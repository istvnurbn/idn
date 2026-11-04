# Throwaway VM that rehearses vermilion's encrypted install: the same disk,
# boot and Secure Boot stack, none of its hardware or desktop. It runs on
# vermilion under QEMU with UEFI, Secure Boot and a software TPM. Remove it,
# with its entry in hosts.nix, once vermilion runs encrypted.
{den, ...}: {
  den.aspects.understudy.includes = with den.aspects; [
    qemu-guest
    # Disk ids and swap size are settings in hosts.nix
    disko-btrfs-impermanence-main
    disko-btrfs-data

    # System
    boot
    impermanence
    luks
    secure-boot
    luks-ssh-unlock
    plymouth
    deploy-safety

    # Base
    nix
    networking
    locale
    sudo
    openssh
    shell
  ];
}
