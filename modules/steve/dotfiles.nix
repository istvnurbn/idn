{
  den.aspects.dotfiles = {
    homeManager = {config, ...}: let
      dotsLink = path:
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/idn/modules/steve/dotfiles/${path}";
    in {
      # Files/folders in the root of the $HOME directory
      home.file."./.zshrc".source = dotsLink "zshrc";
      home.file."./.gitconfig".source = dotsLink "gitconfig";
      home.file."./.abcde.conf".source = dotsLink "abcde.conf";

      # Files/folders in the .config directory
      home.file.".config/atuin".source = dotsLink "config/atuin";
      home.file.".config/btop/themes/catppuccin_mocha.theme".source = dotsLink "config/btop/themes/catppuccin_mocha.theme";
      home.file.".config/dtop".source = dotsLink "config/dtop";
      home.file.".config/ghostty".source = dotsLink "config/ghostty";
      home.file.".config/lazygit".source = dotsLink "config/lazygit";
      home.file.".config/mc/ini".source = dotsLink "config/mc/ini";
      home.file.".config/scopebuddy".source = dotsLink "config/scopebuddy";
      home.file.".config/zed".source = dotsLink "config/zed";

      # Files/folders in the .local directory
      home.file.".local/share/mc/skins/catppuccin.ini".source = dotsLink "local/share/mc/skins/catppuccin.ini";
    };
  };
}
