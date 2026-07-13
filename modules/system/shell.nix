{
  den.aspects.shell = {user, ...}: {
    os = {pkgs, ...}: {
      # Configure zsh as an interactive shell
      programs.zsh.enable = true;

      environment.systemPackages = with pkgs; [
        atuin
        bat
        btop
        curl
        fastfetch
        fzf
        just
        mc
        mmv
        msedit # just for the fun of it
        pv
        ripgrep
        rsync
        tree
        wget
        xdg-utils
        zoxide
      ];
    };

    darwin = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        coreutils
        gnutar # macOS tar fails me sometimes
        nano
      ];
    };

    impermanence = {
      users.${user.name} = {
        directories = [
          ".local/share/atuin"
          ".local/share/zinit"
          ".local/share/zoxide"
        ];
        files = [
          ".config/btop/btop.conf"
        ];
      };
    };
  };
}
