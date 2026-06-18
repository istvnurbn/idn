{ inputs, den, ... }:
{
  # we can import this flakeModule even if we dont have flake-parts as input!
  imports = [ inputs.den.flakeModule ];

  den.hosts.x86_64-linux.vermilion.users.steve = {
    classes = [ "user" ]; # no homeManager
  };

  den.aspects.vermilion = {
    includes = [ den.batteries.hostname ];
    nixos =
      { pkgs, ... }:
      {
        imports = [
          ./_nixos/configuration.nix
          inputs.disko.nixosModules.disko
        ];
      };
  };

  den.aspects.steve = {
    includes = [ den.batteries.primary-user ];
  };
}
