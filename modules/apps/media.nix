{den, ...}: {
  den.aspects.media = {
    # services.flatpak.packages below comes from the nix-flatpak module;
    # pkgs.unstable comes from the unstable aspect
    includes = [
      den.aspects.flatpak
      den.aspects.unstable
    ];

    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        gimp
        picard
        vlc
        unstable.audacious
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
        ".config/audacious"
        ".config/GIMP"
        ".config/MusicBrainz"
        ".config/vlc"
        ".var/app/com.jeffser.Nocturne"
      ];
    };
  };
}
