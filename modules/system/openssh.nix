{den, ...}: {
  den.aspects.openssh = {
    host,
    user,
    ...
  }: {
    nixos = {
      # Enable the OpenSSH daemon
      services.openssh = {
        enable = true;
        openFirewall = true;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
          AllowUsers = [user.name];
          MaxAuthTries = 3;
          PerSourcePenalties = "crash:3600s authfail:3600s max:86400s";
        };

        knownHosts = {
          vermilion = {
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIfJ4iMClvTaqIYrMZNdro5oGSLk8LYG8awsuZyez7O5";
            extraHostNames = ["vermilion.local"];
          };
        };

        # Default host keys (overridden by impermanence aspect)
        hostKeys =
          if host.hasAspect den.aspects.impermanence
          then [
            {
              path = "/persist/etc/ssh/ssh_host_ed25519_key";
              type = "ed25519";
            }
            {
              bits = 4096;
              openSSHFormat = true;
              path = "/persist/etc/ssh/ssh_host_rsa_key";
              type = "rsa";
            }
          ]
          else [
            {
              path = "/etc/ssh/ssh_host_ed25519_key";
              type = "ed25519";
            }
            {
              bits = 4096;
              openSSHFormat = true;
              path = "/etc/ssh/ssh_host_rsa_key";
              type = "rsa";
            }
          ];
      };

      users.users.${user.name}.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMDFAQW9uPhDsi+CiCxfwon12iT0Earea6CznTniv1Ta steve@vermilion"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG9mUymT0rLNsntCzJp7Na4Rwj9fAMgfh1oSYmXuRvRK steve@hexley"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO+ge++JIgIQHrr14P1u0K+rF/NzfaTiBz+TRMmUfMHO steve@loophole"
      ];
    };

    darwin = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        openssh
      ];
    };

    impermanence = {
      directories = [
        "/etc/ssh"
      ];
    };
  };
}
