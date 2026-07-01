{den, ...}: {
  den.aspects.base.includes = with den.aspects; [
    nix
    overlays
    networking
    locale
    sudo
    openssh
    shell
  ];
}
