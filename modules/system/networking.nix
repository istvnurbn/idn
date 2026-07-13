{
  den.aspects.networking = {host, ...}: {
    nixos = {
      networking = {
        # Configure network connections interactively with nmcli or nmtui.
        networkmanager.enable = true;

        # Enable the firewall
        firewall.enable = true;
      };
    };

    darwin = {
      networking = {
        computerName = host.name;
        localHostName = host.name;
        # Enable application firewall
        applicationFirewall.enable = true;
      };
    };

    impermanence = {
      directories = [
        "/etc/NetworkManager/system-connections"
      ];
    };
  };
}
