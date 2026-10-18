{
  # macOS hosts
  den.hosts.aarch64-darwin.hexley.users.steve = {};

  # NixOS hosts
  den.hosts.x86_64-linux.vermilion.users.steve = {};

  # NixOS-WSL hosts
  den.hosts.x86_64-linux.loophole = {
    wsl.enable = true;
    users.steve = {};
  };
}
