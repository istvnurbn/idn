{
  den.aspects.office = {
    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        libreoffice-qt
        hunspell
        hunspellDicts.en_GB-ize
        hunspellDicts.en_US
        hunspellDicts.hu_HU
        hyphenDicts.en_GB
        hyphenDicts.en_US
        hyphenDicts.hu_HU
      ];
    };
  };
}
