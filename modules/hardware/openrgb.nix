{
  den.aspects.openrgb = {
    nixos = {pkgs, ...}: {
      services.hardware.openrgb = {
        enable = true;
        package = pkgs.openrgb-with-all-plugins;
      };
    };

    persistHome = {
      directories = [
        ".config/OpenRGB"
      ];
    };
  };
}
