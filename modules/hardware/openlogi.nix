{inputs, ...}: {
  flake-file.inputs = {
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    openlogi = {
      url = "github:AprilNEA/OpenLogi";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        rust-overlay.follows = "rust-overlay";
      };
    };
  };

  den.aspects.openlogi.nixos = {
    imports = [inputs.openlogi.nixosModules.default];

    programs.openlogi = {
      enable = true;
      # Starts openlogi-agent with graphical-session.target by default.
      launchAtLogin = true;
    };
  };
}
