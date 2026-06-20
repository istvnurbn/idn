_default:
    @just --list --unsorted

# Generate a new flake.nix file
write:
    nix run .#write-flake

# Update flake inputs to their latest revisions
update *args:
    nix flake update --commit-lock-file --flake . {{ args }}

# Validate the flake.nix file
check:
    nix flake check .

# Build the NixOS configuration without switching to it
build *args:
    sudo nixos-rebuild build --flake . {{ args }} |& nom
    nvd diff /run/current-system ./result

# Build the NixOS configuration and switch to it
switch *args:
    sudo nixos-rebuild switch --flake . {{ args }} |& nom

# Show the nix profile history
history:
    nix profile history --profile /nix/var/nix/profiles/system

# Perform a manual clean (garbage collect and wipe-history)
clean:
    sudo -H nix-env --profile /nix/var/nix/profiles/system --delete-generations old
    sudo -H nix-collect-garbage --delete-older-than 3d
