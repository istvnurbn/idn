{
  den.aspects.heroic = {
    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        heroic
      ];
    };

    persistHome = {
      directories = [
        ".config/heroic"
        ".local/share/umu"
      ];
    };
  };
}
