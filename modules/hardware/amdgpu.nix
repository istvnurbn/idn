{
  den.aspects.amdgpu = {
    nixos = {
      # Kernel modules for amdgpu
      boot.kernelModules = [
        "amdgpu"
      ];

      # Enable hardware accelerated graphics drivers
      hardware = {
        graphics = {
          enable = true;
          enable32Bit = true; # also install 32-bit drivers for 32-bit applications
        };
        amdgpu = {
          initrd.enable = true; # Can fix lower resolution in boot screen during initramfs phase
          overdrive.enable = true; # Overclocking
          opencl.enable = true; # OpenCL support using ROCM runtime library
        };
      };

      # Enable LACT, a tool for monitoring, configuring and overclocking GPUs
      services.lact.enable = true;
    };
  };
}
