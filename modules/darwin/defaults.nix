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
              automaticallyInstallSystemDataFilesAndSecurityUpdates = false;
            };
          };
          lockScreen = {
            turnDisplayOffOnBatteryWhenInactive = "For 2 minutes";
            turnDisplayOffOnPowerAdapterWhenInactive = "For 10 minutes";
          };
          network = {
            firewall = {
              firewall = true;
              options = {
                automaticallyAllowBuiltInSoftwareToReceiveIncomingConnections = true;
                automaticallyAllowDownloadedSignedSoftwareToReceiveIncomingConnections = true;
                blockAllIncomingConnections = false;
                enableStealthMode = false;
              };
            };
          };
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

          # Sets the speed of the Mission Control animations
          expose-animation-duration = 0.1;

          # Set the minimize/maximize window effect
          mineffect = "genie";

          # Do not automatically rearrange spaces
          mru-spaces = false;

          # Show indicator lights for open applications
          show-process-indicators = true;

          # Make icons of hidden applications tranclucent
          showhidden = true;

          # Hot corner action for bottom right corner
          wvous-br-corner = 1;
        };

        finder = {
          # Always show file extensions
          AppleShowAllExtensions = true;

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

          # Jump to the spot that’s clicked on the scroll bar
          AppleScrollerPagingBehavior = true;

          # Show the scrollbars when scrolling
          AppleShowScrollBars = "WhenScrolling";

          # Disable automatic spelling correction
          NSAutomaticSpellingCorrectionEnabled = false;

          # Do not animate opening and closing of windows and popovers
          NSAutomaticWindowAnimationsEnabled = false;

          # Do not save new documents to iCloud by default
          NSDocumentSaveNewDocumentsToCloud = false;

          # Use expanded save panel by default
          NSNavPanelExpandedStateForSaveMode = true;
          NSNavPanelExpandedStateForSaveMode2 = true;

          # Enable moving window by holding anywhere on it like on Linux
          NSWindowShouldDragOnGesture = true;

          # Use the expanded print panel by default
          PMPrintingExpandedStateForPrint = true;
          PMPrintingExpandedStateForPrint2 = true;

          # Sets the beep/alert volume level to 50%
          "com.apple.sound.beep.volume" = 0.6065307;
        };

        screencapture = {
          # Disable drop shadow around screenshots
          disable-shadow = true;

          # Save screenshots to
          location = "~/Pictures/Screenshots";
        };

        WindowManager = {
          # Clicking your wallpaper will move all windows out of the way to allow access to your desktop items and widgets
          EnableStandardClickToShowDesktop = false;

          # Hide widgets in Stage Manager
          StageManagerHideWidgets = true;

          # Hide widgets on desktop
          StandardHideWidgets = true;
        };

        # Security
        loginwindow = {
          # Disable the ability to access the console by typing “>console” for a username at the login window
          DisableConsoleAccess = true;

          # Disable guest access
          GuestEnabled = false;
        };

        screensaver = {
          # Ask for password when the screen saver unlocked or stopped
          askForPassword = true;

          # Grace period before the password is required to unlock or stop the screen saver
          askForPasswordDelay = 0;
        };

        CustomSystemPreferences = {
          NSGlobalDomain = {
            # Close windows when quitting an app
            NSQuitAlwaysKeepsWindows = false;

            # Privacy: disable online spell correction
            WebAutomaticSpellingCorrectionEnabled = false;
          };

          # Do not write AppleDouble files on USB drives and network shares
          "com.apple.desktopservices" = {
            DSDontWriteNetworkStores = true;
            DSDontWriteUSBStores = true;
          };

          # Quit printing app once finished
          "com.apple.print.PrintingPrefs" = {
            "Quit When Finished" = true;
          };

          # Mail
          "com.apple.mail" = {
            # Show attachement at the end of mails
            DisableInlineAttachmentViewing = true;

            # Copy only mail addresses to clipboard
            AddressesIncludeNameOnPasteboard = false;

            # Disable animations
            DisableReplyAnimations = true;
            DisableSendAnimations = true;
          };

          # TextEdit
          "com.apple.TextEdit" = {
            # Start with an empty file.
            NSShowAppCentricOpenPanelInsteadOfUntitledFile = false;
            # Plain text editing.
            RichText = 0;
            PlainTextEncoding = 4;
            PlainTextEncodingForWrite = 4;
          };

          # Disk Utility
          "com.apple.DiskUtility" = {
            DUDebugMenuEnabled = true;
            advanced-image-options = true;
          };

          # Do not offer importing from external cameras
          "com.apple.ImageCapture" = {
            disableHotPlug = true;
          };

          # Do not offer to use new disks for backup target
          "com.apple.TimeMachine" = {
            DoNotOfferNewDisksForBackup = true;
          };

          # Security: software update
          "com.apple.SoftwareUpdate" = {
            # Check for automatic updates daily
            AutomaticCheckEnabled = true;
            ScheduleFrequency = 1;

            # Disable automatic installation of macOS updates
            AutomaticallyInstallMacOSUpdates = false;
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

    provides.to-users.homeManager = {
      imports = [inputs.nix-plist-manager.homeManagerModules.default];

      programs.nix-plist-manager = {
        enable = true;
        options.applications = {
          finder = {
            menuBar = {
              view = {
                showPathBar = true;
                showSidebar = true;
              };
            };
            settings = {
              advanced = {
                keepFoldersOnTop = {
                  inWindowsWhenSortingByName = true;
                  onDesktop = true;
                };
                removeItemsFromTheTrashAfter30Days = true;
                whenPerformingASearch = "Search the Current Folder";
              };
              general = {
                showTheseItemsOnTheDesktop = {
                  cdsDvdsAndiPods = true;
                  connectedServers = true;
                  externalDisks = true;
                  hardDisks = false;
                };
              };
            };
          };
          systemSettings = {
            accessibility = {
              audio = {
                backgroundSoundsOptions = {
                  timer = false;
                };
              };
              display = {
                reduceTransparency = true;
                textSize = {
                  preferredReadingSize = "DEFAULT";
                };
              };
              hoverText = {
                hoverTypingOptions = {
                  textFont = "Default";
                };
                options = {
                  textFont = "Default";
                };
              };
              keyboard = {
                slowKeys = false;
                stickyKeys = false;
                stickyKeysOptions = {
                  pressTheShiftKeyFiveTimesToToggleStickyKeys = false;
                };
              };
              liveCaptions = {
                fontFamily = "Default";
              };
              motion = {
                reduceMotion = true;
              };
              pointerControl = {
                trackpadOptions = {
                  dragging = "Off";
                  useTrackpadForScrolling = true;
                };
              };
              readAndSpeak = {
                typingFeedback = {
                  characters = true;
                  modifierKeys = false;
                  selectionChanges = false;
                  words = true;
                };
              };
              voiceControl = {
                showHints = false;
              };
              zoom = {
                useKeyboardShortcutsToZoom = false;
              };
            };
            appearance = {
              clickInTheScrollBarTo = "Jump to the spot that's clicked";
              liquidGlass = 1.0;
              showScrollBars = "When scrolling";
            };
            appleIntelligenceAndSiri = {
              siri = {
                enable = false;
              };
            };
            desktopAndDock = {
              desktopAndStageManager = {
                clickWallpaperToRevealDesktop = "Only in Stage Manager";
              };
              dock = {
                animateOpeningApplications = false;
                automaticallyHideAndShowTheDock = {
                  delay = 0.0;
                  duration = 0.0;
                  enabled = true;
                };
                minimizeWindowsIntoApplicationIcon = true;
                showSuggestedAndRecentAppsInDock = false;
                size = 64;
              };
              hotCorners = {
                bottomLeft = {
                  modifiers = {
                    command = false;
                    control = false;
                    option = false;
                    shift = false;
                  };
                };
                bottomRight = {
                  modifiers = {
                    command = false;
                    control = false;
                    option = false;
                    shift = false;
                  };
                };
                topLeft = {
                  modifiers = {
                    command = false;
                    control = false;
                    option = false;
                    shift = false;
                  };
                };
                topRight = {
                  modifiers = {
                    command = false;
                    control = false;
                    option = false;
                    shift = false;
                  };
                };
              };
              missionControl = {
                automaticallyRearrangeSpacesBasedOnMostRecentUse = false;
                shortcuts = {
                  applicationWindows = "-";
                  missionControl = "-";
                  showDesktop = "-";
                };
              };
              widgets = {
                showWidgets = {
                  inStageManager = false;
                  onDesktop = false;
                };
              };
              windows = {
                dragWindowsToLeftOrRightEdgeOfScreenToTile = false;
                dragWindowsToMenuBarToFillScreen = false;
              };
            };
            general = {
              airDropAndContinuity = {
                iPhoneWidgets = false;
              };
              autoFillAndPasswords = {
                deleteVerificationCodesAfterUse = true;
              };
              languageAndRegion = {
                preferredLanguages = [
                  "en-US"
                  "hu-HU"
                ];
                region = "en_US@rg=huzzzz";
              };
              sharing = {
                mediaSharing = {
                  shareMediaWithGuests = false;
                };
              };
            };
            keyboard = {
              keyboardShortcuts = {
                accessibility = {
                  decreaseContrast = false;
                  increaseContrast = false;
                  invertColors = false;
                };
                appShortcuts = {
                  menuItems = {};
                };
                inputSources = {
                  selectNextSourceInInputMenu = false;
                  selectThePreviousInputSource = false;
                };
                keyboard = {
                  moveFocusToNextWindow = "⌥Tab";
                };
                missionControl = {
                  moveLeftASpace = true;
                  moveRightASpace = true;
                };
              };
              textInput = {
                addPeriodWithDoubleSpace = true;
                capitalizeWordsAutomatically = true;
                inputSources = [
                  "com.apple.keylayout.Hungarian"
                ];
              };
            };
            menuBar = {
              clock = {
                showAmPm = true;
                showTheDayOfTheWeek = true;
              };
            };
            notifications = {
              notificationCenter = {
                summarizeNotifications = false;
              };
            };
            privacyAndSecurity = {
              appleAdvertising = {
                personalizedAds = false;
              };
            };
            sound = {
              soundEffects = {
                alertVolume = 0.606531;
              };
            };
            spotlight = {
              searchResults = {
                appStore = true;
                apps = true;
                books = true;
                calculator = true;
                calendar = true;
                contacts = true;
                dictionary = true;
                files = true;
                folders = true;
                games = true;
                iPhoneApps = true;
                mail = true;
                menuItems = true;
                messages = true;
                music = true;
                notes = true;
                phone = true;
                photos = true;
                podcasts = true;
                reminders = true;
                safari = true;
                shortcuts = true;
                systemSettings = true;
                tips = true;
                voiceMemos = true;
              };
            };
            trackpad = {
              pointAndClick = {
                click = "Medium";
                tapToClick = true;
              };
              scrollAndZoom = {
                rotate = true;
                zoomInOrOut = true;
              };
            };
            wallpaper = {
              startScreenSaver = "After 5 minutes";
            };
          };
        };
      };
    };
  };
}
