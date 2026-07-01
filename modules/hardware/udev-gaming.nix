{
  den.aspects.udev-gaming = {
    nixos = {pkgs, ...}: {
      services.udev.packages = with pkgs; [
        game-devices-udev-rules
        steam-devices-udev-rules
      ];
    };
  };
}
