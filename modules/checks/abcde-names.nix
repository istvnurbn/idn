# Fails when mungefilename in abcde.conf stops giving the names the Picard
# naming script gives, e.g. when uconv (icu.dev) goes missing and every
# name becomes "unknown".
#
#   nix build .#checks.x86_64-linux.abcde-names
{
  den,
  inputs,
  lib,
  ...
}: {
  flake.checks = lib.genAttrs den.systems (system: let
    pkgs = inputs.nixpkgs.legacyPackages.${system};
  in {
    abcde-names = pkgs.runCommand "abcde-names" {nativeBuildInputs = [pkgs.icu.dev];} ''
      HOME=$TMPDIR
      . ${../steve/dotfiles/abcde.conf}
      fails=0
      expect() {
          local got
          got=$(mungefilename "$1")
          [[ $got == "$2" ]] || { echo "mungefilename '$1': got '$got', want '$2'" >&2; fails=1; }
      }
      expect "Кино & Björk's [Live]" "Kino_and_Bjorks_(Live)"
      expect "Straße Ő-Side" "Strasse_O_Side"
      expect "a [] b" "a_b"
      expect "?!" "unknown"
      (( fails == 0 )) && touch $out
    '';
  });
}
