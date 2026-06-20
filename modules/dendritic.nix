{ inputs, ... }:
{
  flake-file.inputs = {
    den.url = "github:denful/den";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-lib";
    };
  };
  # we can import this flakeModule even if we dont have flake-parts as input!
  imports = [
    (inputs.flake-file.flakeModules.dendritic or { })
    (inputs.den.flakeModules.dendritic or { })
  ];
}
