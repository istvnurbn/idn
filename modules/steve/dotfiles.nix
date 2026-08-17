{
  den.aspects.dotfiles = {
    homeManager = {
      config,
      lib,
      ...
    }: let
      dotsLink = path:
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/idn/modules/steve/dotfiles/${path}";

      # $HOME-relative target paths; each is linked to the identical path
      # (minus the leading dot) under modules/steve/dotfiles/.
      linkedPaths = [
        # Files/folders in the root of the $HOME directory
        ".abcde.conf"
        ".face"
        ".gitconfig"

        # Files/folders in the .config directory
        ".config/atuin"
        ".config/btop/themes/catppuccin_mocha.theme"
        ".config/dtop"
        ".config/ghostty"
        ".config/helix"
        ".config/lazygit"
        ".config/mc/ini"
        ".config/scopebuddy"
        ".config/zed"

        # Files/folders in the .local directory
        ".local/share/mc/skins/catppuccin.ini"
      ];
    in {
      home.file =
        lib.genAttrs linkedPaths (path: {
          source = dotsLink (lib.removePrefix "." path);
        })
        // {
          # Keep this key as "./.zshrc", not ".zshrc": home-manager's own
          # zsh integration (enabled via user-shell "zsh") writes to that
          # same key. Matching it exactly lets our file win instead of the
          # two silently fighting over the same file on disk.
          "./.zshrc".source = dotsLink "zshrc";
        };
    };
  };
}
