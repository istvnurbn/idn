# Secure Boot with lanzaboote: everything on the ESP is signed with this
# host's own keys, so the unencrypted boot partition can't be tampered with.
# With Secure Boot enforced, the TPM can then safely unlock LUKS by itself
# (luks.nix sets that up).
#
# Takes over from boot.nix's systemd-boot, so its memtest86+ and netboot.xyz
# entries disappear (they're unsigned and wouldn't boot anyway).
#
# Setting up a host (enrolling the keys, sealing the disk key to the TPM, a
# PIN, a recovery key, and what to do when the TPM refuses) is written up once,
# in idn-primer's README, "6. Encrypted: Secure Boot and the TPM":
#   https://github.com/istvnurbn/idn-primer#6-encrypted-secure-boot-and-the-tpm
{inputs, ...}: {
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

      # luks.nix turns on TPM unlock for the encrypted root when this aspect
      # is on the host

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
