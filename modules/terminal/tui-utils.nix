{
  den.aspects.tui-utils = {
    os = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        btop
        fastfetch
      ];
    };
  };
}
