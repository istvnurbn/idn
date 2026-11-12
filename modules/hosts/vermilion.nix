{den, ...}: {
  den.aspects.vermilion = {
    includes = with den.aspects; [
      # Hardware
      firmware
      amdcpu
      amdgpu
      audio
      bluetooth
      coolercontrol
      # openlogi
      openrgb
      lact
      # Disk ids, swap size and resume offset are settings in hosts.nix
      disko-btrfs-impermanence-main
      disko-btrfs-data

      # System
      boot
      impermanence
      sops
      deploy-safety

      # Base
      nix
      chaotic
      networking
      avahi
      locale
      sudo
      openssh
      shell
      tailscale

      # Misc. shell
      devel
      media-cli

      # Desktop
      plymouth
      plasma
      fonts
      desktop-base
      firefox
      helium
      tor
      office
      flatpak
      media
      claude

      # Gaming
      gaming-base
      steam
      faugus
      # sunshine
      moonshine
    ];

    # Published to the fleet's SSH roster (see system/openssh.nix)
    ssh-keys = {
      host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIfJ4iMClvTaqIYrMZNdro5oGSLk8LYG8awsuZyez7O5";
      users.steve = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMDFAQW9uPhDsi+CiCxfwon12iT0Earea6CznTniv1Ta steve@vermilion";
    };

    nixos = {pkgs, ...}: {
      boot = {
        kernelPackages = pkgs.linuxPackages_cachyos-lto-znver4;
        kernelModules = ["ntsync"];

        initrd.availableKernelModules = [
          "nvme"
          "xhci_pci"
          "ahci"
          "usb_storage"
          "usbhid"
          "sd_mod"
          # Wired NIC, for the initrd's SSH fallback (luks-ssh-unlock)
          "igc"
        ];
      };

      # Disable printing
      services.printing.enable = false;

      # Wire gamescope through the host
      programs.gamescope.package = pkgs.gamescope_git;

      services.hardware.openrgb.motherboard = "amd";

      # GPU index/PCI address specific to this machine's hardware layout.
      # See hardware/amdgpu.nix and gaming/moonshine.nix.
      programs.gamemode.settings.gpu.gpu_device = 1;
    };
  };
}
