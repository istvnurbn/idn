# Essentially the impermanence-class example from the den docs,
# cleaned up and made reusable by sjcobb2022 in their nix-den repo.
# There are slight modifications in the impermanenceHostClass and
# comments all over so I can have a better understanding.
{
  den,
  lib,
  ...
}: let
  # Mirrors the impermanence module's environment.persistence.<path>.* options
  # so the forwarded submodule is properly typed rather than freeform.
  # Option schema for the class that declares the options aspects are allowed
  # to set at the impermanenece class: directories, fles, hideMounts, and a
  # users attrset (each user submodule havings its own directories/files).
  impermanenceAdapter = {
    options = {
      directories = lib.mkOption {
        type = lib.types.listOf lib.types.anything;
        default = [];
      };
      files = lib.mkOption {
        type = lib.types.listOf lib.types.anything;
        default = [];
      };
      hideMounts = lib.mkOption {
        type = lib.types.anything;
        default = false;
      };
      users = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            directories = lib.mkOption {
              type = lib.types.listOf lib.types.anything;
              default = [];
            };
            files = lib.mkOption {
              type = lib.types.listOf lib.types.anything;
              default = [];
            };
          };
        });
        default = {};
      };
    };
  };

  #
  impermanenceHostClass = path: {aspect-chain}:
    den.batteries.forward {
      each = lib.singleton true;
      # Read from the impermanence class
      fromClass = _: "impermanence";
      # Write into the nixos class
      intoClass = _: "nixos";
      # Lands the config at environment.persistence.<path>
      intoPath = _: ["environment" "persistence" path];
      # pull the class content from the current aspect being resolved
      fromAspect = _: lib.head aspect-chain;
      # Only forward if the target host actually has environment.persistence defined
      guard = {options, ...}: options ? environment && options.environment ? persistence;
      # Types the forwarded submodule with the schema above
      adapterModule = impermanenceAdapter;
    };
in {
  den.provides.impermanence = impermanenceHostClass;
}
