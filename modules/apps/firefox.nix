{
  den.aspects.firefox = let
    # Shared with the home-manager profile below (provides.to-users.homeManager)
    # so the same policies apply on nixos and darwin alike.
    policies = {
      EnterprisePoliciesEnabled = true;

      # Updates & Background Services
      AppAutoUpdate = false;
      BackgroundAppUpdate = false;
      ManualAppUpdateOnly = true;

      # Features
      DisableDeveloperTools = false;
      DisableFeedbackCommands = true;
      EncryptedMediaExtensions = true;
      DisableFirefoxStudies = true;
      DisableFirefoxScreenshots = true;
      DisableFormHistory = true;
      DisableSetDesktopBackground = true;
      DisablePocket = true;
      DisableTelemetry = true;

      # UI and Behavior
      DontCheckDefaultBrowser = true;
      FirefoxHome = {
        SponsoredStories = false;
        SponsoredTopSites = false;
        Stories = false;
      };
      GenerativeAI = {
        Enabled = false;
      };
      NoDefaultBookmarks = true;

      # Additional search engines
      SearchEngines = {
        PreventInstalls = false;
        Remove = [
          "Amazon.com"
          "eBay"
          "Perplexity"
        ];
      };
    };
  in {
    nixos = {
      programs.firefox = {
        enable = true;
        inherit policies;
      };
    };

    darwin = {
      homebrew.casks = [
        "firefox"
      ];
    };

    persistHome = {
      directories = [
        ".config/mozilla"
      ];
    };

    provides.to-users.homeManager = {
      programs.firefox = {
        enable = true;

        # The actual browser is already installed system-wide (nixos facet)
        # or via the Homebrew cask (darwin facet); home-manager only manages
        # the profiles (settings/extensions/search) that each user's aspect
        # defines, so skip installing a second, redundant nixpkgs Firefox
        # into the user profile.
        package = null;

        # Same enterprise policies as the nixos facet. On darwin these are
        # written to ~/Library/Preferences/org.mozilla.firefox.plist, which
        # the Homebrew-installed Firefox reads regardless of `package`. On
        # NixOS this copy is a no-op: home-manager applies Linux policies
        # only by wrapping its own package (null here), so the nixos facet's
        # copy is the one that takes effect.
        inherit policies;
      };
    };
  };
}
