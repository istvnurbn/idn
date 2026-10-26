{
  den.aspects.qemu-guest.nixos = {modulesPath, ...}: {
    imports = [(modulesPath + "/profiles/qemu-guest.nix")];
  };
}
