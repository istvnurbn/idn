{
  den.aspects.firmware = {
    nixos = {
      # Enables non-free firmware on devices not recognized by `nixos-generate-config`.
      hardware.enableRedistributableFirmware = true;
      # Enable all firmware, including unfree packages that must be explictly allowed.
      hardware.enableAllFirmware = true;
    };
  };
}
