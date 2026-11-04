# Every host's full system build, so `just check` catches build failures
# and not only evaluation errors. `nix flake check` builds only the current
# system's checks, so each machine builds the hosts of its own platform.
{
  config,
  den,
  lib,
  ...
}: let
  deployable = host:
    lib.elem (lib.take 1 host.intoAttr) [
      ["nixosConfigurations"]
      ["darwinConfigurations"]
    ];
in {
  flake.checks = lib.genAttrs den.systems (
    system:
      lib.concatMapAttrs (
        name: host:
          lib.optionalAttrs (deployable host) {
            "host-${name}" = (lib.getAttrFromPath host.intoAttr config.flake).config.system.build.toplevel;
          }
      ) (den.hosts.${system} or {})
  );
}
