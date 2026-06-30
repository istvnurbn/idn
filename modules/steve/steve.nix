{den, ...}: {
  den.aspects.steve = {
    includes = [
      den.aspects.dotfiles
      den.aspects.xdg-folders
      den.aspects.plasma
    ];

    user = {
      description = "István Urbán";
      createHome = true;
      hashedPassword = "$y$j9T$ae.Dmqz2N2YdPvY1xUvwu0$wdBYfrORJhqvPUPJpFP7oHsYrxBAwBec2hAKbc3KnM4";
    };

    nixos = {
      users.users.steve = {
        extraGroups = [
          "audio"
          "cdrom"
          "docker"
          "gamemode"
        ];
      };
    };
  };
}
