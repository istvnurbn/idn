{den, ...}: {
  den.aspects.vermilion = {
    includes = [
      # Hardware
      den.aspects.firmware
      den.aspects.amdcpu
      den.aspects.amdgpu
      den.aspects.audio
      den.aspects.bluetooth
      den.aspects.coolercontrol
      den.aspects.openrgb
      den.aspects.lact
      # Takes the device id and swap size as an argument
      # In case you want to hibernate, check the disko.nix file.
      (den.provides.disko-btrfs-impermanence-main "/dev/disk/by-id/nvme-CT1000T710SSD8_2536530B906D" "48G")
      (den.provides.disko-btrfs-data "/dev/disk/by-id/nvme-CT2000T710SSD8_2532525EB150")

      # System
      den.aspects.boot
      den.aspects.cachyos-kernel
      den.aspects.impermanence
      (den.provides.impermanence "/persist")

      # Base
      den.aspects.nix
      den.aspects.overlays
      den.aspects.networking
      den.aspects.avahi
      den.aspects.locale
      den.aspects.sudo
      den.aspects.openssh
      den.aspects.shell
      den.aspects.tailscale

      # Misc. shell
      den.aspects.devel
      den.aspects.media-cli

      # Desktop
      den.aspects.plymouth
      den.aspects.plasma
      den.aspects.fonts
      den.aspects.desktop-base
      den.aspects.firefox
      den.aspects.helium
      den.aspects.tor
      den.aspects.office
      den.aspects.flatpak
      den.aspects.media

      # Gaming
      den.aspects.gaming-base
      den.aspects.gaming-udev
      den.aspects.steam
      den.aspects.heroic
      # den.aspects.sunshine
      den.aspects.moonshine
    ];

    nixos = {
      # Enables hibernation from swap file on a btrfs subvol
      # sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
      boot.resumeDevice = "/dev/disk/by-partlabel/disk-main-root";
      boot.kernelParams = ["resume_offset=533760"];

      boot.initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];

      # Disable printing
      services.printing.enable = false;

      services.hardware.openrgb.motherboard = "amd";
    };
  };
}
