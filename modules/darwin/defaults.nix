{inputs, ...}: {
  flake-file.inputs.nix-plist-manager = {
    url = "github:sushydev/nix-plist-manager";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  den.aspects.darwin-defaults = {
    darwin = {
      imports = [inputs.nix-plist-manager.darwinModules.default];

      programs.nix-plist-manager = {
        enable = true;
        options.applications.systemSettings = {
          battery = {
            options = {
              preventAutomaticSleepingOnPowerAdapterWhenTheDisplayIsOff = false;
              slightlyDimTheDisplayOnBattery = true;
              wakeForNetworkAccess = "Only on Power Adapter";
            };
          };
          general = {
            dateAndTime = {
              # source below only applies while this is true.
              setTimeAndDateAutomatically = true;

              # Explicit timeZone below is only in effect while this is false
              setTimeZoneAutomaticallyUsingYourCurrentLocation = false;
              source = "time.apple.com";
              timeZone = "Europe/Budapest";
            };
            sharing = {
              contentCaching = false;
              fileSharing = false;
              fileSharingOptions = {
                sharedFolders = {
                  "/Users/steve/Public" = "István Urbán’s Public Folder";
                };
              };
              printerSharing = false;
              remoteApplicationScripting = false;
              remoteApplicationScriptingOptions = {
                allowAccessFor = "Only these users";
              };
              remoteManagement = false;
              screenSharing = false;
              screenSharingOptions = {
                allowAccessFor = "Only these users";
              };
            };
            softwareUpdate = {
              automaticallyDownloadNewUpdatesWhenAvailable = true;
              automaticallyInstallApplicationUpdatesFromTheAppStore = true;
              automaticallyInstallMacOSUpdates = false;
              automaticallyInstallSystemDataFilesAndSecurityUpdates = false;
            };
          };
          lockScreen = {
            turnDisplayOffOnBatteryWhenInactive = "For 2 minutes";
            turnDisplayOffOnPowerAdapterWhenInactive = "For 10 minutes";
          };
          # The firewall lives in the networking aspect (networking.applicationFirewall).
          privacyAndSecurity = {
            analyticsAndImprovements = {
              shareMacAnalytics = false;
              shareWithAppDevelopers = false;
            };
          };
        };
      };

      system.defaults = {
        ActivityMonitor = {
          # Change the icon in the Dock to CPU Usage
          IconType = 5;

          # Sort the main activity page based on descending CPU usage
          SortColumn = "CPUUsage";
          SortDirection = 0;
        };

        dock = {
          # Enable spring loading for all Dock items
          enable-spring-load-actions-on-all-items = true;

          # Display the appswitcher on all displays
          appswitcher-all-displays = true;

          # Set the minimize/maximize window effect
          mineffect = "genie";

          # Show indicator lights for open applications
          show-process-indicators = true;

          # Make icons of hidden applications tranclucent
          showhidden = true;

          # Disable the bottom right hot corner (Quick Note by default)
          wvous-br-corner = 1;
        };

        finder = {
          # List view as the default Finder view
          FXPreferredViewStyle = "Nlsv";

          # Home folder as the default folder shown in Finder windows
          NewWindowTarget = "Home";

          # Allow quitting the Finder
          QuitMenuItem = true;

          # Resize columns to fit filenames
          _FXEnableColumnAutoSizing = true;
        };

        NSGlobalDomain = {
          # Use 24-hour time
          AppleICUForce24HourTime = true;

          # Automatically switch icon and widget style
          AppleIconAppearanceTheme = "RegularAutomatic";

          # Automatically switch between light and dark mode
          AppleInterfaceStyleSwitchesAutomatically = true;

          # Use the metric system
          AppleMeasurementUnits = "Centimeters";
          AppleMetricUnits = 1;
          AppleTemperatureUnit = "Celsius";

          # Do not animate opening and closing of windows and popovers
          NSAutomaticWindowAnimationsEnabled = false;

          # Do not save new documents to iCloud by default
          NSDocumentSaveNewDocumentsToCloud = false;

          # Use expanded save panel by default
          NSNavPanelExpandedStateForSaveMode = true;

          # Move a window by Ctrl+Cmd-dragging anywhere on it
          NSWindowShouldDragOnGesture = true;

          # Use the expanded print panel by default (only Preview and ColorSync
          # Utility still read this)
          PMPrintingExpandedStateForPrint = true;
        };

        screencapture = {
          # Disable drop shadow around screenshots
          disable-shadow = true;

          # Save screenshots to
          location = "~/Pictures/Screenshots";
        };

        # Security
        loginwindow = {
          # Disable the ability to access the console by typing “>console” for a username at the login window
          DisableConsoleAccess = true;

          # Disable guest access
          GuestEnabled = false;
        };

        # macOS no longer reads the screen saver password keys (askForPassword,
        # askForPasswordDelay). Set the lock delay once with
        # `sysadminctl -screenLock immediate -password -`.

        # Runs `defaults write` as root, so a bare domain lands in
        # /var/root/Library/Preferences: system-wide domains need their full path.
        # Per-user prefs go through home-manager (provides.to-users below, or the
        # user's own aspect).
        CustomSystemPreferences = {
          # Security: check for software updates daily
          "/Library/Preferences/com.apple.SoftwareUpdate" = {
            AutomaticCheckEnabled = true;
            ScheduleFrequency = 1;
          };

          # Do not offer to use new disks for backup target
          "/Library/Preferences/com.apple.TimeMachine" = {
            DoNotOfferNewDisksForBackup = true;
          };
        };
      };
    };

    # Every user on a Mac gets the module and these privacy/hygiene prefs;
    # personal preferences live in each user's aspect (<user>._.darwin-settings).
    provides.to-users.homeManager = {
      imports = [inputs.nix-plist-manager.homeManagerModules.default];

      programs.nix-plist-manager = {
        enable = true;
        options.applications.systemSettings.privacyAndSecurity = {
          appleAdvertising = {
            personalizedAds = false;
          };
        };
      };

      targets.darwin.defaults = {
        # Do not write .DS_Store files on network shares
        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true;
        };

        # Privacy
        # Disable identifier tracking.
        "com.apple.AdLib" = {
          "allowIdentifierForAdvertising" = false;
          "forceLimitAdTracking" = true;
        };

        # Privacy: disable Microsoft Office telemetry
        "com.microsoft.office" = {"DiagnosticDataTypePreference" = "ZeroDiagnosticData";};
      };
    };
  };
}
