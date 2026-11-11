{
  den.aspects.amdcpu = {
    nixos = {
      lib,
      config,
      ...
    }: {
      # Update the CPU microcode for AMD processors
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

      boot = {
        kernelModules = ["kvm-amd"];
      };
    };
  };
}
