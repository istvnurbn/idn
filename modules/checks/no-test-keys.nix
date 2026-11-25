# Fails when a real host trusts one of nixpkgs' snakeoil SSH keys. The VM
# tests authorize them in their extraModules; they must never reach a host
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

  # The initrd's SSH logins (luks-ssh-unlock) and every user's
  trusted = c:
    (c.boot.initrd.network.ssh.authorizedKeys or [])
    ++ lib.concatMap (u: u.openssh.authorizedKeys.keys or []) (lib.attrValues c.users.users);
  leaks = lib.attrNames (lib.filterAttrs (_: host: lib.any (k: lib.any (s: lib.hasInfix s k) snakeoil) (trusted host.config)) (
    (config.flake.nixosConfigurations or {}) // (config.flake.darwinConfigurations or {})
  ));
in {
  flake.checks = lib.genAttrs den.systems (system: {
    no-test-keys = inputs.nixpkgs.legacyPackages.${system}.runCommand "no-test-keys" {} (
      if leaks == []
      then "touch $out"
      else ''echo "snakeoil SSH keys trusted by: ${toString leaks}" >&2; exit 1''
    );
  });
}
