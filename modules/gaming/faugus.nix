{
  den.aspects.faugus = {
    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [faugus-launcher];
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
