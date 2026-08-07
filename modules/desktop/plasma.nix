{inputs, ...}: {
  flake-file.inputs.plasma-manager = {
    url = "github:nix-community/plasma-manager";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.home-manager.follows = "home-manager";
  };

  den.aspects.plasma = {user, ...}: {
    nixos = {pkgs, ...}: {
      services = {
        displayManager.plasma-login-manager.enable = true;
        desktopManager.plasma6.enable = true;
      };

      programs = {
        kdeconnect.enable = true;
        partition-manager.enable = true;
      };

      # Ports for KDE Connect
      networking.firewall = rec {
        allowedTCPPortRanges = [
          {
            from = 1714;
            to = 1764;
          }
        ];
        allowedUDPPortRanges = allowedTCPPortRanges;
      };

      xdg.portal = {
        enable = true;
        config.common.default = "kde";
        extraPortals = with pkgs; [
          kdePackages.xdg-desktop-portal-kde
        ];
      };

      environment.systemPackages = with pkgs; [
        kdePackages.isoimagewriter
        kdePackages.kcalc
        kdePackages.kquickimageedit
        exfatprogs
      ];

      services.orca.enable = false;

      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        elisa
        kate
        konsole
        ktexteditor
        khelpcenter
        kwin-x11
        print-manager
        qrca
      ];
    };

    impermanence = {
      users.${user.name} = {
        directories = [
          ".config/kdeconnect"
        ];
      };
    };

    provides.to-users.homeManager = {
      imports = [inputs.plasma-manager.homeModules.plasma-manager];

      xdg.mimeApps = {
        enable = true;
        defaultApplications = let
          browser = ["firefox.desktop"];
        in {
          "application/x-extension-htm" = browser;
          "application/x-extension-html" = browser;
          "application/x-extension-shtml" = browser;
          "application/x-extension-xht" = browser;
          "application/x-extension-xhtml" = browser;
          "application/xhtml+xml" = browser;
          "text/html" = browser;
          "x-scheme-handler/about" = browser;
          "x-scheme-handler/chrome" = browser;
          "x-scheme-handler/http" = browser;
          "x-scheme-handler/https" = browser;
          "x-scheme-handler/unknown" = browser;
        };
      };

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
          cursor = {
            animationTime = 5;
            cursorFeedback = "Bouncing";
            size = 24;
            taskManagerFeedback = true;
            theme = "breeze_cursors";
          };
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

          kdeglobals = {
            KDE.AutomaticLookAndFeel = true;
            General = {
              BrowserApplication = "firefox.desktop";
              TerminalApplication = "com.mitchellh.ghostty.desktop";
              TerminalService = "com.mitchellh.ghostty.desktop";
            };
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
