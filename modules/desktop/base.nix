{
  den.aspects.desktop-base = {user, ...}: {
    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        ghostty
        wl-clipboard
        unstable.zed-editor
        proton-pass
      ];

      programs.localsend = {
        enable = true;
        openFirewall = true;
      };
    };

    darwin = {
      homebrew = {
        brews = [
          "imessage-exporter"
          "mas"
          "mole"
        ];
        casks = [
          "bartender"
          "ghostty"
          "linearmouse"
          "localsend"
          "proton-drive"
          "proton-mail"
          "proton-pass"
          "zed"
        ];
        masApps = {
          "Amphetamine" = 937984704;
          "Magnet" = 441258766;
        };
      };
    };

    impermanence = {
      users.${user.name} = {
        directories = [
          ".config/libreoffice"
          ".config/Proton Pass"
          ".local/share/org.localsend.localsend_app"
          ".local/share/zed"
        ];
      };
    };
  };
}
