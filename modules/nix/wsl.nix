{
  flake-file.inputs.nixos-wsl = {
    url = "github:nix-community/NixOS-WSL/release-26.05";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-compat.follows = "flake-compat";
    };
  };

  # den's wsl battery imports NixOS-WSL and enables it for hosts with wsl.enable (hosts.nix); primary-user sets defaultUser.
  # The `wsl` class lands in the host's wsl.* options.
  den.aspects.wsl.wsl.wslConf = {
    automount.root = "/mnt";
    # Do not include the Windows PATH in the PATH variable
    interop.appendWindowsPath = false;
    network.generateHosts = false;
  };
}
