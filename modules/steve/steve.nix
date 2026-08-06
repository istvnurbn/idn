{den, ...}: {
  den.aspects.steve = {user, ...}: {
    includes = [
      den.aspects.dotfiles
      den.aspects.xdg-folders
    ];

    user = {
      description = "István Urbán";
      createHome = true;
    };

    nixos = {pkgs, ...}: let
      avatar = ./dotfiles/face;

      accountsServiceUser = pkgs.writeText "accountsservice-${user.name}" ''
        [User]
        Icon=/var/lib/AccountsService/icons/${user.name}
      '';
    in {
      users.users.${user.name} = {
        hashedPassword = "$y$j9T$ae.Dmqz2N2YdPvY1xUvwu0$wdBYfrORJhqvPUPJpFP7oHsYrxBAwBec2hAKbc3KnM4";
        extraGroups = [
          "audio"
          "cdrom"
          "dialout"
          "docker"
          "gamemode"
          "i2c"
          "input"
          "moonshine"
          "uinput"
        ];
      };

      systemd.tmpfiles.rules = [
        "C+ /var/lib/AccountsService/users/${user.name} 0600 root root - ${accountsServiceUser}"
        "L+ /var/lib/AccountsService/icons/${user.name} - - - - ${avatar}"
      ];
    };

    impermanence = {
      users.${user.name} = {
        directories = [
          "idn"
        ];
        files = [];
      };
    };
  };
}
