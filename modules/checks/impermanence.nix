# Impermanence VM test: the repo's impermanence aspect on a real btrfs disk,
# rebooted once. It asserts that
#   - / is the `root` btrfs subvolume and /persist is mounted,
#   - a file written to / is gone after the reboot, and the old root holding
#     it sits under old_roots/ (the initrd wipe moved it),
#   - a persisted directory and a persisted single file kept their content,
#   - /etc/machine-id, which the aspect itself persists, is unchanged,
#   - in steve's home (persistHome, through home-manager) a persisted
#     directory, a persisted single file and ~/.ssh kept their content,
#     ~/.ssh is still 0700, steve still owns them, and a file nothing
#     persists is gone.
#
#   nix build .#checks.x86_64-linux.vm-impermanence -L
#   nix run .#checks.x86_64-linux.vm-impermanence.driverInteractive
#
# The disk is a btrfs image with empty `root` and `persist` subvolumes, made at
# build time without a VM. It stands in for disko's layout: only what the
# aspect needs, no ESP, swap or LUKS. The VM boots its kernel directly.
{
  den,
  inputs,
  lib,
  ...
}: let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  vmTest = import ./_vm-test.nix {inherit inputs lib;};

  # mkfs.btrfs --subvol turns these directories of the (empty) root dir into
  # subvolumes. It runs as root in a user namespace, so they belong to root
  # like on a disko-made disk and not to the build user. qcow2, so QEMU
  # doesn't have to guess the format.
  disk =
    pkgs.runCommand "vm-impermanence-disk.qcow2" {
      nativeBuildInputs = [pkgs.btrfs-progs pkgs.qemu-utils pkgs.util-linux];
    } ''
      mkdir -p rootdir/root rootdir/persist
      truncate -s 1G disk.raw
      unshare --map-root-user mkfs.btrfs -q -L nixos --rootdir rootdir --subvol root --subvol persist disk.raw
      qemu-img convert -f raw -O qcow2 disk.raw $out
    '';

  # The start script uses this file if it exists and only creates an empty
  # disk otherwise. It's relative to the machine's state directory, which
  # survives shutdown() and start(), so the reboot keeps the disk.
  diskName = "vm-impermanence.qcow2";

  btrfsDisk = {
    virtualisation.diskImage = "./${diskName}";
    virtualisation.useDefaultFilesystems = false;
    virtualisation.fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "btrfs";
        options = ["subvol=root"];
      };
      "/persist" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "btrfs";
        options = ["subvol=persist"];
        neededForBoot = true;
      };
    };
  };
in {
  den.hosts.x86_64-linux.vm-impermanence = vmTest {
    # A real user, so persistHome reaches home-manager the way it does on vermilion
    users.steve = {};
    extraModules = [btrfsDisk];

    testScript = ''
      import os
      import shutil

      image = machine.state_dir / "${diskName}"
      shutil.copy("${disk}", image)
      os.chmod(image, 0o644)

      machine.start()
      machine.wait_for_unit("multi-user.target")
      machine.wait_for_unit("home-manager-steve.service")

      with subtest("/ is the btrfs root subvolume and /persist is mounted"):
          fstype, options = machine.succeed("findmnt -no FSTYPE,OPTIONS /").split()
          assert fstype == "btrfs", fstype
          assert "subvol=/root" in options.split(","), options
          machine.succeed("findmnt /persist")

      machine.succeed("echo root > /marker-root")
      machine.succeed("echo dir > /var/lib/vm-impermanence/marker")
      machine.succeed("echo file > /etc/vm-impermanence-marker")
      machine_id = machine.succeed("cat /etc/machine-id")

      # Written as steve, so ownership and modes are tested too. mkdir -p makes
      # a broken persistHome fail in the subtests below instead of here.
      home_files = {
          "vm-impermanence/marker": "dir",  # persisted directory (aspect below)
          ".vm-impermanence-marker": "file",  # persisted single file (aspect below)
          ".ssh/marker": "ssh",  # persisted, mode 0700, by the impermanence aspect
      }
      for path, text in {**home_files, "not-persisted": "gone"}.items():
          machine.succeed(f"runuser -u steve -- sh -c 'mkdir -p $(dirname /home/steve/{path}) && echo {text} > /home/steve/{path}'")

      machine.shutdown()
      machine.start()
      machine.wait_for_unit("multi-user.target")
      machine.wait_for_unit("home-manager-steve.service")

      with subtest("a file on / is gone after the reboot"):
          machine.fail("test -e /marker-root")

      with subtest("the wipe moved the old root under old_roots/"):
          machine.succeed("mkdir /btrfs && mount -o subvolid=5 /dev/disk/by-label/nixos /btrfs")
          machine.succeed("grep -qx root /btrfs/old_roots/*/marker-root")
          machine.succeed("umount /btrfs")

      with subtest("a persisted directory survives"):
          assert machine.succeed("cat /var/lib/vm-impermanence/marker").strip() == "dir"

      with subtest("a persisted single file survives"):
          assert machine.succeed("cat /etc/vm-impermanence-marker").strip() == "file"

      with subtest("/etc/machine-id is unchanged"):
          assert machine.succeed("cat /etc/machine-id") == machine_id

      with subtest("persistHome: home paths survive, ~/.ssh is still 0700"):
          for path, text in home_files.items():
              assert machine.succeed(f"cat /home/steve/{path}").strip() == text, path
          assert machine.succeed("stat -c %a /home/steve/.ssh").strip() == "700"

      with subtest("persistHome: steve still owns his home and the persisted paths"):
          owners = machine.succeed(
              "stat -c %U /home/steve /home/steve/.ssh /home/steve/vm-impermanence /home/steve/.vm-impermanence-marker"
          ).split()
          assert set(owners) == {"steve"}, owners

      with subtest("persistHome: the rest of the home is gone"):
          machine.fail("test -e /home/steve/not-persisted")
    '';
  };

  den.aspects.vm-impermanence = {
    includes = [den.aspects.impermanence];

    # Check-only entries, through the same settings every aspect uses
    persist = {
      directories = ["/var/lib/vm-impermanence"];
      files = ["/etc/vm-impermanence-marker"];
    };
    persistHome = {
      directories = ["vm-impermanence"];
      files = [".vm-impermanence-marker"];
    };
  };
}
