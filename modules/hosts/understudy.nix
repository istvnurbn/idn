# Throwaway VM that rehearses vermilion's encrypted install: the same disk,
# boot and Secure Boot stack, none of its hardware or desktop. It runs on
# vermilion under QEMU with UEFI, Secure Boot and a software TPM. Remove it,
# with its entry in hosts.nix, once vermilion runs encrypted.
{den, ...}: {
  # The VM is reinstalled for every rehearsal, so it has no stable host key
  # to be a sops recipient. Without sops nothing sets steve's password, so
  # give it a throwaway one ("understudy") for the console. SSH password
  # login stays off (openssh.nix), so this only opens the VM's own console.
  den.aspects.understudy.nixos.users.users.steve.hashedPassword = "$y$j9T$FfT7z61vdmOBjvJSSuCPD0$0QQ351gQaQi.PUtg5nYXKTRslJ3PU.0UDtMbrYLoE1.";

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
