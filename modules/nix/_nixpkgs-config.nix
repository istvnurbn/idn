# The one nixpkgs config for every package set this repo builds: each host's
# pkgs (den.default in dendritic.nix), pkgs.unstable (copies the host's) and
# the idn#... shell packages (idn-pkgs in unstable.nix). Macs add
# allowUnsupportedSystem (nix-darwin.nix). The leading underscore keeps
# import-tree from loading it as a module.
{
  # Allow non-free packages
  allowUnfree = true;
}
