{
  flake-file = {
    inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
      import-tree.url = "github:denful/import-tree";
      flake-parts.url = "github:hercules-ci/flake-parts";
    };
  };
}
