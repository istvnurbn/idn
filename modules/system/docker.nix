{inputs, ...}: {
  flake-file.inputs.dtop = {
    url = "github:amir20/dtop";
  };

  den.aspects.docker = {
    nixos = {pkgs, ...}: {
      # Enable Docker
      virtualisation.docker = {
        enable = true;
        storageDriver = "btrfs";
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
      };

      # Adding my user to the Docker group
      users.extraGroups.docker.members = ["steve"];

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
