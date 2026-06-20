{
  den.aspects.nix-tools = {
    os = { pkgs, ... }: {
      # Utils making it easier to deal with Nix
      environment.systemPackages = with pkgs; [
        nil
        nixd
        alejandra
        nix-output-monitor
        nvd
      ];
    };
  };
}
