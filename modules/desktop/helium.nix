{inputs, ...}: {
  flake-file.inputs = {
    helium = {
      url = "github:schembriaiden/helium-browser-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
    };
  };

  den.aspects.helium = {user, ...}: {
    os = {pkgs, ...}: {
      nixpkgs.overlays = [inputs.helium.overlays.default];

      environment.systemPackages = with pkgs; [
        helium
      ];

      environment.sessionVariables = {
        NIXOS_OZONE_WL = 1;
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
      };
    };

    impermanence = {
      users.${user.name} = {
        directories = [
          ".config/net.imput.helium"
        ];
      };
    };
  };
}
