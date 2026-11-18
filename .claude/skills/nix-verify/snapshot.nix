# drvPath of every check of the flake at `ref`, to compare a change:
# identical drvPath = identical system. Used by SKILL.md:
#   nix eval --json --impure --expr 'import ./snapshot.nix "<flake ref>"'
ref: let
  flake = builtins.getFlake ref;
  inherit (flake.inputs.nixpkgs) lib;
  hosts = flake.nixosConfigurations // flake.darwinConfigurations;
  # The nix aspect registers the repo itself (registry.idn.flake = self), so
  # any edit, even to a README, changes every host. Pin it; the VM tests drop
  # the registry for the same reason (checks/_vm-test.nix).
  pinned = host:
    (host.extendModules {
      modules = [
        {
          nix.registry.idn.to = lib.mkForce {
            type = "path";
            path = "/idn";
          };
        }
      ];
    }).config.system.build.toplevel.drvPath;
in
  lib.mapAttrs (_: checks:
    lib.mapAttrs (name: check:
      if lib.hasPrefix "host-" name
      then pinned hosts.${lib.removePrefix "host-" name}
      else check.drvPath)
    # Both hash the whole source tree, so they change on any edit.
    (removeAttrs checks ["treefmt" "check-flake-file"]))
  flake.checks
