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
      openlogi
      openrgb
      lact
      # Disk ids, swap size and resume offset are settings in hosts.nix
      disko-btrfs-impermanence-main
      disko-btrfs-data

      # System
      boot
      impermanence
      deploy-safety

      # Base
      nix
      overlays
      chaotic
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

    nixos = {pkgs, ...}: {
      boot = {
        kernelPackages = pkgs.linuxPackages_cachyos-lto-znver4;
        kernelModules = ["ntsync"];

        initrd.availableKernelModules = [
          "nvme"
          "xhci_pci"
          "ahci"
          "usb_storage"
          "usbhid"
          "sd_mod"
        ];
      };

      # Disable printing
      services.printing.enable = false;

      # Wire gamescope through the host
      programs.gamescope.package = pkgs.gamescope_git;

      services.hardware.openrgb.motherboard = "amd";

      # GPU index/PCI address specific to this machine's hardware layout.
      # See hardware/amdgpu.nix and gaming/moonshine.nix.
      programs.gamemode.settings.gpu.gpu_device = 1;
      services.moonshine.settings.compositor.gpu = "0000:03:00.0";
    };
  };
}
