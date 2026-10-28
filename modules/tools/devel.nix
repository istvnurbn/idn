{
  den.aspects.devel = {
    os = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        lazygit
        jq
        just-lsp
        gawk
        helix
      ];
    };
  };
}
