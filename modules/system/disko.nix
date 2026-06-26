{
  den,
  inputs,
  ...
}: {
  flake-file.inputs = {
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Default boot drive with impermanence-friendly layout
  # Parametric provider - takes device path and swap size as an argument
  den.provides.disko-btrfs-impermanence-main = device: swapSize: {
    nixos = {
      host,
      lib,
      ...
    }: {
      imports = [inputs.disko.nixosModules.disko];

      disko.devices.disk.main = {
        inherit device;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };

            root = {
              priority = 2;
              size = "100%";
              content = {
                type = "btrfs";
                # force-overwrite any existing fs and setting nixos as label
                extraArgs = [
                  "-L"
                  "nixos"
                  "-f"
                ];
                subvolumes = {
                  # ephemeral root — wiped every boot by the initrd service
                  "/root" = {
                    mountpoint = "/";
                    mountOptions = [
                      "subvol=root"
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "subvol=nix"
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "/persist" = lib.mkIf (host.hasAspect den.aspects.impermanence) {
                    mountpoint = "/persist";
                    mountOptions = [
                      "subvol=persist"
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  # If you hibernate, add two bits manually after install:
                  #
                  # boot.resumeDevice = "/dev/disk/by-partlabel/disk-main-root";
                  # boot.kernelParams = [ "resume_offset=<N>" ];
                  #
                  # <N> comes from
                  # sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
                  "/swap" = {
                    mountpoint = "/swap";
                    swap.swapfile.size = swapSize; # >= RAM if you hibernate
                  };
                };
              };
            };
          };
        };
      };

      fileSystems."/persist" =
        lib.mkIf (host.hasAspect den.aspects.impermanence)
        {
          neededForBoot = true;
        };
    };
  };
}
