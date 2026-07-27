{
  den.aspects.sunshine = {user, ...}: {
    nixos = {
      services.sunshine = {
        enable = true;
        autoStart = true;
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
