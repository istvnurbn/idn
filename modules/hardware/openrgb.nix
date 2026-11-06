{
  den.aspects.openrgb = {
    nixos = {pkgs, ...}: {
      services.hardware.openrgb = {
        enable = true;
        package = pkgs.openrgb-with-all-plugins;
      };
    };

    # The SDK server runs as a system service (StateDirectory=OpenRGB), so its
    # profiles and settings live here, not in the home directory
    persist = {
      directories = [
        "/var/lib/OpenRGB"
      ];
    };

    persistHome = {
      directories = [
        ".config/OpenRGB"
      ];
    };
  };
}
