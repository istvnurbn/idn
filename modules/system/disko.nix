{
  den,
  inputs,
  lib,
  ...
}: let
  persistPath = import ./_persist-path.nix {inherit den;};
in {
  flake-file.inputs = {
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Default boot drive with impermanence-friendly layout.
  # Its values are aspect settings, set per host in hosts.nix.
  den.aspects.disko-btrfs-impermanence-main = {
    settings = {
      device = lib.mkOption {
        type = lib.types.str;
        example = "/dev/disk/by-id/nvme-...";
        description = "Boot disk, as a /dev/disk/by-id path";
      };
      swapSize = lib.mkOption {
        type = lib.types.str;
        example = "48G";
        description = "Size of /swap/swapfile; at least the RAM size to hibernate";
      };
      resumeOffset = lib.mkOption {
        type = lib.types.nullOr lib.types.ints.unsigned;
        default = null;
        description = ''
          resume_offset of /swap/swapfile, which enables hibernation. Read it
          after install: sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
        '';
      };
    };
    nixos = {
      host,
      lib,
      ...
    }: let
      cfg = host.settings.disko-btrfs-impermanence-main;

      # With the `luks` aspect on the host, the btrfs root sits inside LUKS2.
      # The partition keeps its name, so it stays /dev/disk/by-partlabel/disk-main-root.
      encrypted = host.hasAspect den.aspects.luks;
      maybeLuks = content:
        if encrypted
        then {
          type = "luks";
          # Opens as /dev/mapper/crypted
          name = "crypted";
          # Pass TRIM through to the SSD; only reveals which blocks are unused
          settings.allowDiscards = true;
          inherit content;
        }
        else content;
    in {
      imports = [inputs.disko.nixosModules.disko];

      disko.devices.disk.main = {
        inherit (cfg) device;
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
              content = maybeLuks {
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
                  # To hibernate, set the resumeOffset setting after install
                  "/swap" = {
                    mountpoint = "/swap";
                    swap.swapfile.size = cfg.swapSize;
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

      # Hibernate into the swapfile once its offset is known
      boot = lib.mkIf (cfg.resumeOffset != null) {
        # The device btrfs is on: the opened LUKS volume when encrypted
        resumeDevice =
          if encrypted
          then "/dev/mapper/crypted"
          else "/dev/disk/by-partlabel/disk-main-root";
        kernelParams = ["resume_offset=${toString cfg.resumeOffset}"];
      };
    };
  };

  # Data disk with whole drive btrfs
  den.aspects.disko-btrfs-data = {
    settings.device = lib.mkOption {
      type = lib.types.str;
      example = "/dev/disk/by-id/nvme-...";
      description = "Data disk, as a /dev/disk/by-id path";
    };

    nixos = {
      host,
      lib,
      ...
    }: let
      # With the `luks` aspect on the host, this disk is encrypted too. It opens
      # in stage 2 with a keyfile on the encrypted root, so whatever unlocked
      # root (TPM, console or SSH) unlocks it as well, without a second prompt.
      encrypted = host.hasAspect den.aspects.luks;
      keyFile = persistPath host "/etc/secrets/data.key";
      maybeLuks = content:
        if encrypted
        then {
          type = "luks";
          # Opens as /dev/mapper/data, from /etc/crypttab below
          name = "data";
          initrdUnlock = false;
          inherit content;
        }
        else content;
    in {
      imports = [inputs.disko.nixosModules.disko];

      disko.devices.disk.data = {
        inherit (host.settings.disko-btrfs-data) device;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            data = {
              size = "100%";
              content = maybeLuks {
                type = "btrfs";
                extraArgs = [
                  "-L"
                  "data"
                  "-f"
                ];
                mountpoint = "/mnt/data";
                mountOptions =
                  [
                    "compress=zstd"
                    "noatime"
                  ]
                  # A missing key or disk shouldn't stop the boot
                  ++ lib.optional encrypted "nofail";
              };
            };
          };
        };
      };

      # The keyfile is made once, at install time (see the primer's README)
      environment.etc.crypttab = lib.mkIf encrypted {
        text = ''
          data /dev/disk/by-partlabel/disk-data-data ${keyFile} luks,discard,nofail
        '';
      };
    };
  };
}
