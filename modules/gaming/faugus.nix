{den, ...}: {
  den.aspects.faugus = {
    # pkgs.unstable comes from the unstable aspect; gaming takes the latest
    # Faugus from it
    includes = [den.aspects.unstable];

    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [unstable.faugus-launcher];
    };

    persistHome = {
      directories = [
        ".config/faugus-launcher"
        ".local/share/faugus-launcher"
        # Recently played and running-games tracking
        ".local/state/faugus-launcher"
        # Steam Runtime that umu-run downloads
        ".local/share/umu"
      ];
    };
  };
}
