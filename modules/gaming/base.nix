{
  flake-file.inputs.scopebuddy = {
    url = "github:OpenGamingCollective/ScopeBuddy";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  den.aspects.gaming-base = {
    nixos = {
      config,
      pkgs,
      inputs',
      ...
    }: {
      # shortcut: carries the unmerged fix for gamemode's exit-hook abort (a bwrap core
      # dump per Faugus game exit, FeralInteractive/gamemode#575). Delete it once
      # nixpkgs' gamemode includes the fix; the patch stops applying then.
      nixpkgs.overlays = [
        (final: prev: {
          gamemode = prev.gamemode.overrideAttrs (old: {
            patches =
              old.patches
              ++ [
                (final.fetchpatch {
                  url = "https://github.com/FeralInteractive/gamemode/commit/92730d09dc20f654e7c96903c011cdade7a93e2f.patch";
                  includes = ["lib/client_impl.c"]; # the fix, without its test
                  hash = "sha256-Sv+QZmkhJRcM8g3w5cY02J0g23zjm7LaREhKgnJUhQU=";
                })
              ];
          });
        })
      ];

      # programs.gamemode creates the 'gamemode' group;
      # the user needs to be a member (see provides.to-users below).
      programs.gamemode = {
        enable = true;
        enableRenice = true;
        settings = {
          general = {
            renice = 10;
          };
        };
      };

      # Enable udev rules for Steam hardware and uinput for Steam Input
      hardware = {
        steam-hardware.enable = true;
        uinput.enable = true;
      };

      services.udev.packages = with pkgs; [
        game-devices-udev-rules
        steam-devices-udev-rules
      ];

      # Hosts choose the package; vermilion sets Nyx's gamescope_git.
      programs.gamescope.enable = true;

      environment.systemPackages = with pkgs; [
        mangohud
        # scb prefixes its own gamescope onto PATH; hand it the host's choice instead.
        (inputs'.scopebuddy.packages.default.override {gamescope = config.programs.gamescope.package;})
        wineWow64Packages.waylandFull
        protonup-qt
      ];
    };

    provides.to-users.user.extraGroups = ["gamemode" "uinput"];
  };
}
