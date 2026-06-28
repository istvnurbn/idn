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
