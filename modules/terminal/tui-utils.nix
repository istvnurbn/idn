{
  den.aspects.tui-utils = {user, ...}: {
    os = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        btop
        fastfetch
      ];
    };

    impermanence = {
      users.${user.name} = {
        files = [
          ".config/btop/btop.conf"
        ];
      };
    };
  };
}
