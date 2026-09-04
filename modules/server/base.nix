# Baseline for headless NixOS servers (homelab, VPS). Include on every such
# host; internet-facing ones additionally get server-internet-facing.nix.
#
# Deliberately not included here, unlike the desktop-oriented aspects of the
# same name: `networking` (NetworkManager + darwin computerName, not a fit
# for a headless box) and `locale` (bundles hu_HU/Hungarian keyboard layout,
# meaningless for an SSH-only machine). This aspect provides its own minimal
# equivalents below instead. Same reasoning for `boot`: its memtest86/
# netbootxyz boot-menu entries are useless without physical/console access,
# so this aspect owns its own minimal systemd-boot setup rather than
# combining with it.
#
# Deliberately not adopted from nix-community/srvos, which this is inspired
# by: `services.userborn` (its own upstream code guards against enabling it
# together with impermanence, which these hosts use) and anything
# ZFS-related (not this config's established pattern — these hosts are
# btrfs, matching vermilion).
{
  den.aspects.server-base.nixos = {
    lib,
    pkgs,
    ...
  }: {
    # Headless: no GUI aspects will be included on these hosts, but disable
    # explicitly anyway (documentation/fonts/xdg all cost store space and
    # build time for nothing on a box with no desktop session).
    fonts.fontconfig.enable = lib.mkDefault false;
    documentation.nixos.enable = lib.mkDefault false;
    documentation.doc.enable = lib.mkDefault false;
    documentation.info.enable = lib.mkDefault false;
    documentation.man.enable = lib.mkDefault false;
    xdg.autostart.enable = lib.mkDefault false;
    xdg.icons.enable = lib.mkDefault false;
    xdg.menus.enable = lib.mkDefault false;
    xdg.mime.enable = lib.mkDefault false;
    xdg.sounds.enable = lib.mkDefault false;

    # UTC everywhere on servers: avoids DST-transition ambiguity in logs and
    # makes correlating logs across machines trivial.
    time.timeZone = lib.mkDefault "UTC";

    networking = {
      useNetworkd = lib.mkDefault true;
      firewall = {
        enable = true;
        allowPing = true;
        # A publicly reachable box gets constant background scan noise;
        # logging every refused connection would flood the journal.
        logRefusedConnections = lib.mkDefault false;
      };
    };

    systemd = {
      # A stuck emergency shell on a box only reachable over SSH is
      # effectively permanent downtime; better to keep trying to boot.
      enableEmergencyMode = false;

      settings.Manager = {
        # Forcefully reboot if the system hangs without progress. No-ops
        # harmlessly if the host has no hardware/virtual watchdog device.
        RuntimeWatchdogSec = lib.mkDefault "15s";
        RebootWatchdogSec = lib.mkDefault "30s";
        KExecWatchdogSec = lib.mkDefault "1m";
      };
    };

    boot = {
      loader = {
        systemd-boot = {
          enable = true;
          # Small cloud-image ESPs fill up after months of updates; servers
          # don't need many generations kept around anyway.
          configurationLimit = lib.mkDefault 5;
        };
        efi.canTouchEfiVariables = true;
        timeout = lib.mkDefault 3;
      };

      # Most cloud providers' only out-of-band recovery path if SSH breaks
      # is a serial console.
      kernelParams =
        ["console=ttyS0,115200"]
        ++ lib.optional pkgs.stdenv.hostPlatform.isAarch "console=ttyAMA0,115200"
        ++ ["console=tty0"];
    };

    programs.vim = {
      enable = true;
      defaultEditor = lib.mkDefault true;
    };

    environment.systemPackages = with pkgs; [
      curl
      dnsutils
      htop
      jq
      tmux
    ];

    # Keep the serial console visible when testing with `nixos-rebuild build-vm`.
    virtualisation.vmVariant.virtualisation.graphics = lib.mkDefault false;
  };
}
