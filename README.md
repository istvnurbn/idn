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

## License

[MIT](LICENSE)
