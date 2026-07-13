{
  den.aspects.sudo = {
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
    };

    darwin = {
      security.pam.services.sudo_local = {
        # Enable managing /etc/pam.d/sudo_local with nix-darwin
        enable = true;
        # Use TouchID for sudo
        touchIdAuth = true;
        # Use Apple Watch for sudo authentication, for devices without Touch ID or laptops with lids closed.
        watchIdAuth = true;
        # Fixes Touch ID for sudo not working inside tmux and screen
        reattach = true;
      };
    };
  };
}
