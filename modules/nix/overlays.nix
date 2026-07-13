{inputs, ...}: {
  flake-file.inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

  den.aspects.overlays = {
    os = {host, ...}: {
      nixpkgs.overlays = [
        (final: prev: {
          unstable = import inputs.nixpkgs-unstable {
            system = host.system;
            config.allowUnfree = true;
          };
        })
      ];
    };
  };
}
