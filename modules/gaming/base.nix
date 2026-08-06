{inputs, ...}: {
  flake-file.inputs = {
    proton-cachyos = {
      url = "github:powerofthe69/proton-cachyos-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    scopebuddy = {
      url = "github:OpenGamingCollective/ScopeBuddy";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  den.aspects.gaming-base = {
    nixos = {pkgs, ...}: {
      nixpkgs.overlays = [
        inputs.proton-cachyos.overlays.default
      ];

      # programs.gamemode creates the 'gamemode' group;
      # the user needs to be a member (see steve.nix).
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
            gpu_device = 1;
            amd_performance_level = "high";
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
        gamescope
        inputs.scopebuddy.packages.${pkgs.stdenv.hostPlatform.system}.default
        wineWow64Packages.waylandFull
        protonup-qt
      ];

      environment.sessionVariables = {
        # Disable mesh shaders — common cause of VKD3D ring timeouts on RDNA4
        RADV_DEBUG = "nomeshshader";
        # Disable upload heap host-visible VRAM — improves stability with VKD3D DX12 titles
        VKD3D_CONFIG = "no_upload_hvv";
      };
    };

    provides.to-users = {user, ...}: {
      nixos.users.users.${user.name}.extraGroups = ["gamemode" "uinput"];
    };
  };
}
