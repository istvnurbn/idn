{
  den.aspects.gui-base = {user, ...}: {
    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        ghostty
        zed-editor
      ];
    };

    impermanence = {
      users.${user.name} = {
        directories = [
          ".local/share/zed"
        ];
      };
    };
  };
}
