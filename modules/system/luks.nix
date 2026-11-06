# Full disk encryption, for machines with someone at the keyboard. On a
# host's list, this puts the btrfs root of den.aspects.disko-btrfs-impermanence-main
# inside LUKS2 (/dev/mapper/crypted). Servers and other headless hosts stay
# unencrypted.
#
# The ESP stays unencrypted because the firmware has to read it. Instead of
# hiding it, secure-boot.nix makes it tamper-proof, and with secure-boot on
# the host this aspect lets the TPM unlock the disk. Without secure-boot,
# every boot asks for the passphrase on the console; luks-ssh-unlock adds an
# SSH fallback for that prompt.
#
# Changing the layout needs a reformat (or an offline cryptsetup reencrypt).
# After install, add a recovery key and keep it off the machine:
#   sudo systemd-cryptenroll --recovery-key /dev/disk/by-partlabel/disk-main-root
{den, ...}: {
  # disko.nix also checks for this aspect with host.hasAspect to wrap the root
  # in LUKS. systemd-cryptsetup in stage 1 is what reads TPM2 tokens; systemd
  # in the initrd is the default since 26.05, so it needs no setting here.
  den.aspects.luks.nixos = {
    host,
    lib,
    ...
  }: {
    # Under Secure Boot, try the TPM first, then measure the volume key into
    # PCR 15. Sealing to an empty PCR 15 stops a swapped-in look-alike
    # partition from getting the real key out of the TPM. Name from disko.nix.
    boot.initrd.luks.devices = lib.mkIf (host.hasAspect den.aspects.secure-boot) {
      crypted.crypttabExtraOpts = ["tpm2-device=auto" "tpm2-measure-pcr=yes"];
    };
  };
}
