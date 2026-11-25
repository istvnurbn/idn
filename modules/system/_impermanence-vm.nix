# For a VM of an impermanent host whose root isn't impermanence's btrfs
# layout: vermilion's vmVariant and vm-boot-chain's first boot. It turns
# off the initrd wipe and impermanence's btrfs assertion, keeping every
# other assertion, and the resume device, which the initrd would wait for
# forever on the VM's disk. Not a module of its own (leading underscore):
# import it and set impermanenceVm.enable.
{
  config,
  extendModules,
  lib,
  ...
}: {
  options.impermanenceVm = {
    enable = lib.mkEnableOption "running an impermanent host on a VM's plain root";
    # Set on the copy the assertions are read from
    unfiltered = lib.mkEnableOption "every assertion" // {internal = true;};
  };

  config = lib.mkIf config.impermanenceVm.enable {
    boot.initrd.systemd.services.wipe-file-systems.enable = false;
    boot.resumeDevice = lib.mkForce "";
    assertions = lib.mkIf (!config.impermanenceVm.unfiltered) (lib.mkForce (
      lib.filter (a: a.assertion || !lib.hasPrefix "impermanence:" a.message)
      (extendModules {modules = [{impermanenceVm.unfiltered = true;}];}).config.assertions
    ));
  };
}
