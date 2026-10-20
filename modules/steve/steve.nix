{den, ...}: {
  den.aspects.steve = {user, ...}: {
    includes = [
      den.aspects.dotfiles
      den.aspects.xdg-folders
      (den.lib.policy.when ({host, ...}: host.hasAspect den.aspects.firefox) den.aspects.steve._.firefox-settings)
      (den.lib.policy.when ({host, ...}: host.hasAspect den.aspects.plasma) den.aspects.steve._.plasma-settings)
    ];

    user = {
      description = "István Urbán";
      createHome = true;
    };

    provides.to-hosts.nixos = {pkgs, ...}: let
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
          "input"
        ];
      };

      systemd.tmpfiles.rules = [
        "C+ /var/lib/AccountsService/users/${user.name} 0600 root root - ${accountsServiceUser}"
        "L+ /var/lib/AccountsService/icons/${user.name} - - - - ${avatar}"
      ];
    };

    persistHome = {
      directories = [
        "idn"
      ];
    };
  };
}
