# For a VM of an impermanent host whose root isn't impermanence's btrfs
# layout: vermilion's vmVariant and vm-boot-chain's first boot. The
# impermanence aspect then skips its wipe and btrfs check, and the resume
# device goes, since the initrd would wait for it forever on the VM's disk.
# Not a module of its own (leading underscore): import it and set
# impermanenceVm.enable.
{
  config,
  lib,
  ...
}: {
  options.impermanenceVm.enable = lib.mkEnableOption "running an impermanent host on a VM's plain root";

  config = lib.mkIf config.impermanenceVm.enable {
    impermanence.vmRoot = true;
    boot.resumeDevice = lib.mkForce "";
  };
}
