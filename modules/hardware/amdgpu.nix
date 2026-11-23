{
  den.aspects.amdgpu = {
    nixos = {pkgs, ...}: {
      boot = {
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

      environment = {
        systemPackages = with pkgs; [
          amdgpu_top
          nvtopPackages.amd
        ];
        sessionVariables = {
          # radv 26.1 on RDNA4: non-conformance notice is expected, not a bug
          MESA_VK_IGNORE_CONFORMANCE_WARNING = "1";
          # https://wiki.cachyos.org/configuration/gaming/#increase-maximum-shader-cache-size
          AMD_VULKAN_ICD = "RADV";
          MESA_SHADER_CACHE_MAX_SIZE = "16G";
        };
      };

      # GameMode GPU tweaks for AMD cards; inert unless gaming-base enables
      # gamemode. gpu_device (which GPU index to target) depends on the
      # host's GPU layout, so hosts set it, e.g. hosts/vermilion.nix.
      programs.gamemode.settings.gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        amd_performance_level = "high";
      };
    };
  };
}
