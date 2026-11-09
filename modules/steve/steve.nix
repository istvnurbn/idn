{den, ...}: {
  den.aspects.steve = {user, ...}: {
    includes = [
      den.aspects.dotfiles
      den.aspects.xdg-folders
      (den.lib.policy.when ({host, ...}: host.hasAspect den.aspects.firefox) den.aspects.steve._.firefox-settings)
      (den.lib.policy.when ({host, ...}: host.hasAspect den.aspects.plasma) den.aspects.steve._.plasma-settings)
      (den.lib.policy.when ({host, ...}: host.hasAspect den.aspects.darwin-defaults) den.aspects.steve._.darwin-settings)
    ];

    user = {
      description = "István Urbán";
    };

    provides.to-hosts.nixos = {pkgs, ...}: let
      avatar = ./dotfiles/face;

      accountsServiceUser = pkgs.writeText "accountsservice-${user.name}" ''
        [User]
        Icon=/var/lib/AccountsService/icons/${user.name}
      '';
    in {
      users.users.${user.name} = {
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
