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
  };
}
