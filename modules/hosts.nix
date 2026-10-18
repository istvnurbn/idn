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
    };
  };

  # NixOS-WSL hosts
  den.hosts.x86_64-linux.loophole = {
    wsl.enable = true;
    users.steve = {};
  };
}
