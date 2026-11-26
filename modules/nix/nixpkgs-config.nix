# The one nixpkgs config for every package set this repo builds: each host's
# pkgs (den.default in dendritic.nix), pkgs.unstable (copies the host's) and
# the idn#... shell packages (idn-pkgs in unstable.nix). Macs add
# allowUnsupportedSystem (nix-darwin.nix).
{lib, ...}: {
  options.idn.nixpkgsConfig = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    description = "nixpkgs config of every package set this repo builds";
  };

  config.idn.nixpkgsConfig = {
    # Allow non-free packages
    allowUnfree = true;
  };
}
