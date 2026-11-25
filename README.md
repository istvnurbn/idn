<div align="center">
  <img src="/assets/nixos-logomark-rainbow-gradient-minimal.png" width="128" alt="NixOS logomark"/>
  <br/>
  <h1>iDN</h1>
  <p>
    <b>istvnurbn's dendritic nixconfig</b>
    <br/>
    <i>A Nix flake to manage my Unices.</i>
  </p>
</div>

## Highlights

- **Dendritic pattern via [den](https://github.com/denful/den):** one aspect per file, with hosts composing aspects directly.
- **Multi-platform:** macOS, NixOS and WSL hosts are all composed from the same shared aspects.
- **Opt-in impermanence:** the btrfs root is wiped on every boot. Every aspect declares what it needs to survive and hosts that don’t opt in simply ignore these entries.
- **Cross-entity user config:** aspects deliver their per-user home manager payload to every user of the host.
- **Convenient to use** — `just` wraps [`nh`](https://github.com/nix-community/nh) with the same subcommands and each host is also exposed as a flake app: `nix run .#hostname`

## How it works

Each file in the `modules/` directory describes one _aspect_. Each aspect contains everything it needs on every supported platform, including macOS and NixOS configurations, per-user dotfiles and folders that survive reboots when impermanence is enabled.

A host is simply a list of aspects: if something is on the list, it is on the machine; if it isn't, it isn't. Adding a new machine means creating a new "list".

Flake inputs are declared next to the aspect that uses them, and [flake-file](https://github.com/denful/flake-file) generates `flake.nix` from all of them.

Otherwise, the code is commented generously — partly for you, mostly for the me of six months from now.

## Hosts

| Host        | Platform   | Role                                   |
| ----------- | ---------- | -------------------------------------- |
| `hexley`    | nix-darwin | My everyday MacBookPro18,3             |
| `loophole`  | NixOS-WSL  | Nix tooling and more on my work laptop |
| `vermilion` | NixOS      | AMD gaming desktop                     |

## Usage

```console
just write      # regenerate flake.nix
just update     # update flake inputs
just switch     # build, activate, make boot default
just rollback   # go back a generation
```

Run `just` to see the full list.

`just check` builds every host of the current platform and runs the VM tests in [`modules/checks`](modules/checks), each described at the top of its file. To run one alone, `nix build .#checks.x86_64-linux.<name> -L`:

- `vm-server` and `vm-internet-facing`: the shared server aspects and their hardening, booted next to a client.
- `vm-boot-chain`: the encrypted desktop boot on UEFI with Secure Boot and a software TPM. Lanzaboote boots with Secure Boot on, root unlocks at the `hu` console prompt, over initrd SSH and by the TPM, the data disk opens through its keyfile, and home-manager comes up.
- `install-impermanence-root`, `install-impermanence-root-luks` and `install-data`: disko formats each disk layout, the host is installed onto it and booted, and the mounts and `/etc/fstab` must match the layout (one `subvol=` per subvolume mount). The impermanence root is also rebooted once: a file on `/` is gone and its old root sits under `old_roots/`, while persisted paths in `/` and in home, `/etc/machine-id` and `/var/log` keep their content.
- `no-test-keys`: no host trusts one of nixpkgs' snakeoil SSH keys or takes an initrd secret or SSH host key from the Nix store.

To drive a VM test by hand, start its interactive driver, then in its Python prompt boot the machines and open a shell on one:

```console
nix run '.#checks.x86_64-linux.<name>.driverInteractive'
>>> start_all()
>>> machine.shell_interact()
```

`vermilion` also builds as a VM of itself that logs `steve` in on tty1. Its VM-only settings sit under `virtualisation.vmVariant` in [`modules/hosts/vermilion.nix`](modules/hosts/vermilion.nix), so the real system is unchanged:

```console
nix build '.#nixosConfigurations.vermilion.config.system.build.vm'
./result/bin/run-vermilion-vm   # keeps its disk in ./vermilion.qcow2
```

## AI Notice

The idea and the initial design of the work presented here are my own. However, I was assisted by Claude in catching mistakes (numerous and sometimes blatantly obvious) and working through the trickier parts as I'm learning this.

## License

[MIT](LICENSE)
