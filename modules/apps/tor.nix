{
  den.aspects.tor = {user, ...}: {
    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        tor-browser
      ];
    };

    darwin = {
      homebrew.casks = [
        "tor-browser"
      ];
    };

    impermanence = {
      users.${user.name} = {
        directories = [
          ".cache/tor project"
        ];
      };
    };
  };
}
