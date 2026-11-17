{
  inputs,
  den,
  ...
}: {
  # rust-overlay is shared with lanzaboote; see flake-inputs.nix
  flake-file.inputs.openlogi = {
    url = "github:AprilNEA/OpenLogi?dir=packaging";
    inputs = {
      nixpkgs.follows = "nixpkgs-unstable";
      rust-overlay.follows = "rust-overlay";
    };
  };

  den.aspects.openlogi = {
    # pkgs.unstable comes from the unstable aspect
    includes = [den.aspects.unstable];

    nixos = {pkgs, ...}: {
      # The flake's module, for its agent service (nixpkgs' module has none)
      imports = [inputs.openlogi.nixosModules.default];

      programs.openlogi = {
        enable = true;
        # The flake's own build fails `cargo test` on nixpkgs-unstable: its
        # cargoSetupHook sets ZSTD_SYS_USE_PKG_CONFIG and xtask's zstd-sys
        # finds no libzstd. nixpkgs' build skips xtask and is in the cache.
        package = pkgs.unstable.openlogi;
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
