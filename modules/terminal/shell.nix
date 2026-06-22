{
  den.aspects.shell = {
    os = { pkgs, ... }: {
      # Configure zsh as an interactive shell
      programs.zsh.enable = true;

      environment.systemPackages = with pkgs; [
        atuin
        fzf
        zoxide
        bat
        tree
        mc
        wget
        curl
        rsync
        msedit # just for the fun of it
        pv
        mmv
        xdg-utils
      ];
    };

    darwin = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        coreutils
        nano
        gnutar # macOS tar fails me sometimes
        openssh
      ];
    };
  };
}
