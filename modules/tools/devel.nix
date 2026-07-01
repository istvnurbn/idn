{
  den.aspects.devel = {
    os = {pkgs, ...}: {
      # Utils making it easier to deal with my projects
      environment.systemPackages = with pkgs; [
        git
        lazygit
        jq
        just-lsp
        gawk
      ];
    };
  };
}
