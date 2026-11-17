{
  flake-file.inputs.darwin = {
    url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # darwin-rebuild and the other darwin-* tools come with nix-darwin (system.tools)
  den.aspects.nix-darwin.darwin = {
    # Many packages report they don't support aarch64-darwin, but they build
    # and run fine here. NixOS hosts keep nixpkgs' platform check.
    nixpkgs.config.allowUnsupportedSystem = true;
  };
}
