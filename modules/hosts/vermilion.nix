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
      # Disk ids, swap size and resume offset are settings in hosts.nix
      disko-btrfs-impermanence-main
      disko-btrfs-data

      # System
      boot
      cachyos-kernel
      impermanence
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
