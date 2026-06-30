{
  den.aspects.gaming-steam = {user, ...}: {
    nixos = {pkgs, ...}: {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        extest.enable = true;
        protontricks.enable = true;
        extraCompatPackages = with pkgs; [
          proton-ge-bin
          proton-cachyos-x86_64_v3
        ];
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
      systemd.user.tmpfiles = {
        enable = true; # Let this fail, if someone changes the default.
        rules = let
          steamInstallDir = "%h/.local/share/Steam";
          compatDir = "${steamInstallDir}/compatibilitytools.d";
          linkGE = "${compatDir}/Proton-GE";
          linkCachy = "${compatDir}/Proton-CachyOS";
          protonGE = pkgs.proton-ge-bin.steamcompattool.outPath;
          cachyOS = pkgs.proton-cachyos-x86_64_v3.steamcompattool.outPath;
          steamDir = "%h/.steam";
        in [
          "d ${compatDir} - - - - -"
          "L+ ${linkGE} - - - - ${protonGE}"
          "L+ ${linkCachy} - - - - ${cachyOS}"

          # When Steam gets started for the first time, it creates a directory with
          # symlinks to the install directory (among other things). Third party
          # tools are using these to find Proton versions.
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
