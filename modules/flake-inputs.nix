# Most flake inputs are declared here so flake-file can regenerate flake.nix.
# Run `nix run .#write-flake` or `just write` after adding or changing any input.
{
  flake-file = {
    inputs = {
      flake-parts = {
        url = "github:hercules-ci/flake-parts";
        inputs.nixpkgs-lib.follows = "nixpkgs-lib";
      };
      flake-utils = {
        url = "github:numtide/flake-utils";
        inputs.systems.follows = "systems";
      };
      home-manager = {
        url = "github:nix-community/home-manager/release-26.05";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      import-tree.url = "github:denful/import-tree";
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
      nixpkgs-lib.follows = "nixpkgs";
      nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
      systems.url = "github:nix-systems/default";
    };
    description = "IDN - istvnurbn's dendritic nixconfig";
    do-not-edit = ''
      # DO-NOT-EDIT. This file was auto-generated using github:denful/flake-file.
      # Run `nix run .#write-flake` or `just write` to regenerate it.
    '';
    outputs = "dendritic";
  };
}
