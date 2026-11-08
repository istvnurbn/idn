{
  den.aspects.faugus = {
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
