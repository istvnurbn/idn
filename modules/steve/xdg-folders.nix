{
  den.aspects.xdg-folders = {
    homeManager = {
      xdg.userDirs = {
        enable = true;
        createDirectories = true;

        publicShare = null;
        templates = null;
      };
      # Creating a temp directory
      home.file."temp/.create".text = "";
    };
  };
}
