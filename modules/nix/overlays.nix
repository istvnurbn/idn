{inputs, ...}: {
  flake-file.inputs = {
    nixpkgs-unstable.follows = "chaotic/nixpkgs";
  };

  den.aspects.overlays = {
    os = {
      nixpkgs.overlays = [
        (final: prev: {
          unstable = import inputs.nixpkgs-unstable {
            inherit (final.stdenv.hostPlatform) system;
            inherit (final) config;
          };
        })
      ];
    };
  };
}
