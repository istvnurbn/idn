{ inputs, ... }: {
  flake-file.inputs = {
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
  };

  den.aspects.cachyos-kernel = {
    nixos = { pkgs, ... }: {
      # Enabling CachyOS kernel overlay
      nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];

      # Setting the kernel package
      boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-zen4;

      boot.kernelModules = [ "ntsync" ];

      # Binary cache for CachyOS kernel
      nix.settings.substituters = [
        "https://attic.xuyh0120.win/lantian"
        "https://cache.garnix.io"
      ];
      nix.settings.trusted-public-keys = [
        "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
    };
  };
}
