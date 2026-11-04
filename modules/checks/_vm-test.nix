# Turns a Den host into a check-only VM test. Den resolves the host's
# aspects as usual, but runNixOSTest boots them as the node `machine`
# instead of nixosSystem building them, and the test lands in
# checks.<system>.<host name>. Used by modules/checks/*.nix; the leading
# underscore keeps import-tree from loading it as a module.
{
  inputs,
  lib,
}: {
  testScript,
  users ? {},
  nodes ? {},
  extraModules ? [],
}: {config, ...}: {
  inherit users;
  intoAttr = ["checks" config.system config.name];

  instantiate = {modules, ...}:
    inputs.nixpkgs.legacyPackages.${config.system}.testers.runNixOSTest {
      inherit (config) name;
      inherit testScript;
      # The aspects set nixpkgs.* options
      node.pkgsReadOnly = false;

      nodes =
        nodes
        // {
          machine = {
            imports = modules ++ extraModules;
            # The overlays aspect puts the repo itself in the registry, which
            # would re-run every test on every commit
            nix.registry = lib.mkForce {};
          };
        };
    };
}
