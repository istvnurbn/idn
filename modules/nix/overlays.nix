{
  inputs,
  den,
  ...
}: let
  unstableOverlay = final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final.stdenv.hostPlatform) system;
      inherit (final) config;
    };
  };
in {
  den.aspects.overlays.os = {
    nixpkgs.overlays = [unstableOverlay];
    nix.registry.unstable.flake = inputs.nixpkgs-unstable;
    nix.registry.idn.flake = inputs.self;
  };

  # Den's perSystem equivalent: becomes flake.legacyPackages.<system> for every
  # system in den.systems, so `nix shell idn#<pkg>` / `idn#unstable.<pkg>` allow unfree.
  den.schema.flake-system.includes = [den.aspects.idn-pkgs];

  # Class content is a module and pkgs has its own `config` attribute,
  # so the package set has to sit under an explicit `config`.
  den.aspects.idn-pkgs.legacyPackages = {pkgs, ...}: {
    config = import inputs.nixpkgs {
      inherit (pkgs.stdenv.hostPlatform) system;
      config.allowUnfree = true;
      overlays = [unstableOverlay];
    };
  };
}
