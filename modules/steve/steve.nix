{den, ...}: {
  den.aspects.steve = {
    includes = [
      den.batteries.primary-user
      (den.provides.user-shell "zsh")
      den.aspects.dotfiles
    ];
    nixos = {
      users.users.steve = {
        description = "István Urbán";
        hashedPassword = "$y$j9T$ae.Dmqz2N2YdPvY1xUvwu0$wdBYfrORJhqvPUPJpFP7oHsYrxBAwBec2hAKbc3KnM4";
      };
    };
  };
}
