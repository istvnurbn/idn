{inputs, ...}: {
  flake-file.inputs = {
    moonshine = {
      url = "github:hgaiser/moonshine";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  den.aspects.moonshine = {user, ...}: {
    nixos = {
      imports = [inputs.moonshine.nixosModules.default];

      services.moonshine = {
        enable = true;

        # The user whose applications you want to stream.
        user = user.name;
        # Only needed when the user's uid is not declared in your
        # configuration. Check with `id -u alice`.
        uid = 1000;

        # Opens the GameStream ports. Only do this on a LAN or VPN-facing
        # firewall. See Security in the main README.
        openFirewall = true;

        # Everything from the Configuration section of the main README goes
        # here, written as nix instead of TOML.
        settings = {
          application = [
            {
              title = "Steam Big Picture";
              command = [
                "/run/current-system/sw/bin/steam"
                "steam://open/bigpicture"
              ];
            }
          ];
          application_scanner = [
            {
              type = "steam";
              library = "$HOME/.local/share/Steam";
              command = [
                "/run/current-system/sw/bin/steam"
                "-bigpicture"
                "steam://rungameid/{game_id}"
              ];
            }
            {
              type = "heroic";
              command = [
                "/run/current-system/sw/bin/heroic"
                "--no-gui"
                "heroic://launch?appName={app_name}&runner={runner}"
              ];
            }
          ];
        };
      };
    };

    impermanence = {
      users.${user.name} = {
        directories = [
          ".local/share/moonshine"
        ];
      };
    };
  };
}
