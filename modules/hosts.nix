{inputs, ...}: {
  # macOS hosts
  den.hosts.aarch64-darwin.hexley.users.steve = {};

  # NixOS hosts
  den.hosts.x86_64-linux.vermilion = {
    # Built from nixpkgs-unstable (Nyx's pin), Home Manager to match. Every
    # other host stays on stable. stateVersion is unaffected (dendritic.nix).
    instantiate = inputs.nixpkgs-unstable.lib.nixosSystem;
    home-manager.module = inputs.home-manager-unstable.nixosModules.home-manager;
    users.steve = {};
    settings = {
      disko-btrfs-impermanence-main = {
        device = "/dev/disk/by-id/nvme-CT1000T710SSD8_2536530B906D";
        swapSize = "48G";
        resumeOffset = 533760;
      };
      disko-btrfs-data.device = "/dev/disk/by-id/nvme-CT2000T710SSD8_2532525EB150";
      moonshine = {
        gpu = "0000:03:00.0";
        interfaces = ["eno1"];
        panelNetworks = ["10.0.10.0/24"];
      };
    };
  };

  # NixOS-WSL hosts
  den.hosts.x86_64-linux.loophole = {
    wsl.enable = true;
    users.steve = {};
  };
}
