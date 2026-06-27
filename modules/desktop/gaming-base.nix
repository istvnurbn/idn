{inputs, ...}: {
  flake-file.inputs = {
    proton-cachyos.url = "github:powerofthe69/proton-cachyos-nix";
    scopebuddy.url = "github:OpenGamingCollective/ScopeBuddy";
  };

  den.aspects.gaming-base = {
    nixos = {pkgs, ...}: {
      nixpkgs.overlays = [
        inputs.proton-cachyos.overlays.default
      ];

      environment.systemPackages = with pkgs; [
        gamemode
        mangohud
        gamescope
        inputs.scopebuddy.packages.${pkgs.stdenv.hostPlatform.system}.default
        wineWow64Packages.wayland
        protonup-qt
        protontricks
      ];

      environment.sessionVariables = {
        # Proton settings
        PROTON_ENABLE_WAYLAND = "1";
        PROTON_ENABLE_HDR = "1";
        PROTON_FSR4_UPGRADE = "1";
      };
    };
  };
}
