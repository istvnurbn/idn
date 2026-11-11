{inputs, ...}: {
  # nixpkgs-unstable follows this input's nixpkgs; see flake-inputs.nix
  flake-file.inputs.chaotic = {
    url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    inputs.home-manager.follows = "";
  };

  # Include this wherever Nyx packages are used; Den dedupes it.
  den.aspects.chaotic.nixos.imports = with inputs.chaotic.nixosModules; [
    nyx-cache
    nyx-overlay
    nyx-registry
  ];
}
