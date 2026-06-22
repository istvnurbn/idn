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
      home.file.".config/zed".source = dotsLink "config/zed";
      home.file.".config/ghostty".source = dotsLink "config/ghostty";
      home.file.".config/dtop".source = dotsLink "config/dtop";
    };
  };
}
