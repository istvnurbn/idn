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

      # Add your user to the gamemode group
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

      environment.systemPackages = with pkgs; [
        mangohud
        gamescope
        inputs.scopebuddy.packages.${pkgs.stdenv.hostPlatform.system}.default
        wineWow64Packages.wayland
        protonup-qt
      ];

      environment.sessionVariables = {
        # Proton settings
        PROTON_ENABLE_HDR = "1";
        PROTON_ENABLE_WAYLAND = "1";
        PROTON_FSR4_UPGRADE = "1";
        PROTON_USE_NTSYNC = "1";
        # Disable mesh shaders — common cause of VKD3D ring timeouts on RDNA4
        RADV_DEBUG = "nomeshshader";
        # Disable upload heap host-visible VRAM — improves stability with VKD3D DX12 titles
        VKD3D_CONFIG = "no_upload_hvv";
      };
    };
  };
}
