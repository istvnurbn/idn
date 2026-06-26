{
  den.aspects.shell = {user, ...}: {
    os = {pkgs, ...}: {
      # Configure zsh as an interactive shell
      programs.zsh.enable = true;

      environment.systemPackages = with pkgs; [
        atuin
        fzf
        zoxide
        bat
        tree
        mc
        just
        wget
        curl
        rsync
        msedit # just for the fun of it
        pv
        mmv
        xdg-utils
      ];
    };

    darwin = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        coreutils
        nano
        gnutar # macOS tar fails me sometimes
      ];
    };

    impermanence = {
      users.${user.name} = {
        directories = [
          ".local/share/atuin"
          ".local/share/zinit"
          ".local/share/zoxide"
        ];
      };
    };
  };
}
