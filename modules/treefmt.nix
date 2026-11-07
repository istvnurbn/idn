{
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.treefmt-nix = {
    url = "github:numtide/treefmt-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
// lib.optionalAttrs (inputs ? treefmt-nix) {
  imports = [inputs.treefmt-nix.flakeModule];

  perSystem.treefmt = {
    projectRootFile = "flake.nix";
    programs.alejandra.enable = true;
  };
}
