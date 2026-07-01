{
  den.aspects.gaming-heroic = {user, ...}: {
    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        heroic
      ];

      nixpkgs.config.permittedInsecurePackages = [
        "pnpm-10.29.2"
      ];

      impermanence = {
        users.${user.name} = {
          directories = [
            ".config/heroic"
          ];
        };
      };
    };
  };
}
