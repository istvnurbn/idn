{ inputs, den, ... }:
{
  # we can import this flakeModule even if we dont have flake-parts as input!
  imports = [ inputs.den.flakeModule ];

  den.hosts.x86_64-linux.vermilion.users.steve = {
    classes = [ "user" ]; # no homeManager
  };

  den.aspects.vermilion = {
    includes = [
      den.batteries.hostname
      den.aspects.amdcpu
      den.aspects.amdgpu
      # Takes the device id and swap size as an argument
      # In case you want to hibernate, check disko.nix file.
      (den.provides.disko-btrfs-main "/dev/disk/by-id/nvme-CT1000T710SSD8_2536530B906D" "48G")
    ];
    nixos =
      { pkgs, lib, ... }:
      {
        imports = [
          ./_nixos/configuration.nix
        ];
        # Enables non-free firmware on devices not recognized by `nixos-generate-config`.
        hardware.enableRedistributableFirmware = lib.mkDefault true;

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
      };
  };

  den.aspects.steve = {
    includes = [ den.batteries.primary-user ];
  };
}
