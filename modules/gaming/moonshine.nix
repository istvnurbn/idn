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
    # pkgs.unstable comes from the unstable aspect
    includes = [den.aspects.unstable];

    # Static aspect: Den only discovers `settings` outside a function.
    # Set per host in hosts.nix, e.g. settings.moonshine.gpu.
    settings.gpu = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "0000:03:00.0";
      description = "PCI bus address of the capture GPU; null lets moonshine pick";
    };

    # Each host names its own LAN interfaces; an empty list fails the build
    # (see assertions) rather than silently opening nothing.
    settings.interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["eno1"];
      description = "LAN interfaces to open the GameStream and mDNS ports on";
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

      # Launchers are only offered for the ones the host has
      hasSteam = host.hasAspect den.aspects.steam;
      hasFaugus = host.hasAspect den.aspects.faugus;

      # The Steam the steam aspect installs (programs.steam), not whatever
      # is on PATH. Only evaluated when hasSteam.
      steam = lib.getExe config.programs.steam.package;

      # Steam is single-instance per user: with a desktop Steam running, the
      # stream's steam:// URL opens on the desktop instead and the session
      # fails. Runs as the session's pre_command (ExecStartPre), so the
      # stream's Steam starts only once the desktop one is gone. The stream's
      # own Steam needs no stop: ending the session stops its unit.
      steamStop = lib.getExe (pkgs.writeShellApplication {
        name = "moonshine-steam-stop";
        runtimeInputs = [pkgs.procps pkgs.coreutils];
        text = ''
          pgrep -x steam >/dev/null || exit 0

          # Ask nicely, then escalate: SIGTERM, and SIGKILL 5s later
          ${steam} -shutdown >/dev/null 2>&1 || true
          timeout 30 pidwait -x steam || true
          pgrep -x steam >/dev/null || exit 0

          echo "steam still up 30s after -shutdown, sending SIGTERM" >&2
          pkill -x steam || true
          timeout 5 pidwait -x steam || true
          pkill -KILL -x steam || true
        '';
      });

      # Shared by the Big Picture app and the Steam scanner
      steamSession = {
        pre_command = [[steamStop]];
      };
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
        {
          assertion = cfg.interfaces != [];
          message = "moonshine: set settings.moonshine.interfaces for this host in hosts.nix, e.g. [\"eno1\"]";
        }
      ];

      # Upstream only has a global openFirewall. Open the GameStream ports,
      # plus 5353/udp for its mDNS responder, on LAN or VPN-facing interfaces
      # only; see Security in the main README. tailscale0 is already trusted.
      networking.firewall.interfaces = let
        s = config.services.moonshine.settings;
      in
        lib.genAttrs cfg.interfaces (_: {
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
        });

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

          application = lib.optional hasSteam (steamSession
            // {
              title = "Steam Big Picture";
              command = [steam "steam://open/bigpicture"];
              # gamescope's -e, so Steam's overlay and focus work. The Steam
              # scanner always turns it on for its games.
              steam_integration = true;
            });

          application_scanner =
            lib.optional hasSteam (steamSession
              // {
                type = "steam";
                library = "$HOME/.local/share/Steam";
                command = [steam "steam://rungameid/{game_id}"];
              })
            ++ lib.optional hasFaugus {
              # `--game` needs no pre_command: it runs Faugus' runner
              # directly instead of forwarding to a running instance.
              type = "faugus";
              command = [
                (lib.getExe pkgs.unstable.faugus-launcher)
                "--game"
                "{game_id}"
              ];
            };
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
