{
  flake-file = {
    description = "IDN - istvnurbn's dendritic nixconfig";

    inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
      nixpkgs-lib.follows = "nixpkgs";
      disko = {
        url = "github:nix-community/disko";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      import-tree.url = "github:denful/import-tree";
      flake-file.url = "github:denful/flake-file";
    };

    do-not-edit = ''
      # DO-NOT-EDIT. This file was auto-generated using github:denful/flake-file.
      # Use `just write` to regenerate it.
    '';
  };
}
