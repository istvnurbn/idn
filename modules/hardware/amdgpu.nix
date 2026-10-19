{
  den.aspects.amdgpu = {
    nixos = {
      boot = {
        kernelModules = [
          "amdgpu"
        ];
        kernelParams = [
          # Allow GPU soft-reset on ring timeout instead of full hang
          "amdgpu.gpu_recovery=1"
        ];
      };

      hardware = {
        graphics = {
          enable = true;
          # also install 32-bit drivers for 32-bit applications
          enable32Bit = true;
        };
        amdgpu = {
          # Can fix lower resolution in boot screen during initramfs phase
          initrd.enable = true;
          overdrive.enable = true;
          # OpenCL support using ROCM runtime library
          opencl.enable = true;
        };
      };

      # radv 26.1 on RDNA4: non-conformance notice is expected, not a bug
      environment.sessionVariables.MESA_VK_IGNORE_CONFORMANCE_WARNING = "1";
    };
  };
}
