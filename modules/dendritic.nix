{
  den,
  inputs,
  ...
}: {
  # Setup for den
  flake-file.inputs = {
    flake-file.url = "github:denful/flake-file";
    den.url = "github:denful/den";
  };

  imports = [
    (inputs.flake-file.flakeModules.dendritic or {})
    (inputs.den.flakeModules.dendritic or {})
  ];

  # den specific setup
  den = {
    schema.user.classes = ["homeManager"];

    default = {
      nixos.system.stateVersion = "26.05";
      homeManager.home.stateVersion = "26.05";

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
