# Exposes flake apps under the name of each host / home for building with nh.
# Check-only hosts (modules/checks/) can't be deployed, so they get none.
{
  den,
  lib,
  inputs,
  ...
}: let
  checkOnly = lib.concatMap (
    hosts: lib.attrNames (lib.filterAttrs (_: host: lib.take 1 host.intoAttr == ["checks"]) hosts)
  ) (lib.attrValues den.hosts);
in {
  flake.packages = lib.genAttrs den.systems (
    system:
      removeAttrs (den.lib.nh.denPackages {fromFlake = true;} inputs.nixpkgs.legacyPackages.${system}) checkOnly
  );
}
