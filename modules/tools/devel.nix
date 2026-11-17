{
  den.aspects.devel = {
    os = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        gawk
        helix
        just-lsp
        jq
        lazygit
      ];
    };

    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        gh
        hugo
      ];
    };

    # Homebrew's bottles on macOS: nixpkgs' Mac builds of these Go tools can be
    # uncached at the pinned nixos-26.05, and building them pulls in Go first
    darwin.homebrew.brews = [
      "gh"
      "hugo"
    ];

    persistHome = {
      directories = [
        ".config/gh"
      ];
    };
  };
}
