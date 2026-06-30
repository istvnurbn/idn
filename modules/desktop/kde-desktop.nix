{
  den.aspects.kde-desktop = {user, ...}: {
    nixos = {pkgs, ...}: {
      # Enable Plasma
      services = {
        desktopManager.plasma6.enable = true;

        # Default display manager for Plasma
        displayManager.plasma-login-manager.enable = true;
      };

      programs = {
        kdeconnect.enable = true;
        partition-manager.enable = true;
      };

      # Ports for KDE Connect
      networking.firewall = rec {
        allowedTCPPortRanges = [
          {
            from = 1714;
            to = 1764;
          }
        ];
        allowedUDPPortRanges = allowedTCPPortRanges;
      };

      xdg.portal = {
        enable = true;
        config.common.default = "kde";
      };

      environment.systemPackages = with pkgs; [
        kdePackages.isoimagewriter
        kdePackages.kcalc
        kdePackages.kquickimageedit
        exfatprogs
      ];

      # Remove unnecessary apps
      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        elisa
        kate
        konsole
        ktexteditor
        khelpcenter
        print-manager
        qrca
      ];
    };

    impermanence = {
      users.${user.name} = {
        directories = [
          ".config/kdeconnect"
        ];
      };
    };
  };
}
