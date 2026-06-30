{inputs, ...}: {
  flake-file.inputs.plasma-manager = {
    url = "github:nix-community/plasma-manager";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.home-manager.follows = "home-manager";
  };

  den.aspects.plasma = {
    homeManager = {pkgs, ...}: {
      imports = [inputs.plasma-manager.homeModules.plasma-manager];

      programs.plasma = {
        enable = true;

        fonts = {
          fixedWidth = {
            family = "Maple Mono NF";
            pointSize = 10;
          };
          general = {
            family = "Inter";
            pointSize = 10;
          };
          menu = {
            family = "Inter";
            pointSize = 10;
          };
          small = {
            family = "Inter";
            pointSize = 8;
          };
          toolbar = {
            family = "Inter";
            pointSize = 10;
          };
          windowTitle = {
            family = "Inter";
            pointSize = 10;
          };
        };

        panels = [
          {
            location = "bottom";
            alignment = "center";
            lengthMode = "fill";
            hiding = "dodgewindows";
            opacity = "translucent";
            floating = true;
            height = 46;

            widgets = [
              {
                name = "org.kde.plasma.kickoff";
                config = {
                  General = {
                    icon = "nix-snowflake";
                    alphaSort = true;
                    highlightNewlyInstalledApps = false;
                    showActionButtonCaptions = false;
                  };
                };
              }
              {
                name = "org.kde.plasma.icontasks";
                config = {
                  General = {
                    launchers = [
                      "applications:firefox.desktop"
                      "applications:org.kde.dolphin.desktop"
                      "applications:com.mitchellh.ghostty.desktop"
                    ];
                  };
                };
              }
              "org.kde.plasma.marginsseparator"
              {
                systemTray.items = {
                  shown = [
                    "org.kde.plasma.volume"
                    "org.kde.plasma.brightness"
                    "org.kde.plasma.bluetooth"
                    "org.kde.plasma.networkmanagement"
                  ];
                };
              }
              "org.kde.plasma.digitalclock"
              "org.kde.plasma.showdesktop"
            ];
          }
        ];

        workspace = {
          clickItemTo = "select";
          colorScheme = "BreezeLight";
          cursor = {
            animationTime = 5;
            cursorFeedback = "Bouncing";
            size = 24;
            taskManagerFeedback = true;
            theme = "breeze_cursors";
          };
          lookAndFeel = "org.kde.breeze.desktop";
          wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Coast/contents/images/5120x2880.png";
        };

        kwin.effects.zoom.enable = false;

        input.mice = [
          {
            name = "Logitech PRO X 2 DEX";
            enable = true;
            acceleration = null;
            accelerationProfile = "none";
            leftHanded = false;
            middleButtonEmulation = false;
            naturalScroll = false;
            scrollSpeed = 1;
            productId = "40b8";
            vendorId = "046d";
          }
        ];

        powerdevil.AC = {
          powerButtonAction = "showLogoutScreen";
          powerProfile = "performance";
          whenSleepingEnter = "standbyThenHibernate";
          autoSuspend = {
            action = "sleep";
            idleTimeout = 900;
          };
          dimDisplay = {
            enable = true;
            idleTimeout = 300;
          };
          turnOffDisplay = {
            idleTimeout = 600;
            idleTimeoutWhenLocked = 60;
          };
        };

        configFile = {
          dolphinrc = {
            ContentDisplay.UseShortRelativeDates = false;
            ContextMenu.ShowViewMode = false;
            General = {
              AutoExpandFolders = true;
              BrowseThroughArchives = true;
              EditableUrl = true;
              ShowFullPath = true;
            };
            MainWindow.MenuBar = "Disabled";
          };

          kwalletrc = {
            Wallet = {
              Enabled = false;
              "First Use" = false;
              "Close When Idle" = false;
              "Close on Screensaver" = false;
              "Leave Open" = false;
              "Prompt on Open" = false;
            };
            "org.freedesktop.secrets"."apiEnabled" = true;
          };

          klipperrc.General.KeepClipboardContents = false;
        };
      };
    };
  };
}
