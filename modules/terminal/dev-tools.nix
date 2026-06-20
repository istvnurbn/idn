{
  den.aspects.dev-tools = {
    os = { pkgs, ... }: {
      # Utils making it easier to deal with Nix
      environment.systemPackages = with pkgs; [
        git
        lazygit
        jq
        just
        just-lsp
      ];
    };
  };
}
