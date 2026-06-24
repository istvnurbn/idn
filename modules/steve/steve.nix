{den, ...}: {
  den.aspects.steve = {
    includes = [
      den.batteries.primary-user
      (den.provides.user-shell "zsh")
      den.aspects.dotfiles
    ];

    user = {
      description = "István Urbán";
      createHome = true;
      hashedPassword = "$y$j9T$ae.Dmqz2N2YdPvY1xUvwu0$wdBYfrORJhqvPUPJpFP7oHsYrxBAwBec2hAKbc3KnM4";
    };
  };
}
