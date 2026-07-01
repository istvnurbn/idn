{
  den.aspects.nix = {
    os = {pkgs, ...}: {
      nix = {
        settings = {
          nix-path = ["nixpkgs=${pkgs.path}"];

          # Users and groups that have additional rights when connecting to the Nix daemon
          trusted-users = [
            "root"
            "@wheel"
          ];

          # Enable the Flakes feature and the accompanying new nix command-line tool
          experimental-features = [
            "nix-command"
            "flakes"
          ];

          # Do not warn about dirty Git/Mercurial trees
          warn-dirty = false;

          # The commit summary to use when committing changed flake lock files
          commit-lock-file-summary = "chore: update flake.lock";

          # Nix automatically detects files in the store that have identical contents, and replaces them with hard links
          auto-optimise-store = !pkgs.stdenv.hostPlatform.isDarwin;

          # List of binary cache URLs used to obtain pre-built binaries of Nix packages
          substituters = [
            "https://cache.nixos.org/"
            "https://nix-community.cachix.org"
            "https://nixpkgs-unfree.cachix.org"
          ];

          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
          ];
        };

        # From https://jackson.dev/post/nix-reasonable-defaults/
        optimise.automatic = true;
        extraOptions = ''
          connect-timeout = 5
          min-free = 128000000
          max-free = 1000000000
          fallback = true
        '';
      };

      nixpkgs.config = {
        # Allow non-free packages
        allowUnfree = true;

        # A lot of stuff says it doesn't work on aarch64-darwin, but it actually does.
        allowUnsupportedSystem = true;
      };

      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 7d --keep 3";
      };

      environment = {
        variables = {
          NH_FLAKE = "$HOME/idn";
        };
      };

      # Utils making it easier to deal with Nix
      environment.systemPackages = with pkgs; [
        nixd
        alejandra
      ];

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
      };
    };

    nixos = {
      programs.nix-ld.enable = true;
      # programs.nix-ld.libraries = with pkgs; [
      # Add any missing dynamic libraries for unpackaged programs
      # here, NOT in environment.systemPackages
      #];
    };
  };
}
