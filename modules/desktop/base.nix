{den, ...}: {
  den.aspects.desktop-base = {
    # pkgs.unstable comes from the unstable aspect
    includes = [den.aspects.unstable];

    os = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        unstable.mcp-nixos
      ];
    };

    nixos = {
      host,
      lib,
      pkgs,
      ...
    }: {
      environment.systemPackages = with pkgs;
        [
          ghostty
          wl-clipboard
          unstable.zed-editor
          proton-pass
        ]
        ++ lib.optional (host.hasAspect den.aspects.plasma) kdePackages.ghostwriter;

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
          "markedit"
        ];
        masApps = {
          "Amphetamine" = 937984704;
          "Magnet" = 441258766;
        };
      };
    };

    persistHome = {
      directories = [
        ".config/Proton Pass"
        ".local/share/org.localsend.localsend_app"
        ".local/share/zed"
        ".local/share/ghostwriter"
      ];
      files = [
        ".config/kde.org/ghostwriter.conf"
      ];
    };
  };
}
