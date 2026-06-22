{ den, ... }: {
  den.schema.user = {
    includes = [ den.batteries.mutual-provider ];
    classes = [ "homeManager" ];
  };

  den.default = {
    nixos.system.stateVersion = "26.05";
    homeManager.home.stateVersion = "26.05";

    includes = [
      den.provides.hostname
      den.provides.define-user
    ];
  };
}
