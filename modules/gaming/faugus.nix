{den, ...}: {
  den.aspects.faugus = {
    # pkgs.unstable comes from the overlays aspect
    includes = [den.aspects.overlays];

    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [unstable.faugus-launcher];
    };

    persistHome = {
      directories = [
        ".config/faugus-launcher"
        ".local/share/faugus-launcher"
      ];
    };
  };
}
