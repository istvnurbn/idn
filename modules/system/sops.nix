# Secrets with sops-nix. Encrypted files live in secrets/, their recipients in
# secrets/.sops.yaml. Each host decrypts with its own SSH host key, used as it
# is (no ssh-to-age), at activation.
{
  den,
  inputs,
  ...
}: {
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.sops = {
    nixos = {host, ...}: {
      imports = [inputs.sops-nix.nixosModules.sops];

      sops = {
        # Impermanent hosts read the key from /persist: password secrets are
        # decrypted before impermanence binds it into /etc/ssh.
        age.sshKeyFile =
          if host.hasAspect den.aspects.impermanence
          then "/persist/etc/ssh/ssh_host_ed25519_key"
          else "/etc/ssh/ssh_host_ed25519_key";
        age.sshKeyPaths = [];
        gnupg.sshKeyPaths = [];
      };
    };

    # Every user's password hash comes from secrets/shared.yaml, under
    # <name>-password, decrypted before the users are created.
    includes = [
      ({user, ...}: {
        nixos = {config, ...}: {
          sops.secrets."${user.userName}-password" = {
            sopsFile = ../../secrets/shared.yaml;
            neededForUsers = true;
          };
          users.users.${user.userName}.hashedPasswordFile =
            config.sops.secrets."${user.userName}-password".path;
        };
      })
    ];
  };
}
