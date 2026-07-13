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

        # Enable AMD CPU scaling https://www.kernel.org/doc/html/latest/admin-guide/pm/amd-pstate.html
        # On recent AMD CPUs this can be more energy efficient.
        kernelParams = ["amd_pstate=active"];
      };
    };
  };
}
