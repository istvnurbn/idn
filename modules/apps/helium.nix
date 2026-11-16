{inputs, ...}: {
  flake-file.inputs = {
    helium = {
      url = "github:schembriaiden/helium-browser-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
    };
  };

  den.aspects.helium = {
    os = {pkgs, ...}: {
      nixpkgs.overlays = [inputs.helium.overlays.default];

      environment.systemPackages = with pkgs; [
        helium
      ];
    };

    nixos = {
      environment.sessionVariables = {
        NIXOS_OZONE_WL = 1;
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
      };
    };

    persistHome = {
      directories = [
        ".config/net.imput.helium"
      ];
    };
  };
}
