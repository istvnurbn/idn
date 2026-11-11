{
  inputs,
  den,
  lib,
  ...
}: {
  # Upstream's flake tracks main, ahead of nixpkgs. Its own nixpkgs only
  # builds its packages/devShells; the NixOS module builds against host pkgs.
  flake-file.inputs.moonshine = {
    url = "github:istvnurbn/moonshine/faugus-scanner";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  den.aspects.moonshine = {
    # pkgs.unstable comes from the overlays aspect
    includes = [den.aspects.overlays];

    # Static aspect: Den only discovers `settings` outside a function.
    # Set per host in hosts.nix, e.g. settings.moonshine.gpu.
    settings.gpu = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "0000:03:00.0";
      description = "PCI bus address of the capture GPU; null lets moonshine pick";
    };

    nixos = {
      config,
      host,
      user,
      pkgs,
      lib,
      ...
    }: let
      cfg = host.settings.moonshine;

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

      steamShutdownExe = lib.getExe steamShutdown;

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

      heroicShutdownExe = lib.getExe heroicShutdown;

      steamLaunch = pkgs.writeShellApplication {
        name = "moonshine-steam-launch";
        text = ''
          ${steamShutdownExe}
          exec ${steamExe} "$@"
        '';
      };

      steamLaunchExe = lib.getExe steamLaunch;

      heroicLaunch = pkgs.writeShellApplication {
        name = "moonshine-heroic-launch";
        text = ''
          ${heroicShutdownExe}
          exec ${heroicExe} "$@"
        '';
      };

      heroicLaunchExe = lib.getExe heroicLaunch;
    in {
      # Upstream's module, not nixpkgs'. It builds moonshine against the
      # host's pkgs on purpose: mesa/Vulkan load from /run/opengl-driver and
      # break if moonshine links an older glibc than they do.
      imports = [inputs.moonshine.nixosModules.default];

      # sunshine and moonshine would fight over the same ports
      assertions = [
        {
          assertion = !(host.hasAspect den.aspects.sunshine);
          message = "moonshine: the host also includes sunshine; keep only one";
        }
      ];

      # Upstream only has a global openFirewall. Open the GameStream ports,
      # plus 5353/udp for its mDNS responder, on LAN or VPN-facing interfaces
      # only; see Security in the main README. tailscale0 is already trusted.
      networking.firewall.interfaces.eno1 = let
        s = config.services.moonshine.settings;
      in {
        allowedTCPPorts = [
          (s.webserver.port_https or 47984)
          (s.webserver.port or 47989)
          (s.stream.port or 48010)
        ];
        allowedUDPPorts = [
          5353
          (s.stream.video.port or 47998)
          (s.stream.control.port or 47999)
          (s.stream.audio.port or 48000)
        ];
      };

      services.moonshine = {
        enable = true;

        # The user whose applications you want to stream.
        user = user.name;
        # Locates /run/user/<uid>. Upstream derives it from users.users.<user>.uid,
        # which we leave allocated; first normal user gets 1000 (`id -u`).
        uid = 1000;

        # An idle Moonlight client polls the HTTPS port every 5s, logging a
        # WARN for every dropped TLS probe.
        logFilter = "moonshine=info,moonshine::tls=error";

        # Everything from the Configuration section of the main README goes
        # here, written as nix instead of TOML.
        settings = {
          name = host.name;

          compositor = {
            gpu = lib.mkIf (cfg.gpu != null) cfg.gpu;
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
            {
              # `--game` needs no shutdown wrapper: it runs Faugus' runner
              # directly instead of forwarding to a running instance.
              type = "faugus";
              command = [
                (lib.getExe pkgs.unstable.faugus-launcher)
                "--game"
                "{game_id}"
              ];
            }
          ];
        };
      };
    };

    # Upstream's module, unlike nixpkgs', does not add `input` (virtual
    # gamepads for streamed games); steve/steve.nix already does.
    provides.to-users.user.extraGroups = ["moonshine"];

    persistHome = {
      directories = [
        ".config/moonshine" # certs
        ".local/share/moonshine" # paired clients
      ];
    };
  };
}
