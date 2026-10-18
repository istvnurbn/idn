{
  den,
  inputs,
  lib,
  ...
}: {
  # Setup for den
  flake-file.inputs = {
    flake-file.url = "github:denful/flake-file/latest";
    den.url = "github:denful/den/latest";
  };

  imports = [
    (inputs.flake-file.flakeModules.dendritic or {})
    (inputs.den.flakeModules.dendritic or {})
  ];

  # den specific setup
  den = {
    schema.user.classes = ["homeManager"];
    # Host aspects' homeManager and persistHome reach every user.
    # Without it impermanence keeps none of a user's home paths.
    schema.user.includes = [den.batteries.host-aspects];

    # Aspects declare typed `settings`; hosts set them in hosts.nix.
    # See guides/aspect-settings in den's docs.
    reservedKeys = ["settings"];
    schema.host.imports = [
      {
        options.settings = lib.mkOption {
          type = import ./_settings-type.nix {inherit den lib;};
          default = {};
          description = "Per-aspect typed settings";
        };
      }
    ];

    default = {
      darwin.system.stateVersion = 6;
      homeManager.home.stateVersion = "26.05";
      nixos = {
        system.stateVersion = "26.05";
        # Declarative user management
        users.mutableUsers = false;
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
      ];
    };
  };
}
