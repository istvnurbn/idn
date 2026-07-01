{
  den.aspects.gaming-steam = {user, ...}: {
    nixos = {pkgs, ...}: let
      # Single source of truth for compat tools. Stable names decouple the symlink path from package chrumn.
      # Using pkg.steamcompattool.name would rename symlinks on every update, orphaning per-game Proton selection.
      compatTools = with pkgs; [
        {
          pkg = proton-ge-bin;
          name = "GE-Proton";
        }
        {
          pkg = proton-cachyos;
          name = "Proton-CachyOS";
        }
      ];
    in {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        extest.enable = true;
        protontricks.enable = true;
        extraCompatPackages = map ({pkg, ...}: pkg) compatTools;
        extraPackages = with pkgs; [
          hidapi
        ];
      };

      # Enable udev rules for Steam hardware and uinput for Steam Input
      hardware = {
        steam-hardware.enable = true;
        uinput.enable = true;
      };

      # Link the Proton-GE and Proton CachyOS nix store path to the user directory.
      # This is needed for using these compat tools with Heroic and others.
      #
      # Discussion: https://discourse.nixos.org/t/using-proton-ge-bin-package-outside-of-steam/
      systemd.user.tmpfiles = let
        steamInstallDir = "%h/.local/share/Steam";
        compatToolDir = "${steamInstallDir}/compatibilitytools.d/";
        steamDir = "%h/.steam";
        mkCompatLink = {
          pkg,
          name,
        }: "L+ ${compatToolDir}/${name} - - - -${pkg.steamcompattool}";
      in {
        enable = true;
        rules =
          ["d ${compatToolDir} - - - - -"]
          ++ map mkCompatLink compatTools
          ++ [
            # When Steam gets started, it creates a directory with symlinks to  the install directory.
            # Third party tools are using these to find Proton versions
            "d ${steamDir} - - - - -"
            "L ${steamDir}/root - - - - ${steamInstallDir}"
            "L ${steamDir}/steam - - - - ${steamInstallDir}"
          ];
      };
    };

    impermanence = {
      users.${user.name} = {
        directories = [
          ".local/share/Steam"
          ".cache/protontricks"
        ];
      };
    };
  };
}
