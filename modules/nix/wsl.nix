{inputs, ...}: {
  flake-file.inputs.nixos-wsl = {
    url = "github:nix-community/NixOS-WSL/release-26.05";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.wsl.nixos = {
    imports = [inputs.nixos-wsl.nixosModules.default];

    wsl = {
      enable = true;
      defaultUser = "steve";
      wslConf = {
        automount.root = "/mnt";
        # Do not include the Windows PATH in the PATH variable
        interop.appendWindowsPath = false;
        network.generateHosts = false;
      };
    };
  };
}
