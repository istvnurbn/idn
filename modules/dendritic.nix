{
  den,
  inputs,
  lib,
  ...
}: {
  # Setup for den
  flake-file.inputs = {
    flake-file.url = "github:denful/flake-file/v0.7.0";
    den.url = "github:denful/den/cbe76f223bd02a48e7611e157b33036f38425131";
  };

  imports = [
    (inputs.flake-file.flakeModules.dendritic or {})
    (inputs.den.flakeModules.dendritic or {})
  ];

  # den specific setup
  den = {
    schema.user.classes = lib.mkDefault ["homeManager"];
    # Host aspects' homeManager and persistHome reach every user.
    # Without it impermanence keeps none of a user's home paths.
    schema.user.includes = [den.batteries.host-aspects];

    # Aspects declare typed `settings`; hosts set them in hosts.nix.
    # See guides/aspect-settings in den's docs.
    reservedKeys = ["settings"];
    schema.host = {
      imports = [
        {
          options.settings = lib.mkOption {
            type = import ./_settings-type.nix {inherit den lib;};
            default = {};
            description = "Per-aspect typed settings";
          };
        }
      ];

      # Hosts take what their users hand them through provides.to-hosts
      # (steve.nix). Explicit, because den stops doing it by default in the
      # release planned for 2027-01-01 (den #694).
      includes = [den.batteries.mutual-provider];
    };

    default = {
      darwin = {
        system.stateVersion = 6;
        # Every host, with or without the nix aspect; pkgs.unstable copies it
        nixpkgs.config = import ./nix/_nixpkgs-config.nix;
      };
      homeManager.home.stateVersion = "26.05";
      nixos = {
        nixpkgs.config = import ./nix/_nixpkgs-config.nix;
        # Hosts installed on a later release override this in their aspect
        system.stateVersion = lib.mkDefault "26.05";
        # Declarative user management
        users.mutableUsers = false;
        # Hungarian keyboard on every console, including the initrd's
        # passphrase prompt and VM windows
        console.keyMap = "hu";
      };

      includes = [
        # Automatically sets home.username, home.homeDirectory, users.users.<name>
        den.provides.define-user
        # Makes user admin (wheel and networkmanager)
        den.provides.primary-user
        # Sets shell for user at OS and HM level
        (den.provides.user-shell "zsh")
        # Automatically sets networking.hostName from host name
        den.provides.hostname
        # flake inputs with the system pre-selected
        den.provides.inputs'
        # Every macOS host: without it nix-darwin ignores homebrew.casks
        den.aspects.nix-homebrew
      ];
    };
  };
}
