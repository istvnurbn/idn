{
  den.aspects.efi-boot = {
    nixos = {
      # Use the systemd-boot EFI boot loader.
      boot.loader = {
        systemd-boot = {
          enable = true;
          configurationLimit = 3;
          # Make Memtest86+ available from the systemd-boot menu
          memtest86 = {
            enable = true;
            sortKey = "o_memtest86";
          };
          # netboot.xyz allows you to boot OS installers and utilities over the network
          netbootxyz = {
            enable = true;
            sortKey = "o_netbootxyz";
          };
        };
        efi.canTouchEfiVariables = true;
      };
    };
  };
}
