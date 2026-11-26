{
  den.aspects.avahi.nixos = {options, ...}: {
    services.avahi =
      {
        enable = true;
        openFirewall = true;
        nssmdns4 = true;
      }
      # Unstable (vermilion) moved publish.* into settings and warns on the old
      # names; 26.05 has no settings option, so stable keeps publish.*
      // (
        if options.services.avahi ? settings
        then {
          settings.publish = {
            disable-publishing = false;
            publish-addresses = true;
          };
        }
        else {
          publish = {
            enable = true;
            addresses = true;
          };
        }
      );
  };
}
