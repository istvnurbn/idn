{
  den.aspects.networking = {host, ...}: {
    nixos = {lib, ...}: {
      networking = {
        # Configure network connections interactively with nmcli or nmtui.
        networkmanager.enable = true;
      };

      # Legacy multicast name resolution, vulnerable to spoofing.
      services.resolved.settings.Resolve.LLMNR = lib.mkDefault "false";
    };

    darwin = {
      networking = {
        computerName = host.name;
        localHostName = host.name;
        # Enable application firewall
        applicationFirewall = {
          enable = true;
          allowSigned = true;
          allowSignedApp = true;
          blockAllIncoming = false;
          enableStealthMode = false;
        };
      };
    };

    persist = {
      directories = [
        "/etc/NetworkManager/system-connections"
        # secret_key (the seed for stable MAC and IPv6 addresses), DHCP leases
        # and timestamps; without it every boot looks like a new machine
        "/var/lib/NetworkManager"
      ];
    };
  };
}
