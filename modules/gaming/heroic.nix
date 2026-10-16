{
  den.aspects.heroic = {
    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        heroic
      ];

      nixpkgs.config.permittedInsecurePackages = [
        "pnpm-10.29.2"
      ];
    };

    persistHome = {
      directories = [
        ".config/heroic"
        ".local/share/umu"
      ];
    };
  };
}
