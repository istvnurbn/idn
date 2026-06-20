{
  den.aspects.security = {
    nixos = {
      # Extra rules for sudo
      security.sudo.extraRules = [
        {
          users = [ "steve" ];
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
          AllowUsers = [ "steve" ];
          MaxAuthTries = 3;
          PerSourcePenalties = "crash:3600s authfail:3600s max:86400s";
        };
      };

      # Declarative user management
      users.mutableUsers = false;
    };
  };
}
