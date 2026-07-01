{
  den.aspects.media = {
    os = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        abcde
        cddiscid
        exiftool
        ffmpeg-full
        flac
        hugo
        id3v2
        imagemagick
        lame
        libcdio-paranoia
        recode
      ];
    };
  };
}
