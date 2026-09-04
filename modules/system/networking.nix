{
  den.aspects.networking = {host, ...}: {
    nixos = {lib, ...}: {
      networking = {
        # Configure network connections interactively with nmcli or nmtui.
        networkmanager.enable = true;

        # Enable the firewall
        firewall.enable = true;
      };

      # Legacy multicast name resolution, vulnerable to spoofing
      services.resolved.settings.Resolve.LLMNR = lib.mkDefault "false";
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
