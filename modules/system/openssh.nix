{den, ...}: {
  den.aspects.openssh = {host, ...}: {
    nixos = {
      # Enable the OpenSSH daemon
      services.openssh = {
        enable = true;
        openFirewall = true;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
          AllowUsers = ["steve"];
          MaxAuthTries = 3;
          PerSourcePenalties = "crash:3600s authfail:3600s max:86400s";
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

      # Declarative user management
      users.mutableUsers = false;
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
