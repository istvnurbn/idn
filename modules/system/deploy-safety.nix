# Warn (and require confirmation) if the machine's actual hostname doesn't
# match the config being switched to, e.g. `nh os switch --hostname foo` run
# against the wrong box. Adapted from nix-community/srvos's
# detect-hostname-change.nix, written natively rather than imported.
{
  den.aspects.deploy-safety.nixos = {
    config,
    lib,
    ...
  }:
    lib.mkIf (config.networking.hostName != "") {
      system.preSwitchChecks.detectHostnameChange = ''
        detectHostnameChange() {
          local actual
          actual="$(< /proc/sys/kernel/hostname)"

          # Skip during initial install (e.g. nixos-anywhere's installer env)
          if [[ ! -e /run/booted-system || "$actual" == "nixos-installer" ]]; then
            return
          fi

          local desired="${config.networking.hostName}"

          if [[ "$actual" = "$desired" ]]; then
            return
          fi

          # Escape hatch for automation
          if [[ "''${EXPECTED_HOSTNAME:-}" = "$desired" ]]; then
            return
          fi

          echo "WARNING: machine hostname is '$actual', but this config is for '$desired'." >&2
          echo "Are you deploying to the right host? Type YES to continue:" >&2
          read -r reply
          if [[ "$reply" != YES ]]; then
            echo "aborting" >&2
            exit 1
          fi
        }
        detectHostnameChange
      '';
    };
}
