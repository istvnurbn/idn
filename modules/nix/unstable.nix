{
  config,
  inputs,
  den,
  ...
}: let
  unstableOverlay = final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final.stdenv.hostPlatform) system;
      # Same config as the host's pkgs (idn.nixpkgsConfig)
      inherit (final) config;
    };
  };
in {
  # Include this wherever pkgs.unstable is used; Den dedupes it.
  den.aspects.unstable.os = {
    nixpkgs.overlays = [unstableOverlay];
  };

  # Den's perSystem equivalent: becomes flake.legacyPackages.<system> for every
  # system in den.systems, so the idn registry entry (nix aspect) has packages
  # to serve.
  den.schema.flake-system.includes = [den.aspects.idn-pkgs];

  # Class content is a module and pkgs has its own `config` attribute,
  # so the package set has to sit under an explicit `config`.
  den.aspects.idn-pkgs.legacyPackages = {pkgs, ...}: {
    config = import inputs.nixpkgs {
      inherit (pkgs.stdenv.hostPlatform) system;
      # Like the hosts: Macs also allow unsupported systems (nix-darwin.nix)
      config = config.idn.nixpkgsConfig // {allowUnsupportedSystem = pkgs.stdenv.hostPlatform.isDarwin;};
      overlays = [unstableOverlay];
    };
  };
}
