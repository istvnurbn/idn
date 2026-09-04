{den, ...}: {
  den.aspects.vermilion = {
    includes = with den.aspects; [
      # Hardware
      firmware
      amdcpu
      amdgpu
      audio
      bluetooth
      coolercontrol
      openrgb
      lact
      # Takes the device id and swap size as an argument
      # In case you want to hibernate, check the disko.nix file.
      (den.provides.disko-btrfs-impermanence-main "/dev/disk/by-id/nvme-CT1000T710SSD8_2536530B906D" "48G")
      (den.provides.disko-btrfs-data "/dev/disk/by-id/nvme-CT2000T710SSD8_2532525EB150")

      # System
      boot
      cachyos-kernel
      impermanence
      (den.provides.impermanence "/persist")
      deploy-safety

      # Base
      nix
      overlays
      networking
      avahi
      locale
      sudo
      openssh
      shell
      tailscale

      # Misc. shell
      devel
      media-cli

      # Desktop
      plymouth
      plasma
      fonts
      desktop-base
      firefox
      helium
      tor
      office
      flatpak
      media

      # Gaming
      gaming-base
      steam
      heroic
      # sunshine
      moonshine
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

      # GPU index/PCI address specific to this machine's hardware layout.
      # See gaming/base.nix and gaming/moonshine.nix.
      programs.gamemode.settings.gpu.gpu_device = 1;
      services.moonshine.settings.compositor.gpu = "0000:03:00.0";
    };
  };
}
