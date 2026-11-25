# Install tests for the real disk layouts (modules/system/disko.nix): disko
# formats each layout on empty disks, the host is installed onto them and
# booted, and _install-test.nix checks the mounts against the layout's own
# disko declaration. disko's test VM has plain OVMF, read-only EFI variables
# and no TPM, so Secure Boot and TPM unlock are vm-boot-chain's job.
#
#   nix build .#checks.x86_64-linux.install-impermanence-root -L
{
  den,
  inputs,
  lib,
  ...
}: let
  installTest = import ./_install-test.nix {inherit inputs lib;};

  # disko's test swaps in its own disks, so the path is a placeholder
  root = {
    disko-btrfs-impermanence-main = {
      device = "/dev/vda";
      swapSize = "256M";
    };
  };
  data.disko-btrfs-data.device = "/dev/vdb";

  # disko's test mounts the host store read-only over 9p and leaves the
  # installed Nix database empty, where nixos-install leaves both usable.
  # Home Manager's activation installs into the store, so this lays a
  # writable layer on the installed /nix and registers Home Manager's
  # closure (the toplevel is disko's extended one), then runs the activation
  # again.
  nixosInstallStore = {
    config,
    lib,
    pkgs,
    ...
  }: {
    fileSystems."/nix/.ro-store" = {
      device = "nix-store";
      fsType = "9p";
      neededForBoot = true;
      options = ["trans=virtio" "version=9p2000.L" "cache=loose"];
    };
    # Over the mkForce in disko's installTest
    fileSystems."/nix/store" = lib.mkOverride 40 {
      overlay = {
        lowerdir = ["/nix/.ro-store"];
        upperdir = "/nix/.rw-store/upper";
        workdir = "/nix/.rw-store/work";
      };
    };
    disko.tests.extraChecks = lib.mkBefore ''
      machine.succeed(
          "nix-store --load-db < ${pkgs.closureInfo {rootPaths = map (home: home.home.activationPackage) (lib.attrValues config.home-manager.users);}}/registration",
          "systemctl restart home-manager-steve.service",
      )
    '';
  };
in {
  den.hosts.x86_64-linux = {
    # vermilion's root: btrfs subvolumes, / wiped at every boot. After the
    # layout checks it writes files, reboots and checks what the wipe
    # removed and what /persist kept, in / and in steve's home.
    install-impermanence-root = lib.mkMerge [
      (installTest {
        # A real user, so persistHome reaches home-manager the way it does on vermilion
        users.steve = {};
        extraModules = [nixosInstallStore];
        extraChecks = ''
          machine.wait_for_unit("multi-user.target")
          machine.wait_for_unit("home-manager-steve.service")

          machine.succeed("echo root > /marker-root")
          machine.succeed("echo dir > /var/lib/install-impermanence/marker")
          machine.succeed("echo file > /etc/install-impermanence-marker")
          machine.succeed("echo log > /var/log/install-impermanence-marker")
          machine_id = machine.succeed("cat /etc/machine-id")

          # Written as steve, so ownership and modes are tested too. mkdir -p makes
          # a broken persistHome fail in the subtests below instead of here.
          home_files = {
              "install-impermanence/marker": "dir",  # persisted directory (aspect below)
              ".install-impermanence-marker": "file",  # persisted single file (aspect below)
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
              machine.succeed("mkdir /btrfs && mount -o subvolid=5 /dev/disk/by-partlabel/disk-main-root /btrfs")
              machine.succeed("grep -qx root /btrfs/old_roots/*/marker-root")
              machine.succeed("umount /btrfs")

          with subtest("a persisted directory survives"):
              assert machine.succeed("cat /var/lib/install-impermanence/marker").strip() == "dir"

          with subtest("a persisted single file survives"):
              assert machine.succeed("cat /etc/install-impermanence-marker").strip() == "file"

          with subtest("/etc/machine-id is unchanged"):
              assert machine.succeed("cat /etc/machine-id") == machine_id

          with subtest("/var/log survives"):
              assert machine.succeed("cat /var/log/install-impermanence-marker").strip() == "log"

          with subtest("persistHome: home paths survive, ~/.ssh is still 0700"):
              for path, text in home_files.items():
                  assert machine.succeed(f"cat /home/steve/{path}").strip() == text, path
              assert machine.succeed("stat -c %a /home/steve/.ssh").strip() == "700"

          with subtest("persistHome: steve still owns his home and the persisted paths"):
              owners = machine.succeed(
                  "stat -c %U /home/steve /home/steve/.ssh /home/steve/install-impermanence /home/steve/.install-impermanence-marker"
              ).split()
              assert set(owners) == {"steve"}, owners

          with subtest("persistHome: the rest of the home is gone"):
              machine.fail("test -e /home/steve/not-persisted")
        '';
      })
      {settings = root;}
    ];

    # The same root inside LUKS2, unlocked at the console prompt
    install-impermanence-root-luks = lib.mkMerge [
      (installTest {
        users.steve = {};
        # disko's test writes this passphrase to /tmp/secret.key for formatting
        extraModules = [{disko.devices.disk.main.content.partitions.root.content.passwordFile = "/tmp/secret.key";}];
        bootCommands = ''
          retry(lambda _: "Please enter passphrase for disk" in machine.get_console_log(), 300)
          machine.send_console("secretsecret\n")
        '';
        extraChecks = ''
          machine.succeed("cryptsetup isLuks /dev/disk/by-partlabel/disk-main-root")
        '';
      })
      {settings = root;}
    ];

    # The whole-disk data btrfs next to a plain root
    install-data = lib.mkMerge [
      (installTest {users.steve = {};})
      {settings = root // data;}
    ];
  };

  den.aspects = {
    install-impermanence-root = {
      includes = with den.aspects; [boot impermanence disko-btrfs-impermanence-main];
      # Check-only entries, through the same settings every aspect uses
      persist = {
        directories = ["/var/lib/install-impermanence"];
        files = ["/etc/install-impermanence-marker"];
      };
      persistHome = {
        directories = ["install-impermanence"];
        files = [".install-impermanence-marker"];
      };
    };
    install-impermanence-root-luks.includes = with den.aspects; [boot impermanence luks];
    install-data.includes = with den.aspects; [boot disko-btrfs-impermanence-main disko-btrfs-data];
  };
}
