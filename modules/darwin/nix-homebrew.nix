# nix-homebrew manages Homebrew installation on macOS using nix-darwin
{inputs, ...}: let
  # Declared once and shared: nix-homebrew uses `taps` for Nix-store-based
  # tap management, and nix-darwin's homebrew module reads the tap names
  # from it to keep its Brewfile in sync. Reading it back via
  # `den.aspects...` instead leaks den's internal bookkeeping keys
  # (`_`, `__provider`) into the list.
  taps = {
    "homebrew/homebrew-core" = inputs.homebrew-core;
    "homebrew/homebrew-cask" = inputs.homebrew-cask;
  };
in {
  flake-file.inputs = {
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  den.aspects.nix-homebrew.darwin = {
    imports = [
      inputs.nix-homebrew.darwinModules.nix-homebrew
    ];

    nix-homebrew = {
      # Install Homebrew under the default prefix
      enable = true;

      # User owning the Homebrew prefix
      user = "steve";

      # Enable fully-declarative tap management
      inherit taps;

      # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
      mutableTaps = false;
    };

    homebrew = {
      # Enable nix-darwin to manage Homebrew
      enable = true;

      # Align homebrew taps config with nix-homebrew
      taps = builtins.attrNames taps;

      # Disable Homebrew to auto-update itself and all formulae
      global.autoUpdate = false;

      onActivation = {
        # Disable Homebrew to auto-update itself and all formulae during nix-darwin system activation
        autoUpdate = false;

        # Packages installed outside of nix-darwin will be zapped
        cleanup = "zap";

        # Enable Homebrew to upgrade outdated formulae and Mac App Store apps during nix-darwin system activation
        upgrade = true;
      };
    };

    environment = {
      variables = {
        # Do not send analytics
        HOMEBREW_NO_ANALYTICS = "1";

        # Forbid redirects from secure HTTPS to insecure HTTP
        HOMEBREW_NO_INSECURE_REDIRECT = "1";
      };
    };
  };
}
