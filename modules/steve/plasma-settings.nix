{
  den.aspects.steve.provides.plasma-settings.homeManager = {
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
}
