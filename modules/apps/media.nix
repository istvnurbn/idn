{
  den.aspects.media = {user, ...}: {
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

    darwin = {
      homebrew.casks = [
        "affinity"
        "calibre"
        "gimp"
        "iina"
        "imageoptim"
        "musicbrainz-picard"
        "spotify"
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
