{
  den.aspects.networking = {
    nixos = {
      # Configure network connections interactively with nmcli or nmtui.
      networking.networkmanager.enable = true;

      # Enable the firewall
      networking.firewall.enable = true;
    };
  };

  den.aspects.tailscale = {
    nixos = {
      # Enabling tailscale
      services.tailscale = {
        enable = true;

        # Do not bypass the firewall for all incoming traffic
        extraSetFlags = [ "--netfilter-mode=nodivert" ];

        # Disabling logging and telemetry
        extraDaemonFlags = [ "--no-logs-no-support" ];
      };

      # Firewall settings for Tailscale
      networking = {
        firewall = {
          allowedUDPPorts = [ 41641 ];
          trustedInterfaces = [ "tailscale0" ];
        };
      };
    };
  };
}
