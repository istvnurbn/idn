{
  den.aspects.gaming-heroic = {
    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        heroic
      ];

      nixpkgs.config.permittedInsecurePackages = [
        "pnpm-10.29.2"
      ];
    };
  };
}
