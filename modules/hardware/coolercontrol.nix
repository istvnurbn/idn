{
  den.aspects.coolercontrol = {
    nixos = {pkgs, ...}: {
      programs.coolercontrol.enable = true;

      environment.systemPackages = with pkgs; [
        coolercontrol.coolercontrol-gui
      ];
    };
  };
}
