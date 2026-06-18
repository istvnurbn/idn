# Usage in your configuration.nix:
# Update devices to match your hardware.
#
# ls -l /dev/disk/by-id
#
# {
#  imports = [ ./disko-config.nix ];
#  disko.devices.disk.main.device = "/dev/disk/by-id/YOUR_ID_HERE";
# }
#
# In case of an install, expose the device in this file.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-CT1000T710SSD8_2536530B906D";
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
            mountOptions = [ "umask=0077" ];
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
              "/persist" = {
                mountpoint = "/persist";
                mountOptions = [
                  "subvol=persist"
                  "compress=zstd"
                  "noatime"
                ];
              };
              # swapfile subvolume — must NOT be compressed; disko sets NOCOW on
              # the file. Lives on its own subvolume so it survives the root wipe
              #
              # If you hibernate, add two bits manually after install:
              #
              # boot.resumeDevice = "/dev/disk/by-partlabel/disk-main-root";
              # boot.kernelParams = [ "resume_offset=<N>" ];
              #
              # <N> comes from
              # sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
              "/swap" = {
                mountpoint = "/swap";
                swap.swapfile.size = "48G"; # >= RAM if you hibernate
              };
            };
          };
        };
      };
    };
  };
}
