{inputs, ...}: {
  flake-file.inputs.dtop = {
    url = "github:amir20/dtop";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
    inputs.flake-utils.follows = "flake-utils";
  };

  den.aspects.docker = {
    nixos = {pkgs, ...}: {
      # Enable Docker
      # # Add your user to the docker group
      virtualisation.docker = {
        enable = true;
        storageDriver = "btrfs";
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
      };

      # dtop to monitor docker
      environment.systemPackages = with inputs.dtop.packages.${pkgs.stdenv.hostPlatform.system}; [default];
    };

    impermanence = {
      directories = [
        "/var/lib/docker"
      ];
    };
  };
}
