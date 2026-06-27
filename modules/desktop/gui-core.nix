{
  den.aspects.gui-core = {user, ...}: {
    nixos = {pkgs, ...}: {
      programs.localsend = {
        enable = true;
        openFirewall = true;
      };

      services.flatpak.packages = [
        "com.jeffser.Nocturne"
      ];

      environment.systemPackages = with pkgs; [
        ghostty
        zed-editor
        vlc
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
