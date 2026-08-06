{inputs, ...}: {
  flake-file.inputs = {
    moonshine = {
      url = "github:hgaiser/moonshine";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  den.aspects.moonshine = {user, ...}: {
    nixos = {
      pkgs,
      lib,
      ...
    }: let
      steamExe = "/run/current-system/sw/bin/steam";

      steamLaunchExe = lib.getExe' steamLaunch "moonshine-steam-launch";

      steamLaunch = pkgs.writeShellApplication {
        name = "moonshine-steam-launch";
        text = ''
          ${lib.getExe' steamShutdown "moonshine-steam-shutdown"}
          exec ${steamExe} "$@"
        '';
      };

      steamShutdown = pkgs.writeShellApplication {
        name = "moonshine-steam-shutdown";
        runtimeInputs = [pkgs.procps pkgs.coreutils];
        text = ''
          pgrep -x steam >/dev/null || exit 0

          ${steamExe} -shutdown >/dev/null 2>&1 || true

          for _ in {1..30}; do
            pgrep -x steam >/dev/null || exit 0
            sleep 1
          done

          echo "steam still up after 30s, sending SIGTERM" >&2
          pkill -x steam || true
        '';
      };

      heroicExe = "/run/current-system/sw/bin/heroic";

      heroicLaunch = pkgs.writeShellApplication {
        name = "moonshine-heroic-launch";
        text = ''
          ${lib.getExe' heroicShutdown "moonshine-heroic-shutdown"}
          exec ${heroicExe} "$@"
        '';
      };

      heroicShutdown = pkgs.writeShellApplication {
        name = "moonshine-heroic-shutdown";
        runtimeInputs = [pkgs.procps pkgs.coreutils];
        text = ''
          pat='^/nix/store/[^ ]*electron .*/opt/heroic/resources/app.asar'
          pgrep -f "$pat" >/dev/null || exit 0
          pkill -f "$pat" || true
          for _ in {1..30}; do
            pgrep -f "$pat" >/dev/null || exit 0
            sleep 1
          done
          echo "heroic still up after 30s, sending SIGKILL" >&2
          pkill -9 -f "$pat" || true
        '';
      };
    in {
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
                steamLaunchExe
                "steam://open/bigpicture"
              ];
            }
          ];
          application_scanner = [
            {
              type = "steam";
              library = "$HOME/.local/share/Steam";
              command = [
                steamLaunchExe
                "steam://rungameid/{game_id}"
              ];
            }
            {
              type = "heroic";
              command = [
                (lib.getExe' heroicLaunch "moonshine-heroic-launch")
                "--no-gui"
                "heroic://launch?appName={app_name}&runner={runner}"
              ];
            }
          ];
        };
      };
    };

    provides.to-users = {user, ...}: {
      nixos.users.users.${user.name}.extraGroups = ["moonshine"];
    };

    impermanence = {
      users.${user.name} = {
        directories = [
          ".config/moonshine" # certs
          ".local/share/moonshine" # paired clients
        ];
      };
    };
  };
}
