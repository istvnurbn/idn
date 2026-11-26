# Inputs shared by many aspects (nixpkgs, home-manager, flake plumbing) are
# declared here; most others sit next to the aspect that uses them. flake-file
# collects them all to regenerate flake.nix.
# Run `nix run .#write-flake` or `just write` after adding or changing any input.
{
  config,
  lib,
  ...
}: {
  # The stable release every stable input tracks (also nix/wsl.nix and
  # nix/nix-darwin.nix). `just bump-stable <version>` rewrites the line below.
  # Not stateVersion: that records each host's install release (dendritic.nix).
  options.idn.stableRelease = lib.mkOption {
    type = lib.types.str;
    description = "NixOS release the stable inputs track";
  };
  config.idn.stableRelease = "26.05";

  config.flake-file = {
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
        url = "github:nix-community/home-manager/release-${config.idn.stableRelease}";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      import-tree.url = "github:denful/import-tree";
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-${config.idn.stableRelease}";
      nixpkgs-lib.follows = "nixpkgs";
      # pkgs.unstable (nix/unstable.nix) and every input that follows
      # nixpkgs-unstable use Nyx's pin, so Nyx's binary cache matches.
      # Needs the chaotic input (nix/chaotic.nix).
      nixpkgs-unstable.follows = "chaotic/nixpkgs";
      # Followed by lanzaboote (secure-boot.nix) and openlogi (openlogi.nix)
      rust-overlay = {
        url = "github:oxalica/rust-overlay";
        inputs.nixpkgs.follows = "nixpkgs-unstable";
      };
      systems.url = "github:nix-systems/default";
    };
    description = "iDN - istvnurbn's dendritic nixconfig";
    do-not-edit = ''
      # DO-NOT-EDIT. This file was auto-generated using github:denful/flake-file.
      # Run `nix run .#write-flake` or `just write` to regenerate it.
    '';
    outputs = "dendritic";
    # Format flake.nix like the rest of the repo (flake-file defaults to nixfmt)
    formatter = pkgs: pkgs.alejandra;
  };
}
