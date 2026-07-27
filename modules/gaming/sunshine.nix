{
  den.aspects.sunshine = {user, ...}: {
    nixos = {
      services.sunshine = {
        enable = true;
        autoStart = true;
        capSysAdmin = false;
        openFirewall = true;
        settings.capture = "kwin";
      };
    };

    impermanence = {
      users.${user.name} = {
        directories = [
          ".config/sunshine"
        ];
      };
    };
  };
}
