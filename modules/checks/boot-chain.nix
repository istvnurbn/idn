# Boot-chain VM test: the desktop stack's encrypted boot, end to end, on
# UEFI with Secure Boot and a software TPM. It asserts that
#   - the machine boots through lanzaboote with Secure Boot on, after
#     systemd-boot enrolled the keys the secure-boot aspect made,
#   - the console passphrase prompt reads the hu keymap,
#   - a client unlocks root over initrd SSH on port 2222,
#   - with the TPM enrolled (PCR 7 + an empty PCR 15), root unlocks by itself,
#   - the data disk opens after root, through its keyfile on the encrypted root,
#   - every home-manager-<user>.service comes up in the encrypted boot,
#   - it hibernates to the swapfile and resumes from the encrypted root.
# The machine is impermanent like vermilion, so the keys sit at their real
# paths under /persist.
#
#   nix build .#checks.x86_64-linux.vm-boot-chain -L
#   nix run .#checks.x86_64-linux.vm-boot-chain.driverInteractive
#
# Like nixpkgs' LUKS tests, the first boot is a plain system on vda that lays
# out the two empty disks under the partition labels and subvolumes the layout
# aspects use, then links the `encrypted` specialisation in as generation 2,
# which boots from them. disko formats nothing here and qemu-vm replaces its
# file systems; proving the layouts is the install-* checks' job.
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

  # The script makes the swapfile on a fresh filesystem the same way every
  # time, so its resume offset is pinned here and checked by the test, as
  # NC-01 re-reads it on vermilion
  resumeOffset = 61440;

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
        useSecureBoot = true;
        # Secure Boot, and the TPM support that measures it into PCR 7:
        # qemu-vm.nix's default OVMF has neither
        efi.OVMF = pkgs.OVMFFull.fd;
        tpm.enable = true;
        # The encrypted root starts empty, so the store comes from an image
        # disk. Unlike the host store over 9p, its virtio-blk device survives
        # a hibernation. Writable, for home-manager.
        useNixStoreImage = true;
        writableStore = true;
        # The store's writable layer lives on the encrypted /nix, next to the
        # Nix database boot 1 hands over, not on a tmpfs lost at reboot
        writableStoreUseTmpfs = !config.bootChain.encrypted;
        memorySize = 2048;
        emptyDiskImages = [
          {
            size = 2048;
            driveConfig.deviceExtraOpts.serial = "main";
          }
          {
            size = 512;
            driveConfig.deviceExtraOpts.serial = "data";
          }
        ];

        # With the default file systems qemu-vm.nix also drops the aspects'
        # boot.initrd.luks.devices. It replaces disko's file systems either
        # way, so the encrypted boot mounts the script's subvolumes here. The
        # ESP stays on vda, and /nix/store comes from the store image.
        useDefaultFilesystems = !config.bootChain.encrypted;
        fileSystems = let
          subvol = name: {
            device = "/dev/mapper/crypted";
            fsType = "btrfs";
            options = ["subvol=${name}"];
          };
        in
          lib.mkIf config.bootChain.encrypted {
            "/" = subvol "root";
            "/persist" = subvol "persist" // {neededForBoot = true;};
            "/nix" = subvol "nix";
            "/swap" = subvol "swap";
            "/mnt/data" = {
              device = "/dev/mapper/data";
              fsType = "btrfs";
              options = ["nofail"];
            };
          };
      };
      # Boot 1 runs from vda's ext4 image with no LUKS devices: no wipe, no
      # btrfs assertion, no resume device. The encrypted boot keeps all three.
      impermanence.vmRoot = !config.bootChain.encrypted;
      # Boot 1 has no data keyfile, so systemd-cryptsetup@data can ask for a
      # passphrase on the console. That agent takes over the serial device the
      # test backdoor writes stderr to, and later writes fail with EIO
      # (test-instrumentation.nix keeps getty off it for the same reason)
      systemd.services.systemd-ask-password-console.enable = config.bootChain.encrypted;

      specialisation.encrypted.configuration.bootChain.encrypted = true;

      environment.systemPackages = with pkgs; [btrfs-progs cryptsetup gptfdisk];

      # The test driver talks to the VM through its backdoor service, which a
      # hibernation cuts; nixpkgs' hibernate test restarts it the same way
      powerManagement.powerDownCommands = "systemctl --no-block stop backdoor.service";
      powerManagement.resumeCommands = "systemctl --no-block restart backdoor.service";

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

        # Lay out the disks under the layout aspects' partition labels and
        # subvolumes. The data key lives on the encrypted root's /persist, at
        # the path the disko-btrfs-data aspect expects.
        machine.succeed(
            "sgdisk -n1:0:0 -c1:disk-main-root /dev/disk/by-id/virtio-main",
            "sgdisk -n1:0:0 -c1:disk-data-data /dev/disk/by-id/virtio-data",
            "udevadm settle",
            f"echo -n ${passphrase} | cryptsetup luksFormat -q --iter-time=1 {root} -",
            f"echo -n ${passphrase} | cryptsetup open --key-file=- {root} crypted",
            "mkfs.btrfs -q -L nixos /dev/mapper/crypted",
            "mount --mkdir /dev/mapper/crypted /mnt",
            "btrfs subvolume create /mnt/root /mnt/persist /mnt/nix /mnt/swap",
            # disko makes the swapfile it declares when it formats
            "btrfs filesystem mkswapfile --size 1g /mnt/swap/swapfile",
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
            # Boot the encrypted config next, as nixos-rebuild boot would. lzbt
            # installs the system-*-link generations.
            machine.succeed(
                "test -L /nix/var/nix/profiles/system-1-link",
                "ln -sn $(readlink -f /run/current-system/specialisation/encrypted) /nix/var/nix/profiles/system-2-link",
                "ln -sfn system-2-link /nix/var/nix/profiles/system",
                "/nix/var/nix/profiles/system/bin/switch-to-configuration boot 2>&1",
            )
            # The encrypted root's own /nix, with boot 1's Nix database and the
            # paths it built, as an install leaves it
            machine.succeed(
                "cp -a /nix/var /mnt/nix/",
                "mkdir /mnt/nix/.rw-store && cp -a /nix/.rw-store/upper /mnt/nix/.rw-store/",
                "umount /mnt",
                "cryptsetup close crypted",
            )
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

        with subtest("the encrypted boot is healthy"):
            for user in ${builtins.toJSON (lib.attrNames nodes.machine.home-manager.users)}:
                machine.wait_for_unit(f"home-manager-{user}.service")

        with subtest("it hibernates to the swapfile and resumes from the encrypted root"):
            offset = machine.succeed("btrfs inspect-internal map-swapfile -r /swap/swapfile").strip()
            assert offset == "${toString resumeOffset}", f"the swapfile's resume offset is {offset}: set resumeOffset to it"
            boot_id = machine.succeed("cat /proc/sys/kernel/random/boot_id")
            # logind refuses without a usable resume device; fail here, not in a
            # wait for a shutdown that never comes
            machine.succeed("busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanHibernate | grep -qx 's \"yes\"'")
            # A fresh boot would wipe it; a resume never runs the initrd's wipe
            machine.succeed("echo resumed > /marker-hibernate")
            machine.execute("systemctl hibernate >&2 &", check_return=False)
            machine.wait_for_shutdown()
            # The TPM unlocks root, then the initrd resumes from the swapfile on it
            machine.start()
            assert machine.succeed("cat /proc/sys/kernel/random/boot_id") == boot_id, "booted fresh instead of resuming"
            assert machine.succeed("cat /marker-hibernate").strip() == "resumed"
      '';
    })
    {
      # The layout aspects' whole-disk paths; disko never formats them here
      settings = {
        disko-btrfs-impermanence-main = {
          device = "/dev/disk/by-id/virtio-main";
          swapSize = "1G";
          inherit resumeOffset;
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
