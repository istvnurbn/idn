{
  # macOS hosts
  den.hosts.aarch64-darwin.hexley.users.steve = {};

  # NixOS hosts
  den.hosts.x86_64-linux.vermilion = {
    users.steve = {};
    settings = {
      disko-btrfs-impermanence-main = {
        device = "/dev/disk/by-id/nvme-CT1000T710SSD8_2536530B906D";
        swapSize = "48G";
        resumeOffset = 533760;
      };
      disko-btrfs-data.device = "/dev/disk/by-id/nvme-CT2000T710SSD8_2532525EB150";
      moonshine.gpu = "0000:03:00.0";
    };
  };

  # Throwaway VM for rehearsing vermilion's install (see hosts/understudy.nix).
  # Remove it, and that file, once vermilion runs encrypted.
  den.hosts.x86_64-linux.understudy = {
    users.steve = {};
    settings.disko-btrfs-impermanence-main = {
      device = "/dev/disk/by-id/virtio-understudy";
      swapSize = "4G";
    };
    settings.disko-btrfs-data.device = "/dev/disk/by-id/virtio-understudy-data";
  };

  # NixOS-WSL hosts
  den.hosts.x86_64-linux.loophole = {
    wsl.enable = true;
    users.steve = {};
  };
}
