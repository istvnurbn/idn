{
  den.aspects.darwin-security = {
    darwin.system.defaults = {
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
        # Software update
        "com.apple.SoftwareUpdate" = {
          # Check for automatic updates daily
          AutomaticCheckEnabled = true;
          ScheduleFrequency = 1;

          # Disable automatic installation of macOS updates
          AutomaticallyInstallMacOSUpdates = false;

          # Disable automatic app updates from the App Store
          AutomaticallyInstallAppUpdates = false;
        };
      };
    };
  };
}
