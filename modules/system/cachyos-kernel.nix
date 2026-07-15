{inputs, ...}: {
  flake-file.inputs = {
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
      inputs = {
        flake-compat.follows = "flake-compat";
        flake-parts.follows = "flake-parts";
      };
    };
  };

  den.aspects.cachyos-kernel = {
    nixos = {pkgs, ...}: {
      nixpkgs.overlays = [inputs.nix-cachyos-kernel.overlays.pinned];

      boot = {
        kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-zen4;

        kernelModules = ["ntsync"];
      };

      nix.settings = {
        substituters = [
          "https://attic.xuyh0120.win/lantian"
        ];
        trusted-public-keys = [
          "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
        ];
      };
    };
  };
}
