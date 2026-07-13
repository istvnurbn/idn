{
  den.aspects.firmware = {
    nixos = {
      hardware = {
        # Enables non-free firmware on devices not recognized by `nixos-generate-config`.
        enableRedistributableFirmware = true;

        # Enable all firmware, including unfree packages that must be explictly allowed.
        enableAllFirmware = true;
      };

      # Enable fwupd, a DBus service that allows applications to update firmware.
      services.fwupd.enable = true;
    };
  };
}
