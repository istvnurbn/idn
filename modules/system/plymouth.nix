{
  den.aspects.plymouth = {
    nixos = { pkgs, ... }: {
      boot = {
        plymouth = {
          enable = true;
          theme = "nixos-bgrt";
          themePackages = with pkgs; [
            nixos-bgrt-plymouth
          ];
        };

        # Enable "Silent boot"
        consoleLogLevel = 3;
        initrd.verbose = false;
        kernelParams = [
          "quiet"
          "udev.log_level=3"
          "systemd.show_status=auto"
        ];
        # Hide the OS choice for bootloaders.
        # It's still possible to open the bootloader list by pressing any key
        # It will just not appear on screen unless a key is pressed
        loader.timeout = 0;
      };
    };
  };
}
