{inputs, ...}: {
  flake-file.inputs.nix-flatpak = {
    url = "github:gmodena/nix-flatpak";
  };

  den.aspects.flatpak = {
    nixos = {
      imports = [inputs.nix-flatpak.nixosModules.nix-flatpak];

      services.flatpak = {
        enable = true;
        update.auto.enable = true;
        uninstallUnmanaged = true;
      };
    };

    persist = {
      directories = [
        "/var/lib/flatpak"
      ];
    };
  };
}
