{
  den.aspects.tor = {
    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        tor-browser
      ];
    };

    darwin = {
      homebrew.casks = [
        "tor-browser"
      ];
    };

    persistHome = {
      directories = [
        ".cache/tor project"
      ];
    };
  };
}
