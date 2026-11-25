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
in {
  den.hosts.x86_64-linux = {
    # vermilion's root: btrfs subvolumes, / wiped at every boot
    install-impermanence-root = lib.mkMerge [
      (installTest {users.steve = {};})
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
    install-impermanence-root.includes = with den.aspects; [boot impermanence disko-btrfs-impermanence-main];
    install-impermanence-root-luks.includes = with den.aspects; [boot impermanence luks];
    install-data.includes = with den.aspects; [boot disko-btrfs-impermanence-main disko-btrfs-data];
  };
}
