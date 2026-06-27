{
  den.aspects.kde-desktop = {
    nixos = {pkgs, ...}: {
      # Enable Plasma
      services = {
        desktopManager.plasma6.enable = true;

        # Default display manager for Plasma
        displayManager.plasma-login-manager.enable = true;
      };

      environment.systemPackages = with pkgs; [
        kdePackages.kcalc
        kdePackages.kquickimageedit
        kdePackages.partitionmanager
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
  };
}
