{
  den.aspects.sunshine = {user, ...}: {
    nixos = {
      services.sunshine = {
        enable = true;
        autoStart = false;
        capSysAdmin = true;
        openFirewall = true;
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
