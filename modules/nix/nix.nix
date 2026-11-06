{
  den.aspects.nix = {
    os = {pkgs, ...}: {
      nix = {
        # Flakes-only; don't leave channel state/commands lying around
        channel.enable = false;

        settings = {
          # Users and groups that have additional rights when connecting to the Nix daemon
          trusted-users = [
            "@wheel"
          ];

          # Avoid re-transferring already-substitutable paths over SSH when
          # using a remote builder
          builders-use-substitutes = true;

          # Enable the Flakes feature and the accompanying new nix command-line tool
          experimental-features = [
            "nix-command"
            "flakes"
          ];

          warn-dirty = false;

          commit-lock-file-summary = "chore: update flake.lock";

          # From https://jackson.dev/post/nix-reasonable-defaults/
          connect-timeout = 5;
          min-free = 128000000;
          max-free = 1000000000;
          fallback = true;

          # List of binary cache URLs used to obtain pre-built binaries of Nix packages
          substituters = [
            "https://nix-community.cachix.org"
          ];

          trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
        };

        # Hard-links identical files in the store on a schedule. One optimiser
        # for both OSes: nix-darwin refuses auto-optimise-store on Nix
        # versions where it can corrupt the store.
        optimise.automatic = true;
      };

      nixpkgs.config = {
        # Allow non-free packages
        allowUnfree = true;

        # Many packages report they don't support aarch64-darwin, but they build and run fine here.
        allowUnsupportedSystem = true;
      };

      environment = {
        variables = {
          NH_FLAKE = "$HOME/idn";
        };

        # Utils making it easier to deal with Nix
        systemPackages = with pkgs; [
          nixd
          alejandra
        ];
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
      };
    };

    nixos = {
      programs = {
        nh = {
          enable = true;
          clean.enable = true;
          clean.extraArgs = "--keep-since 7d --keep 3";
        };

        nix-ld.enable = true;
        # programs.nix-ld.libraries = with pkgs; [
        # Add any missing dynamic libraries for unpackaged programs
        # here, NOT in environment.systemPackages
        #];
      };
    };

    darwin = {
      config,
      pkgs,
      ...
    }: {
      environment.systemPackages = with pkgs; [
        nh
      ];

      # nix-darwin has no programs.nh module, so replicate what
      # programs.nh.clean gives NixOS: a weekly `nh clean all` run,
      # scheduled the same way nix-darwin's own nix.gc.interval default is.
      launchd.daemons.nh-clean = {
        command = "${pkgs.nh}/bin/nh clean all --keep-since 7d --keep 3";
        path = [config.nix.package];
        serviceConfig = {
          RunAtLoad = false;
          StartCalendarInterval = [
            {
              Weekday = 7;
              Hour = 3;
              Minute = 15;
            }
          ];
        };
      };
    };
  };
}
