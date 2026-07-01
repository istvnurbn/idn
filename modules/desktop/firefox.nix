{
  den.aspects.firefox = {user, ...}: {
    nixos = {
      programs.firefox.enable = true;
    };

    impermanence = {
      users.${user.name} = {
        directories = [
          ".config/mozilla"
        ];
      };
    };
  };
}
