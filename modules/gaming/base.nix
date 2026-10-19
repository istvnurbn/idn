{
  flake-file.inputs.scopebuddy = {
    url = "github:OpenGamingCollective/ScopeBuddy";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  den.aspects.gaming-base = {
    nixos = {
      config,
      pkgs,
      inputs',
      ...
    }: {
      # programs.gamemode creates the 'gamemode' group;
      # the user needs to be a member (see provides.to-users below).
      programs.gamemode = {
        enable = true;
        enableRenice = true;
        settings = {
          general = {
            softrealtime = "auto";
            renice = 10;
          };
          gpu = {
            apply_gpu_optimisations = "accept-responsibility";
            amd_performance_level = "high";
            # gpu_device (which GPU index to target) depends on the host's
            # GPU layout; set programs.gamemode.settings.gpu.gpu_device
            # per-host, e.g. in hosts/vermilion.nix.
          };
        };
      };

      # Enable udev rules for Steam hardware and uinput for Steam Input
      hardware = {
        steam-hardware.enable = true;
        uinput.enable = true;
      };

      services.udev.packages = with pkgs; [
        game-devices-udev-rules
        steam-devices-udev-rules
      ];

      # Hosts choose the package; vermilion sets Nyx's gamescope_git.
      programs.gamescope.enable = true;

      environment.systemPackages = with pkgs; [
        mangohud
        # scb prefixes its own gamescope onto PATH; hand it the host's choice instead.
        (inputs'.scopebuddy.packages.default.override {gamescope = config.programs.gamescope.package;})
        wineWow64Packages.waylandFull
        protonup-qt
      ];
    };

    provides.to-users.user.extraGroups = ["gamemode" "uinput"];
  };
}
