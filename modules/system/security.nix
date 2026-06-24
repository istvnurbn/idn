{den, ...}: {
  den.aspects.security = {host, ...}: {
    nixos = {
      # Extra rules for sudo
      security.sudo.extraRules = [
        {
          users = ["steve"];
          commands = [
            {
              command = "ALL";
              options = [
                "SETENV"
                "NOPASSWD"
              ];
            }
          ];
        }
      ];

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
          ]
          else [
            {
              path = "/etc/ssh/ssh_host_ed25519_key";
              type = "ed25519";
            }
          ];
      };

      # Declarative user management
      users.mutableUsers = false;
    };
  };
}
