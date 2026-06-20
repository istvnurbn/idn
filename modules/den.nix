{ inputs, ... }:
{
  # we can import this flakeModule even if we dont have flake-parts as input!
  imports = [ inputs.den.flakeModule ];

  den.hosts.x86_64-linux.vermilion.users.steve = {
    classes = [ "user" ]; # no homeManager
  };
}
