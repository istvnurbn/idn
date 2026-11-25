# Boot-chain VM test: the desktop stack's encrypted boot, end to end, on
# UEFI with Secure Boot and a software TPM. It asserts that
#   - the machine boots through lanzaboote with Secure Boot on, after
#     systemd-boot enrolled the keys the secure-boot aspect made,
#   - the console passphrase prompt reads the hu keymap,
#   - a client unlocks root over initrd SSH on port 2222,
#   - with the TPM enrolled (PCR 7 + an empty PCR 15), root unlocks by itself,
#   - the data disk opens after root, through its keyfile on the encrypted root.
# The machine is impermanent like vermilion, so the keys sit at their real
# paths under /persist.
#
#   nix build .#checks.x86_64-linux.vm-boot-chain -L
#   nix run .#checks.x86_64-linux.vm-boot-chain.driverInteractive
#
# Like nixpkgs' LUKS tests, the first boot is a plain system on vda that lays
# out the two empty disks under the partition labels disko gives them, and the
# `encrypted` specialisation then boots from them. Disko's full layouts are the
# install-* checks' job.
{
  den,
  inputs,
  lib,
  ...
}: let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  keys = import "${pkgs.path}/nixos/tests/ssh-keys.nix" pkgs;
  vmTest = import ./_vm-test.nix {inherit inputs lib;};

  # hu swaps y and z, so typing it with send_chars only works under hu
  passphrase = "yzsecret";

  # Test-only machine settings: VM hardware, the disks, and keys
  vm = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.bootChain.encrypted = lib.mkEnableOption "booting from the encrypted disks";

    config = {
      virtualisation = {
        useBootLoader = true;
        useEFIBoot = true;
        # Secure Boot, and the TPM support that measures it into PCR 7:
        # qemu-vm.nix's default OVMF has neither
        efi.OVMF = pkgs.OVMFFull.fd;
        tpm.enable = true;
        # The encrypted root starts empty, so the store comes from the host
        mountHostNixStore = true;
        memorySize = 2048;
        emptyDiskImages = [
          {
            size = 1024;
            driveConfig.deviceExtraOpts.serial = "main";
          }
          {
            size = 512;
            driveConfig.deviceExtraOpts.serial = "data";
          }
        ];

        # With the default file systems qemu-vm.nix also drops the aspects'
        # boot.initrd.luks.devices. The ESP stays on vda.
        useDefaultFilesystems = !config.bootChain.encrypted;
        fileSystems = lib.mkIf config.bootChain.encrypted {
          "/" = {
            device = "/dev/mapper/crypted";
            fsType = "btrfs";
            options = ["subvol=root"];
          };
          "/persist" = {
            device = "/dev/mapper/crypted";
            fsType = "btrfs";
            options = ["subvol=persist"];
            neededForBoot = true;
          };
          "/mnt/data" = {
            device = "/dev/mapper/data";
            fsType = "btrfs";
            options = ["nofail"];
          };
        };
      };
      # Disko's swapfile needs a subvolume this test doesn't make
      swapDevices = lib.mkIf config.bootChain.encrypted (lib.mkForce []);
      # The first boot runs from vda's ext4 image, which impermanence's wipe
      # and its btrfs check refuse. The encrypted boot keeps both.
      boot.initrd.systemd.services.wipe-file-systems.enable = config.bootChain.encrypted;
      assertions = lib.mkIf (!config.bootChain.encrypted) (lib.mkForce []);
      # The first boot formats the data disk, so it mustn't try to open it
      environment.etc.crypttab.enable = config.bootChain.encrypted;

      specialisation.encrypted.configuration.bootChain.encrypted = true;

      environment.systemPackages = with pkgs; [btrfs-progs cryptsetup gptfdisk];

      # The image is built before the VM exists, so the aspect's host key file
      # can't be its source: a snakeoil key stands in. The initrd's sshd still
      # reads it from the aspect's path.
      boot.initrd.secrets = lib.genAttrs config.boot.initrd.network.ssh.hostKeys (_: lib.mkForce keys.snakeOilEd25519PrivateKey);
      # The test network has no DHCP server
      boot.initrd.systemd.network.networks."00-test-vlan" = {
        matchConfig.Name = "eth1";
        address = ["${config.networking.primaryIPAddress}/24"];
      };

      users.users.steve.openssh.authorizedKeys.keys = [keys.snakeOilEd25519PublicKey];
    };
  };
in {
  den.hosts.x86_64-linux.vm-boot-chain = lib.mkMerge [
    (vmTest {
      users.steve = {};
      nodes.client = {};
      extraModules = [vm];

      testScript = {nodes, ...}: ''
        import re

        host = "${nodes.machine.networking.hostName}"
        ssh = "${pkgs.openssh}/bin/ssh -i /root/key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
        root = "/dev/disk/by-partlabel/disk-main-root"
        data = "/dev/disk/by-partlabel/disk-data-data"
        prompt = "Please enter passphrase for disk"
        unlocked = r"Finished .*(systemd-cryptsetup@crypted|Cryptography Setup for crypted)"

        def wait_console(regex, timeout):
            # wait_for_console_text reads one queued line a second, minutes
            # behind a booting VM. start() clears the log, so this is one boot.
            retry(lambda _: re.search(regex, machine.get_console_log()) is not None, timeout)

        def reboot():
            machine.shutdown()
            machine.start()

        start_all()
        client.succeed("install -m 600 ${keys.snakeOilEd25519PrivateKey} /root/key")
        machine.wait_for_unit("multi-user.target")

        # Lay out the disks. The data key lives on the encrypted root's /persist,
        # at the path the disko-btrfs-data aspect expects.
        machine.succeed(
            "sgdisk -n1:0:0 -c1:disk-main-root /dev/disk/by-id/virtio-main",
            "sgdisk -n1:0:0 -c1:disk-data-data /dev/disk/by-id/virtio-data",
            "udevadm settle",
            f"echo -n ${passphrase} | cryptsetup luksFormat -q --iter-time=1 {root} -",
            f"echo -n ${passphrase} | cryptsetup open --key-file=- {root} crypted",
            "mkfs.btrfs -q -L nixos /dev/mapper/crypted",
            "mount --mkdir /dev/mapper/crypted /mnt",
            "btrfs subvolume create /mnt/root /mnt/persist",
            "install -d -m 700 /mnt/persist/etc/secrets",
            "dd if=/dev/urandom of=/mnt/persist/etc/secrets/data.key bs=64 count=1",
            "chmod 400 /mnt/persist/etc/secrets/data.key",
            f"echo -n ${passphrase} | cryptsetup luksFormat -q --iter-time=1 {data} -",
            f"echo -n ${passphrase} | cryptsetup luksAddKey --key-file=- {data} /mnt/persist/etc/secrets/data.key",
            f"cryptsetup open --key-file=/mnt/persist/etc/secrets/data.key {data} data",
            "mkfs.btrfs -q -L data /dev/mapper/data",
            "cryptsetup close data",
        )

        with subtest("it boots through lanzaboote with Secure Boot on"):
            # The secure-boot aspect makes its keys on first boot, signs the ESP
            # with them and stages them for systemd-boot to enroll
            machine.wait_for_unit("prepare-sb-auto-enroll.service")
            machine.succeed("install -d /mnt/persist/var/lib && cp -a /var/lib/sbctl /mnt/persist/var/lib/")
            entry = machine.succeed("cd /boot/EFI/Linux && echo nixos-generation-1-specialisation-encrypted-*.efi").strip()
            machine.succeed(f"bootctl set-default {entry}", "umount /mnt", "cryptsetup close crypted")
            machine.shutdown()
            # systemd-boot enrolls the keys in Setup Mode, then resets the machine
            machine.start(allow_reboot=True)
            wait_console(prompt, 300)
            machine.send_console("${passphrase}\n")
            wait_console(unlocked, 120)
            machine.wait_for_unit("multi-user.target")
            status = machine.succeed("bootctl status")
            assert "Secure Boot: enabled (user)" in status, status
            machine.succeed("tr -d '\\0' < /sys/firmware/efi/efivars/StubInfo-4a67b082-0a4c-41cf-b6c7-440b29bb8c4f | grep -q lanzastub")
            assert machine.succeed("findmnt -no SOURCE /").startswith("/dev/mapper/crypted"), "not the encrypted root"

        with subtest("the console passphrase prompt reads the hu keymap"):
            reboot()
            wait_console(prompt, 300)
            machine.send_chars("${lib.replaceStrings ["y" "z"] ["z" "y"] passphrase}\n")
            wait_console(unlocked, 120)
            machine.wait_for_unit("multi-user.target")

        with subtest("a client unlocks root over initrd SSH on port 2222"):
            reboot()
            wait_console(prompt, 300)
            client.wait_for_open_port(2222, host)
            client.succeed(f"echo ${passphrase} | timeout 60 {ssh} -tt -p 2222 root@{host}")
            wait_console(unlocked, 120)
            machine.wait_for_unit("multi-user.target")

        with subtest("with the TPM enrolled, root unlocks without a passphrase"):
            # Secure Boot's state (PCR 7), and PCR 15 before the volume key is measured into it
            machine.succeed(f"PASSWORD=${passphrase} systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7+15:sha256={'0' * 64} {root}")
            reboot()
            wait_console(unlocked, 120)
            machine.wait_for_unit("multi-user.target")

        with subtest("the data disk opens after root, through its keyfile"):
            # Stage 2's unit, so the initrd didn't open it
            machine.wait_for_unit("systemd-cryptsetup@data.service", timeout=60)
            assert machine.succeed("findmnt -no SOURCE /mnt/data").strip() == "/dev/mapper/data"
            machine.succeed(
                f"cryptsetup open --test-passphrase --key-file=/persist/etc/secrets/data.key {data}",
                f"echo -n ${passphrase} | cryptsetup open --test-passphrase --key-file=- {data}",
            )
      '';
    })
    {
      settings = {
        disko-btrfs-impermanence-main = {
          device = "/dev/disk/by-id/virtio-main";
          swapSize = "1G";
        };
        disko-btrfs-data.device = "/dev/disk/by-id/virtio-data";
      };
    }
  ];

  # The desktop stack on an impermanent root, without vermilion's hardware,
  # kernel or GPU
  den.aspects.vm-boot-chain.includes = with den.aspects; [
    boot
    luks
    secure-boot
    luks-ssh-unlock
    disko-btrfs-data
    impermanence
  ];
}
