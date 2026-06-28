{inputs, ...}: {
  flake-file.inputs = {
    helium = {
      url = "github:schembriaiden/helium-browser-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  den.aspects.browsers = {user, ...}: {
    os = {pkgs, ...}: {
      nixpkgs.overlays = [inputs.helium.overlays.default];

      environment.systemPackages = with pkgs; [
        helium
      ];
    };

    nixos = {pkgs, ...}: {
      programs.firefox.enable = true;

      environment.systemPackages = with pkgs; [
        tor-browser
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
          ".config/mozilla"
          ".cache/tor project"
        ];
      };
    };
  };
}
