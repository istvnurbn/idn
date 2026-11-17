{
  den.aspects.firmware = {
    nixos = {
      hardware = {
        # Enable all firmware, including unfree packages that must be explictly allowed.
        enableAllFirmware = true;
      };

      # Enable fwupd, a DBus service that allows applications to update firmware.
      services.fwupd.enable = true;
    };

    # fwupd's update history (pending.db): after the reboot that applies an
    # update, fwupd reads it to find out and report whether the update worked
    persist.directories = ["/var/lib/fwupd"];
  };
}
