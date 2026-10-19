{
  flake-file.inputs.scopebuddy = {
    url = "github:OpenGamingCollective/ScopeBuddy";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  den.aspects.gaming-base = {
    nixos = {
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

      environment.systemPackages = with pkgs; [
        mangohud
        gamescope_git
        inputs'.scopebuddy.packages.default
        wineWow64Packages.waylandFull
        protonup-qt
      ];
    };

    provides.to-users.user.extraGroups = ["gamemode" "uinput"];
  };
}
