{
  den.aspects.devel = {
    os = {pkgs, ...}: {
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
