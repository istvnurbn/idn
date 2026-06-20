{ den, ... }: {
  den.aspects.vermilion = {
    includes = [
      den.aspects.efi-boot
      den.aspects.plymouth
      den.aspects.firmware
      den.aspects.amdcpu
      den.aspects.amdgpu
      den.aspects.audio
      den.aspects.bluetooth
      den.aspects.networking
      # Takes the device id and swap size as an argument
      # In case you want to hibernate, check disko.nix file.
      (den.provides.disko-btrfs-main "/dev/disk/by-id/nvme-CT1000T710SSD8_2536530B906D" "48G")
      den.aspects.security
      den.aspects.locale
      den.aspects.nix-settings
      den.aspects.shell
      den.aspects.nix-tools
      den.aspects.dev-tools
      den.aspects.kde-desktop
      den.aspects.browsers
    ];

    nixos =
      { pkgs, lib, ... }:
      {
        # Use latest kernel.
        boot.kernelPackages = pkgs.linuxPackages_latest;

        # Enables hibernation from swap file on a btrfs subvol
        # sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
        boot.resumeDevice = "/dev/disk/by-partlabel/disk-main-root";
        boot.kernelParams = [ "resume_offset=533760" ];

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
