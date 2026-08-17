{inputs, ...}: {
  flake-file.inputs.nixos-wsl = {
    url = "github:nix-community/NixOS-WSL/release-26.05";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-compat.follows = "flake-compat";
    };
  };

  den.aspects.wsl = {user, ...}: {
    nixos = {
      imports = [inputs.nixos-wsl.nixosModules.default];

      wsl = {
        enable = true;
        defaultUser = user.name;
        wslConf = {
          automount.root = "/mnt";
          # Do not include the Windows PATH in the PATH variable
          interop.appendWindowsPath = false;
          network.generateHosts = false;
        };
      };
    };
  };
}
