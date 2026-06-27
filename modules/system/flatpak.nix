{inputs, ...}: {
  flake-file.inputs.nix-flatpak = {
    url = "github:gmodena/nix-flatpak";
  };

  den.aspects.flatpak = {
    nixos = {pkgs, ...}: {
      imports = [inputs.nix-flatpak.nixosModules.nix-flatpak];

      services.flatpak = {
        enable = true;
        update.auto.enable = false;
        uninstallUnmanaged = true;
      };

      systemd.services.flatpak-repo = {
        wantedBy = ["multi-user.target"];
        path = [pkgs.flatpak];
        script = ''
          flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        '';
      };
    };

    impermanence = {
      directories = [
        "/var/lib/flatpak"
      ];
    };
  };
}
