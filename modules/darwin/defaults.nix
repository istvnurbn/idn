{
  den.aspects.darwin-defaults = {
    darwin.system.defaults = {
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

        # Automatically hide and show the dock
        autohide = true;

        # Sets the speed of the autohide delay
        autohide-delay = 0.0;

        # Sets the speed of the animation when hiding/showing the Dock
        autohide-time-modifier = 0.0;

        # Sets the speed of the Mission Control animations
        expose-animation-duration = 0.1;

        # Animate opening applications from the Dock
        launchanim = false;

        # Set the minimize/maximize window effect
        mineffect = "genie";

        # Minimize windows into their application icon
        minimize-to-application = true;

        # Do not automatically rearrange spaces
        mru-spaces = false;

        # Show indicator lights for open applications
        show-process-indicators = true;

        # Do not show recent applications
        show-recents = false;

        # Make icons of hidden applications tranclucent
        showhidden = true;

        # Hot corner action for bottom right corner
        wvous-br-corner = 1;
      };

      finder = {
        # Always show file extensions
        AppleShowAllExtensions = true;

        # Change the default search scope to current folder
        FXDefaultSearchScope = "SCcf";

        # List view as the default Finder view
        FXPreferredViewStyle = "Nlsv";

        # Remove items in the trash after 30 days
        FXRemoveOldTrashItems = true;

        # Home folder as the default folder shown in Finder windows
        NewWindowTarget = "Home";

        # Allow quitting the Finder
        QuitMenuItem = true;

        # Show connected servers on desktop
        ShowMountedServersOnDesktop = true;

        # Show path breadcrumbs in Finder windows
        ShowPathbar = true;

        # Resize columns to fit filenames
        _FXEnableColumnAutoSizing = true;

        # Keep folders on top when sorting by name
        _FXSortFoldersFirst = true;

        # Keep folders on top when sorting by name on the desktop
        _FXSortFoldersFirstOnDesktop = true;
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

          # Disable automatic app updates from the App Store
          AutomaticallyInstallAppUpdates = false;
        };

        # Privacy
        # Disable personalized advertisements and identifier tracking.
        "com.apple.AdLib" = {
          "allowIdentifierForAdvertising" = false;
          "allowApplePersonalizedAdvertising" = false;
          "forceLimitAdTracking" = true;
        };

        # Privacy: disable Microsoft Office telemetry
        "com.microsoft.office" = {"DiagnosticDataTypePreference" = "ZeroDiagnosticData";};
      };
    };
  };
}
