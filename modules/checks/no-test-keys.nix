# Fails when a real host trusts one of nixpkgs' snakeoil SSH keys, or takes
# an initrd secret or SSH host key from the Nix store, which every user can
# read. The VM tests do both in their extraModules; neither may reach a host
# in nixosConfigurations or darwinConfigurations.
#
#   nix build .#checks.x86_64-linux.no-test-keys
{
  config,
  den,
  inputs,
  lib,
  ...
}: let
  keys = import "${inputs.nixpkgs}/nixos/tests/ssh-keys.nix" inputs.nixpkgs.legacyPackages.x86_64-linux;
  # The key material alone, so options or a comment around it don't hide it
  snakeoil = map (k: lib.elemAt (lib.splitString " " k) 1) [keys.snakeOilPublicKey keys.snakeOilEd25519PublicKey];

  # The initrd's SSH logins (luks-ssh-unlock) and every user's, inline or
  # from key files
  keysIn = keys: files: keys ++ map builtins.readFile files;
  trusted = c:
    keysIn (c.boot.initrd.network.ssh.authorizedKeys or []) (c.boot.initrd.network.ssh.authorizedKeyFiles or [])
    ++ lib.concatMap (u: keysIn (u.openssh.authorizedKeys.keys or []) (u.openssh.authorizedKeys.keyFiles or [])) (lib.attrValues c.users.users);
  # Secrets the boot loader copies into the initrd (null: from the same
  # path at run time), and the host keys of the initrd's and the real sshd
  secretSources = c:
    lib.attrValues (c.boot.initrd.secrets or {})
    ++ (c.boot.initrd.network.ssh.hostKeys or [])
    ++ map (k: k.path) (c.services.openssh.hostKeys or []);
  inStore = p: p != null && (lib.isPath p || lib.hasPrefix builtins.storeDir (toString p));

  hosts = (config.flake.nixosConfigurations or {}) // (config.flake.darwinConfigurations or {});
  hostsWhere = pred: lib.attrNames (lib.filterAttrs (_: host: pred host.config) hosts);
  leaks = hostsWhere (c: lib.any (k: lib.any (s: lib.hasInfix s k) snakeoil) (trusted c));
  storeSecrets = hostsWhere (c: lib.any inStore (secretSources c));
in {
  flake.checks = lib.genAttrs den.systems (system: {
    no-test-keys = inputs.nixpkgs.legacyPackages.${system}.runCommand "no-test-keys" {} (
      if leaks == [] && storeSecrets == []
      then "touch $out"
      else ''
        ${lib.optionalString (leaks != []) ''echo "snakeoil SSH keys trusted by: ${toString leaks}" >&2''}
        ${lib.optionalString (storeSecrets != []) ''echo "initrd secrets or SSH host keys from the Nix store on: ${toString storeSecrets}" >&2''}
        exit 1
      ''
    );
  });
}
