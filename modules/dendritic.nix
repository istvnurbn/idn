{ inputs, ... }:
{
  flake-file = {
    inputs = {
      flake-file.url = "github:denful/flake-file";
      den.url = "github:denful/den";
    };
    description = "IDN - istvnurbn's dendritic nixconfig";
    do-not-edit = ''
      # DO-NOT-EDIT. This file was auto-generated using github:denful/flake-file.
      # Use `just write` to regenerate it.
    '';
    outputs = "dendritic";
  };

  imports = [
    (inputs.flake-file.flakeModules.dendritic or { })
    (inputs.den.flakeModules.dendritic or { })
  ];
}
