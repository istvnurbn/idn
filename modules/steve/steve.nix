{den, ...}: {
  den.aspects.steve = {
    includes = [
      den.aspects.dotfiles
      den.aspects.xdg-folders
    ];

    user = {
      description = "István Urbán";
      createHome = true;
    };

    nixos = {
      users.users.steve = {
        hashedPassword = "$y$j9T$ae.Dmqz2N2YdPvY1xUvwu0$wdBYfrORJhqvPUPJpFP7oHsYrxBAwBec2hAKbc3KnM4";
        extraGroups = [
          "audio"
          "cdrom"
          "dialout"
          "docker"
          "gamemode"
          "i2c"
          "input"
          "uinput"
        ];
      };
    };

    impermanence = {
      users.steve = {
        directories = [
          "idn"
        ];
        files = [];
      };
    };
  };
}
