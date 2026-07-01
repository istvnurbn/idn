{
  den.aspects.amdgpu = {
    nixos = {
      # Kernel modules for amdgpu
      boot = {
        kernelModules = [
          "amdgpu"
        ];
        kernelParams = [
          # Allow GPU soft-reset on ring timeout instead of full hang
          "amdgpu.gpu_recovery=1"
        ];
      };

      # Enable hardware accelerated graphics drivers
      hardware = {
        graphics = {
          enable = true;
          # also install 32-bit drivers for 32-bit applications
          enable32Bit = true;
        };
        amdgpu = {
          # Can fix lower resolution in boot screen during initramfs phase
          initrd.enable = true;
          # Overclocking
          overdrive.enable = true;
          # OpenCL support using ROCM runtime library
          opencl.enable = true;
        };
      };

      # Enable LACT, a tool for monitoring, configuring and overclocking GPUs
      services.lact.enable = true;
    };
  };
}
