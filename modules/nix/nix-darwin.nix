{
  flake-file.inputs.darwin = {
    url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.nix-darwin.darwin = {inputs', ...}: {
    environment.systemPackages = with inputs'.darwin.packages; [
      darwin-option
      darwin-rebuild
      darwin-version
      darwin-uninstaller
    ];
  };
}
