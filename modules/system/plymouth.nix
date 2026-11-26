{
  den.aspects.plymouth = {
    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: {
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
        # 26.11 removed scripted stage 1 and this option with it (vermilion runs unstable)
        initrd.verbose = lib.mkIf (lib.versionOlder config.system.nixos.release "26.11") false;
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
