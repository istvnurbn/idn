# Secure Boot with lanzaboote: everything on the ESP is signed with this
# host's own keys, so the unencrypted boot partition can't be tampered with.
# With Secure Boot enforced, the TPM can then safely unlock LUKS by itself.
#
# Takes over from boot.nix's systemd-boot, so its memtest86+ and netboot.xyz
# entries disappear (they're unsigned and wouldn't boot anyway).
#
# Setting up a host:
#   1. Switch. The first boot creates the keys and stages them on the ESP.
#   2. In the firmware: enable Secure Boot and reset it to Setup Mode (keep
#      the dbx), then reboot. systemd-boot enrolls the keys and reboots;
#      `bootctl status` then says "Secure Boot: enabled (user)".
#   3. Seal the LUKS key to the Secure Boot state and to an empty PCR 15.
#      Add --tpm2-with-pin=yes to also ask for a PIN at boot:
#        sudo systemd-cryptenroll /dev/disk/by-partlabel/disk-main-root \
#          --tpm2-device=auto \
#          --tpm2-pcrs=7+15:sha256=0000000000000000000000000000000000000000000000000000000000000000
#   A dbx or firmware update changes PCR 7: type the passphrase once, then
#   repeat step 3 with --wipe-slot=tpm2.
{
  den,
  inputs,
  ...
}: {
  flake-file.inputs.lanzaboote = {
    url = "github:nix-community/lanzaboote/v1.2.0";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      # Only used for lanzaboote's own development
      pre-commit.follows = "";
      rust-overlay.follows = "rust-overlay";
    };
  };

  den.aspects.secure-boot = {
    nixos = {
      host,
      lib,
      pkgs,
      ...
    }: {
      imports = [inputs.lanzaboote.nixosModules.lanzaboote];

      # lanzaboote installs and signs its own systemd-boot
      boot.loader.systemd-boot.enable = lib.mkForce false;

      boot.lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
        # Keys are created on first boot; until then it installs unsigned
        autoGenerateKeys.enable = true;
        # systemd-boot enrolls them in Setup Mode; Microsoft keys included
        # by default (GPU option ROMs need them)
        autoEnrollKeys.enable = true;
      };

      # Try the TPM first, then measure the volume key into PCR 15. Sealing
      # to an empty PCR 15 stops a swapped-in look-alike partition from
      # getting the real key out of the TPM. Name from disko.nix.
      boot.initrd.luks.devices = lib.mkIf (host.hasAspect den.aspects.luks) {
        crypted.crypttabExtraOpts = ["tpm2-device=auto" "tpm2-measure-pcr=yes"];
      };

      environment.systemPackages = [pkgs.sbctl];
    };

    # Lose these and the next boot makes new, unenrolled keys
    persist.directories = [
      {
        directory = "/var/lib/sbctl";
        mode = "0700";
      }
    ];
  };
}
