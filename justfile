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
    nh os build {{ args }}

# Build and activate the new configuration, and make it the boot default
[linux]
switch *args:
    nh os swtitch {{ args }}

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

# Build and activate the new configuration
[macos]
test *args:
    nh darwin test {{ args }}

# Build the new configuration and make it the boot default
[macos]
boot *args:
    nh darwin build {{ args }}

# Build and activate the new configuration, and make it the boot default
[macos]
switch *args:
    nh darwin swtitch {{ args }}

# List available generations from profile path
[macos]
info *args:
    nh darwin info {{ args }}

# Rollback to a previous generation
[macos]
rollback *args:
    nh darwin rollback {{ args }}

# Load system in a repl
[macos]
repl *args:
    nh darwin repl {{ args }}
