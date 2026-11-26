_default:
    @just --list --unsorted

## Common

# Generate a new flake.nix file
write:
    nix run .#write-flake

# Update flake inputs to their latest revisions
update *args:
    nix flake update --commit-lock-file --flake . {{ args }}

# Validate the flake.nix file
check:
    nix flake check .

# Move the stable inputs to another release, e.g. `just bump-stable 26.11`
bump-stable version:
    #!/usr/bin/env bash
    set -euo pipefail
    [[ "{{ version }}" =~ ^[0-9]{2}\.(05|11)$ ]] || { echo "bump-stable: '{{ version }}' is not a release like 26.11" >&2; exit 1; }
    # Same branch names as the urls in modules/flake-inputs.nix, nix/wsl.nix and nix/nix-darwin.nix
    for ref in NixOS/nixpkgs:nixos nix-community/home-manager:release nix-community/NixOS-WSL:release nix-darwin/nix-darwin:nix-darwin; do
        repo=${ref%%:*} branch=${ref#*:}-{{ version }}
        git ls-remote --exit-code --heads "https://github.com/$repo" "$branch" >/dev/null \
            || { echo "bump-stable: $repo has no $branch branch yet; try again once {{ version }} is out" >&2; exit 1; }
    done
    sed -i 's/^  config\.idn\.stableRelease = ".*";$/  config.idn.stableRelease = "{{ version }}";/' modules/flake-inputs.nix
    grep -q '^  config\.idn\.stableRelease = "{{ version }}";$' modules/flake-inputs.nix \
        || { echo "bump-stable: idn.stableRelease line not found in modules/flake-inputs.nix" >&2; exit 1; }
    just write
    nix flake update --flake . nixpkgs home-manager nixos-wsl darwin

# Perform a manual clean (garbage collect and wipe-history)
clean *args:
    nh clean all {{ args }}

## NixOS

# Build the new configuration
[linux]
build *args:
    nh os build {{ args }}

# Build and activate the new configuration
[linux]
test *args:
    nh os test {{ args }}

# Build the new configuration and make it the boot default
[linux]
boot *args:
    nh os boot {{ args }}

# Build and activate the new configuration, and make it the boot default
[linux]
switch *args:
    nh os switch {{ args }}

# List available generations from profile path
[linux]
info *args:
    nh os info {{ args }}

# Rollback to a previous generation
[linux]
rollback *args:
    nh os rollback {{ args }}

# Load system in a repl
[linux]
repl *args:
    nh os repl {{ args }}

## macOS

# Build the new configuration
[macos]
build *args:
    nh darwin build {{ args }}

# Build and activate the new configuration, and make it the boot default
[macos]
switch *args:
    nh darwin switch {{ args }}

# List available generations from profile path
[macos]
info *args:
    sudo darwin-rebuild --list-generations {{ args }}

# Rollback to a previous generation
[macos]
rollback *args:
    sudo darwin-rebuild --rollback {{ args }}

# Load system in a repl
[macos]
repl *args:
    nh darwin repl {{ args }}
