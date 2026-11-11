{inputs, ...}: {
  # rust-overlay is shared with lanzaboote; see flake-inputs.nix
  flake-file.inputs.openlogi = {
    url = "github:AprilNEA/OpenLogi?dir=packaging";
    inputs = {
      nixpkgs.follows = "nixpkgs-unstable";
      rust-overlay.follows = "rust-overlay";
    };
  };

  den.aspects.openlogi = {
    nixos = {
      imports = [inputs.openlogi.nixosModules.default];

      programs.openlogi = {
        enable = true;
        # Starts openlogi-agent with graphical-session.target by default.
        launchAtLogin = true;
      };
    };

    persistHome = {
      directories = [
        ".config/openlogi"
        ".local/share/openlogi"
      ];
    };
  };
}
