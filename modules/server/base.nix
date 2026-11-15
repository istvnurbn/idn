# Baseline for headless NixOS servers
{
  den.aspects.server-base.nixos = {
    lib,
    pkgs,
    ...
  }: {
    # No GUI aspects will be included on these hosts, but disable explicitly anyway
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

    # UTC everywhere on servers
    time.timeZone = lib.mkDefault "UTC";

    networking = {
      useNetworkd = lib.mkDefault true;
      firewall = {
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
        # Forcefully reboot if the system hangs without progress.
        RuntimeWatchdogSec = lib.mkDefault "15s";
        RebootWatchdogSec = lib.mkDefault "30s";
        KExecWatchdogSec = lib.mkDefault "1m";
      };
    };

    boot = {
      # The bootloader comes from the host: the boot aspect on UEFI, GRUB on a BIOS VPS
      loader.timeout = lib.mkDefault 3;

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
