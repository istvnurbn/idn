{
  den.aspects.devel = {
    os = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        gawk
        gh
        helix
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
