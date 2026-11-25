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
      openlogi
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

      # nixos-rebuild build-vm / .#…vermilion.config.system.build.vm logs in
      # as steve on tty1; only the VM gets it (virtualisation.vmVariant)
      (den.batteries.vm-autologin "steve")
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

      # Wire gamescope through the host
      programs.gamescope.package = pkgs.gamescope_git;

      services.hardware.openrgb.motherboard = "amd";

      # GPU index/PCI address specific to this machine's hardware layout.
      # See hardware/amdgpu.nix and gaming/moonshine.nix.
      programs.gamemode.settings.gpu.gpu_device = 1;

      # Only the VM (nixos-rebuild build-vm, …config.system.build.vm) gets
      # these. Its root is a fresh ext4 image, which impermanence's wipe and
      # its btrfs check refuse, so it drops those two and keeps every other
      # assertion.
      virtualisation.vmVariant = {
        config,
        extendModules,
        lib,
        ...
      }: {
        # Set on the copy the assertions are read from
        options.vmVariantUnfiltered = lib.mkEnableOption "every assertion" // {internal = true;};
        config = {
          virtualisation = {
            memorySize = 8192;
            cores = 4;
          };
          boot.initrd.systemd.services.wipe-file-systems.enable = false;
          assertions = lib.mkIf (!config.vmVariantUnfiltered) (lib.mkForce (
            lib.filter (a: a.assertion || !lib.hasPrefix "impermanence:" a.message)
            (extendModules {modules = [{vmVariantUnfiltered = true;}];}).config.assertions
          ));
        };
      };
    };
  };
}
