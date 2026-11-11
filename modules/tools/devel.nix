{
  den.aspects.devel = {
    os = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        gawk
        gh
        helix
        hugo
        just-lsp
        jq
        lazygit
      ];
    };
    persistHome = {
      directories = [
        ".config/gh"
      ];
    };
  };
}
