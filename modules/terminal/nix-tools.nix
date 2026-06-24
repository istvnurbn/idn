{
  den.aspects.nix-tools = {
    os = {pkgs, ...}: {
      # Utils making it easier to deal with Nix
      environment.systemPackages = with pkgs; [
        nixd
        alejandra
        nix-output-monitor
        nvd
      ];

      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 4d --keep 3";
      };

      environment.variables = {
        NH_FLAKE = "$HOME/idn";
      };
    };
  };
}
