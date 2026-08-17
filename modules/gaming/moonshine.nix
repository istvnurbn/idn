{inputs, ...}: {
  flake-file.inputs = {
    moonshine = {
      url = "github:hgaiser/moonshine";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  den.aspects.moonshine = {
    user,
    host,
    ...
  }: {
    nixos = {
      pkgs,
      lib,
      ...
    }: let
      steamExe = "/run/current-system/sw/bin/steam";
      heroicExe = "/run/current-system/sw/bin/heroic";

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

      steamShutdownExe = lib.getExe' steamShutdown "moonshine-steam-shutdown";

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

      heroicShutdownExe = lib.getExe' heroicShutdown "moonshine-heroic-shutdown";

      steamLaunch = pkgs.writeShellApplication {
        name = "moonshine-steam-launch";
        text = ''
          ${steamShutdownExe}
          exec ${steamExe} "$@"
        '';
      };

      steamLaunchExe = lib.getExe' steamLaunch "moonshine-steam-launch";

      heroicLaunch = pkgs.writeShellApplication {
        name = "moonshine-heroic-launch";
        text = ''
          ${heroicShutdownExe}
          exec ${heroicExe} "$@"
        '';
      };

      heroicLaunchExe = lib.getExe' heroicLaunch "moonshine-heroic-launch";
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

        # An idle Moonlight client polls the HTTPS port every 5s, logging a
        # WARN for every dropped TLS probe.
        logFilter = "moonshine=info,moonshine_core::tls=error";

        # Everything from the Configuration section of the main README goes
        # here, written as nix instead of TOML.
        settings = {
          name = host.name;

          compositor = {
            # gpu (the capture GPU's PCI bus address) is specific to the
            # host's hardware layout; set
            # services.moonshine.settings.compositor.gpu per-host, e.g. in
            # hosts/vermilion.nix.
            keyboard = {
              layout = "hu";
              model = "pc105";
            };
          };

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
                heroicLaunchExe
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
