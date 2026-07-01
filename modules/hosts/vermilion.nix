{den, ...}: {
  den.aspects.vermilion = {
    includes = [
      # Hardware
      den.aspects.amdcpu
      den.aspects.amdgpu
      den.aspects.audio
      den.aspects.bluetooth
      den.aspects.coolercontrol
      den.aspects.firmware
      den.aspects.openrgb
      # Takes the device id and swap size as an argument
      # In case you want to hibernate, check disko.nix file.
      (den.provides.disko-btrfs-impermanence-main "/dev/disk/by-id/nvme-CT1000T710SSD8_2536530B906D" "48G")
      (den.provides.disko-btrfs-data "/dev/disk/by-id/nvme-CT2000T710SSD8_2532525EB150")

      # System
      den.aspects.boot
      den.aspects.cachyos-kernel
      den.aspects.impermanence
      (den.provides.impermanence "/persist")

      # Software
      den.aspects.base
      den.aspects.devel
      den.aspects.media
      den.aspects.desktop
      den.aspects.flatpak
      den.aspects.gui-media
      den.aspects.gaming
      den.aspects.helium
      den.aspects.tor
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
    };
  };
}
