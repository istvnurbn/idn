{
  den.aspects.gui-media = {user, ...}: {
    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        gimp
        picard
        vlc
      ];

      services.flatpak.packages = [
        "com.jeffser.Nocturne"
      ];
    };

    impermanence = {
      users.${user.name} = {
        directories = [
          ".config/GIMP"
          ".config/MusicBrainz"
          ".config/vlc"
          ".var/app/com.jeffser.Nocturne"
        ];
      };
    };
  };
}
