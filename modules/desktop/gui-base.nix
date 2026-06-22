{
  den.aspects.gui-base = {
    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        ghostty
        zed-editor
      ];
    };
  };
}
