{den, ...}: {
  den.aspects.desktop-base = {
    # pkgs.unstable comes from the unstable aspect
    includes = [den.aspects.unstable];

    os = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        unstable.mcp-nixos # stable lagged far behind, without 26.05 for a long time
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
          unstable.zed-editor # moves fast; stable long lacked the agent panel
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
        ".config/kde.org"
        ".local/share/org.localsend.localsend_app"
        ".local/share/zed"
        ".local/share/ghostwriter"
      ];
    };
  };
}
