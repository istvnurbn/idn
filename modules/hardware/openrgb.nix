{
  den.aspects.openrgb = {user, ...}: {
    nixos = {pkgs, ...}: {
      services.hardware.openrgb = {
        enable = true;
        package = pkgs.openrgb-with-all-plugins;
      };
    };

    impermanence = {
      users.${user.name} = {
        directories = [
          ".config/OpenRGB"
        ];
      };
    };
  };
}
