{
  flake-file = {
    inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
      nixpkgs-lib.follows = "nixpkgs";
      import-tree.url = "github:denful/import-tree";
      flake-parts = {
        inputs.nixpkgs-lib.follows = "nixpkgs-lib";
        url = "github:hercules-ci/flake-parts";
      };
    };
  };
}
