{
  den.aspects.media = {
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
        "spotify"
      ];
    };

    persistHome = {
      directories = [
        ".config/GIMP"
        ".config/MusicBrainz"
        ".config/vlc"
        ".var/app/com.jeffser.Nocturne"
      ];
    };
  };
}
