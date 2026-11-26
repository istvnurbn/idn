{
  inputs,
  den,
  ...
}: {
  # nixpkgs-unstable follows this input's nixpkgs; see flake-inputs.nix
  flake-file.inputs.chaotic = {
    url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    inputs.home-manager.follows = "";
  };

  # Include this wherever Nyx packages are used; Den dedupes it.
  den.aspects.chaotic = {
    includes = [den.aspects.unstable];

    nixos = {modulesPath, ...}: {
      imports = with inputs.chaotic.nixosModules; [
        nyx-cache
        nyx-registry
      ];

      # Nyx's packages on the same pin and config that Nyx's nyx-overlay module
      # would import a second time, so the same derivations. A host built from
      # nixpkgs-unstable (vermilion) already has that pin as pkgs, so they go on
      # pkgs; other hosts use the pkgs.unstable copy. Decided from modulesPath:
      # reading final here would recurse.
      # shortcut: skips nyx-overlay's cache-friendly.nix; if the cachyos kernel
      # starts building locally after an update, check what that file changed
      nixpkgs.overlays = [
        (final: _:
          inputs.chaotic.utils.applyOverlay {
            pkgs =
              if toString modulesPath == "${inputs.nixpkgs-unstable}/nixos/modules"
              then final
              else final.unstable;
          })
      ];
    };
  };
}
