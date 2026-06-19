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
    ];
    nixos =
      { pkgs, lib, ... }:
      {
        imports = [
          ./_nixos/configuration.nix
          inputs.disko.nixosModules.disko
        ];
        # Enables non-free firmware on devices not recognized by `nixos-generate-config`.
        hardware.enableRedistributableFirmware = lib.mkDefault true;

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
