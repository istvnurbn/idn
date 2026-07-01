{inputs, ...}: {
  flake-file.inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

  den.aspects.overlays = {
    os = {
      nixpkgs.overlays = [
        (final: prev: {
          unstable = import inputs.nixpkgs-unstable {
            config.allowUnfree = true;
          };
        })
      ];
    };
  };
}
