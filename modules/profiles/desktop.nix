{den, ...}: {
  den.aspects.desktop = {user, ...}: {
    includes = with den.aspects; [
      plymouth
      fonts
      kde
      firefox
    ];

    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        ghostty
        wl-clipboard
        zed-editor
      ];

      programs.localsend = {
        enable = true;
        openFirewall = true;
      };
    };

    impermanence = {
      users.${user.name} = {
        directories = [
          ".local/share/org.localsend.localsend_app"
          ".local/share/zed"
        ];
      };
    };
  };
}
