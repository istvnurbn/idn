{
  den.aspects.styling = {
    os = { pkgs, ... }: {
      fonts.packages = with pkgs; [
        nerd-fonts.zed-mono
        meslo-lgs-nf
        ibm-plex
        fira-sans
        fira-code
        source-serif-pro
        source-sans-pro
        source-code-pro
        inter
      ];
    };
  };
}
