{
  den.aspects.networking = {
    nixos = {
      # Configure network connections interactively with nmcli or nmtui.
      networking.networkmanager.enable = true;

      # Enable the firewall
      networking.firewall.enable = true;
    };

    impermanence = {
      directories = [
        "/etc/NetworkManager/system-connections"
      ];
    };
  };
}
