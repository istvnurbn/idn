{inputs, ...}: {
  flake-file.inputs.plasma-manager = {
    url = "github:nix-community/plasma-manager";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.home-manager.follows = "home-manager";
  };

  den.aspects.plasma = {
    nixos = {pkgs, ...}: {
      services = {
        displayManager.plasma-login-manager.enable = true;
        desktopManager.plasma6.enable = true;
      };

      programs.partition-manager.enable = true;

      xdg.portal = {
        enable = true;
        config.common.default = "kde";
        extraPortals = with pkgs; [
          kdePackages.xdg-desktop-portal-kde
        ];
      };

      # Plasma Browser Integration for Firefox: nixpkgs' plasma6 module already
      # registers the native messaging host, so only the add-on is added here.
      # programs.firefox.* stays inert unless the firefox aspect enables it.
      programs.firefox = {
        policies.ExtensionSettings."plasma-browser-integration@kde.org" = {
          installation_mode = "normal_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/plasma-integration/latest.xpi";
        };

        # KDE's file dialog, through the portal configured above.
        preferences."widget.use-xdg-desktop-portal.file-picker" = 1;
      };

      environment.systemPackages = with pkgs; [
        kdePackages.isoimagewriter
        kdePackages.kcalc
        kdePackages.kquickimageedit
        exfatprogs
      ];

      services.orca.enable = false;

      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        elisa
        kate
        konsole
        ktexteditor
        khelpcenter
        kwin-x11
        print-manager
        qrca
      ];
    };

    provides.to-users.homeManager = {
      imports = [inputs.plasma-manager.homeModules.plasma-manager];
    };
  };
}
