# DO-NOT-EDIT. This file was auto-generated using github:denful/flake-file.
# Run `nix run .#write-flake` or `just write` to regenerate it.
{
  description = "iDN - istvnurbn's dendritic nixconfig";

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  inputs = {
    betterfox-userjs.url = "github:istvnurbn/betterfox-userjs-nix";
    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    den.url = "github:denful/den";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dtop = {
      url = "github:amir20/dtop";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs-unstable";
      };
    };
    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };
    flake-file.url = "github:denful/flake-file";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-lib";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    helium = {
      url = "github:schembriaiden/helium-browser-nix-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        utils.follows = "flake-utils";
      };
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs = {
        home-manager.follows = "";
        nixpkgs.follows = "";
      };
    };
    import-tree.url = "github:denful/import-tree";
    moonshine = {
      url = "github:scottjab/moonshine/3eee41145022e217366e02413f7e1f9d4a8494f3";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
      inputs = {
        flake-compat.follows = "flake-compat";
        flake-parts.follows = "flake-parts";
      };
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/release-26.05";
      inputs = {
        flake-compat.follows = "flake-compat";
        nixpkgs.follows = "nixpkgs";
      };
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-lib.follows = "nixpkgs";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur = {
      url = "github:nix-community/NUR";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
      };
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };
    proton-cachyos = {
      url = "github:powerofthe69/proton-cachyos-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    scopebuddy = {
      url = "github:OpenGamingCollective/ScopeBuddy";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    systems.url = "github:nix-systems/default";
  };
}
