{
  den.aspects.networking = {host, ...}: {
    nixos = {lib, ...}: {
      networking = {
        # Configure network connections interactively with nmcli or nmtui.
        networkmanager.enable = true;

        # Enable the firewall
        firewall.enable = true;
      };

      # Legacy multicast name resolution, vulnerable to spoofing.
      # Not a no-op while stage 2 runs no resolved: the luks-ssh-unlock
      # initrd does, and its resolved.conf is built from these settings.
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
      ];
    };
  };
}
