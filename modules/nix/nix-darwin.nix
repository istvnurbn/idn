{
  flake-file.inputs.darwin = {
    url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.nix-darwin.darwin = {inputs', ...}: {
    # Many packages report they don't support aarch64-darwin, but they build
    # and run fine here. NixOS hosts keep nixpkgs' platform check.
    nixpkgs.config.allowUnsupportedSystem = true;

    environment.systemPackages = with inputs'.darwin.packages; [
      darwin-option
      darwin-rebuild
      darwin-version
      darwin-uninstaller
    ];
  };
}
