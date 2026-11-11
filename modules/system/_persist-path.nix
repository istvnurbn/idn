# Where a file that must survive reboots really lives: under /persist on
# impermanent hosts (readable before impermanence mounts it into place),
# at its normal path elsewhere. Not a module (leading underscore); import it:
#   persistPath = import ./_persist-path.nix {inherit den;};
{den}: host: path:
if host.hasAspect den.aspects.impermanence
then "/persist${path}"
else path
