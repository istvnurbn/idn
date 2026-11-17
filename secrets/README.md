# Secrets

iDN keeps its secrets in [`shared.yaml`](shared.yaml), encrypted with [sops](https://github.com/getsops/sops). The values are encrypted with one data key, and the data key is encrypted for every recipient in [`.sops.yaml`](../.sops.yaml) at the repo root. Hosts decrypt them at activation with [sops-nix](https://github.com/Mic92/sops-nix), set up in [`modules/system/sops.nix`](../modules/system/sops.nix).

Today the file holds one secret, `steve-password`: the hash of `steve`'s login password. Every user of a host that includes `sops` gets their password from a `<user>-password` entry here (SSH logins use keys instead).

## Who can decrypt

| Recipient     | Its private key                                                   | Used for                                            |
| ------------- | ----------------------------------------------------------------- | --------------------------------------------------- |
| People        | `~/.ssh/id_ed25519` on each machine you edit secrets from         | Editing secrets                                     |
| Hosts         | `/etc/ssh/ssh_host_ed25519_key` on each host that includes `sops` | Decrypting at activation                            |
| Emergency key | An age key that lives only in your password manager               | Re-encrypting when none of your machines is at hand |

Encrypting only needs the public keys, which is why `.sops.yaml` can list them in a public repo. Decrypting, and so changing who can decrypt, needs one of the private keys.

## Before you start

Run everything from the repo root, since sops looks for `.sops.yaml` in the current directory and its parents. Get sops and mkpasswd from iDN's nixpkgs:

```sh
nix shell --inputs-from . nixpkgs#sops nixpkgs#mkpasswd
```

To check that `shared.yaml` is encrypted for exactly the keys in `.sops.yaml`, run `sops updatekeys secrets/shared.yaml`. If they match, it says "already up to date", even without a key.

## Everyday tasks

### See or edit secrets

```sh
sops edit secrets/shared.yaml
```

It opens the decrypted file in `$EDITOR` and encrypts it again when you save and quit. To print one value: `sops decrypt --extract '["steve-password"]' secrets/shared.yaml`.

Then commit, push, and `just switch` on the hosts that use what you changed.

### Change your password

```sh
hash=$(mkpasswd -m yescrypt) && printf '"%s"' "$hash" |
  sops set --value-stdin secrets/shared.yaml '["steve-password"]'
```

`mkpasswd` asks for the password, and `&&` keeps a failed `mkpasswd` from writing an empty value. Then commit, push, and `just switch` on every host that includes `sops`.

### Add a secret

1. Add `<name>: <value>` to the file with `sops edit secrets/shared.yaml`.
2. Declare it in the NixOS module of the aspect that uses it, on a host that includes `sops`. The build checks that `<name>` is in the file, so step 1 comes first:

   ```nix
   sops.secrets.<name>.sopsFile = ../../secrets/shared.yaml; # relative to the module
   # The decrypted file is config.sops.secrets.<name>.path, readable by root only unless you set owner or mode
   ```

3. Commit, push, and `just switch` on the hosts that use it.

Secrets that only some hosts should read belong in a file of their own, with its own creation rule in `.sops.yaml`. A secret you can't make again, like an API token, means [rebuilding the file](#installing-a-host-when-no-machine-can-decrypt) stops working, so keep the [emergency key](#the-emergency-key) set up.

### Add a recipient

Do this for a new host before it clones iDN (step 5 of [idn-primer](https://github.com/istvnurbn/idn-primer)), or for a new machine you'll edit secrets from.

1. Get its public key:
   - a host: `ssh steve@<host> cat /etc/ssh/ssh_host_ed25519_key.pub`
   - a machine you edit secrets from: its `~/.ssh/id_ed25519.pub`
2. In `.sops.yaml`, add it under `keys`, below the matching comment, with an anchor (`- &<name> ssh-ed25519 AAAA…`), and add `*<name>` to the creation rule's `age:` list. A reinstalled host's new key replaces its old entry.
3. Re-encrypt. Check that the `+++` line it shows is the new key, then answer `y`:

   ```sh
   sops updatekeys secrets/shared.yaml
   ```

4. Commit and push.

### Remove a recipient

1. Delete its entry in `.sops.yaml` and its anchor in the creation rule.
2. Re-encrypt: `sops updatekeys -y secrets/shared.yaml`.
3. If its private key might be in someone else's hands, that isn't enough: go on with [A machine is lost or stolen](#a-machine-is-lost-or-stolen) from step 2. Otherwise, for example a host you retired and wiped, commit and push.

## The emergency key

An age key whose private half lives only in your password manager, so you can re-encrypt from any machine when none of yours is at hand. It only opens the secrets: it isn't an SSH key and logs in nowhere.

### Set it up

1. Generate it in your own terminal:

   ```sh
   nix shell --inputs-from . nixpkgs#age -c age-keygen
   ```

2. Save the whole output in your password manager. Make sure you can open the password manager on a brand-new device without any of your current machines, with its password and 2FA backup codes kept somewhere else. Otherwise the key is out of reach exactly when you need it.
3. In `.sops.yaml`, add the public key (`age1…`) under `keys`, and `*emergency` to the creation rule's `age:` list:

   ```yaml
   keys:
     # …
     # Emergency: an age key kept only in the password manager
     - &emergency age1…
   ```

4. Re-encrypt with `sops updatekeys secrets/shared.yaml`. The `+++` line is the `age1…` key.
5. Test the copy in your password manager, not the one on your screen. The throwaway `HOME` hides your machine's own keys, which sops would otherwise use without telling you:

   ```sh
   read -rs SOPS_AGE_KEY && export SOPS_AGE_KEY   # paste the AGE-SECRET-KEY-1… line, then Enter
   env HOME="$(mktemp -d)" sops decrypt secrets/shared.yaml >/dev/null && echo works
   unset SOPS_AGE_KEY
   ```

6. Commit and push. Hosts need no rebuild: the data key and the secrets haven't changed.

### Use it

On any machine with Nix, in a clone of iDN: load the key, run the sops commands you need, then unset it. `read -s` keeps the key off the screen, out of your shell history and off the disk:

```sh
read -rs SOPS_AGE_KEY && export SOPS_AGE_KEY   # paste the AGE-SECRET-KEY-1… line, then Enter
sops updatekeys secrets/shared.yaml             # or any other sops command
unset SOPS_AGE_KEY
```

## When things go wrong

### Installing a host when no machine can decrypt

The install itself doesn't need the secrets. Only making the new host a recipient does.

1. Install with [idn-primer](https://github.com/istvnurbn/idn-primer) up to its step 5. If the machine you install from isn't in its `access.nix`, add that machine's key first, since keys are the only way into the installed system.
2. On the target as `steve`, clone iDN (the primer's step 5.3), add the host to iDN, and add its host key to `.sops.yaml` as in [Add a recipient](#add-a-recipient).
3. Re-encrypt, one of two ways:
   - **With the emergency key:** [use it](#use-it) to run `sops updatekeys secrets/shared.yaml`.
   - **Without it:** rebuild the file. Encrypting only needs the public keys already in `.sops.yaml`, and the file's one secret is your password's hash, which you can make again. If your other machines are only out of reach, keep their entries and type your current password. If they're lost or stolen, delete their entries first, type a new password, and afterwards go on with [A machine is lost or stolen](#a-machine-is-lost-or-stolen) from step 3.

     ```sh
     hash=$(mkpasswd -m yescrypt) && printf 'steve-password: %s\n' "$hash" |
       sops encrypt --filename-override secrets/shared.yaml --output secrets/shared.yaml /dev/stdin
     ```

     This only works while every secret in the file can be made again.

4. Run `git add -A` (flakes ignore untracked files), then finish the primer's step 5: `nixos-rebuild boot`, the copies into `/persist`, and the reboot. Push once you have GitHub access.
5. After the reboot, iDN lets in only the SSH keys its hosts publish, so log in on the console. To edit secrets from the new machine later, make its `~/.ssh/id_ed25519.pub` a recipient ([Add a recipient](#add-a-recipient)) and publish it in its host file's `ssh-keys`.

### A machine is lost or stolen

Treat every key on it as exposed: its user key, its host key, and every account signed in on it. If your password manager was signed in, that includes the emergency key: make a new one first ([Set it up](#set-it-up), steps 1–2) and swap it in at step 1.

1. In `.sops.yaml`, delete the machine's entries and their anchors in the creation rule.
2. On a machine that can still decrypt, or with the [emergency key](#use-it), drop the machine's access, replace the data key, and change your password:

   ```sh
   sops updatekeys -y secrets/shared.yaml
   sops rotate -i secrets/shared.yaml
   hash=$(mkpasswd -m yescrypt) && printf '"%s"' "$hash" |
     sops set --value-stdin secrets/shared.yaml '["steve-password"]'
   ```

   `updatekeys` removes the lost key's copy of the data key but keeps the data key itself, which the lost key may already have opened; `rotate` replaces it. The password has to change because the lost key still opens every old version of this file in git history, and this repo is public. Any other secret in the file needs changing at its source too, such as a token reissued. If nothing can decrypt the file any more, [rebuild it](#installing-a-host-when-no-machine-can-decrypt) with a new password instead: that does all three.

3. Remove its keys everywhere else they're trusted:
   - its `ssh-keys` in `modules/hosts/<host>.nix`, which every host trusts
   - its key in idn-primer's `access.nix`
   - its SSH key on GitHub, or it can still push to this repo
   - the machine itself, from the tailnet
   - its session in your password manager
4. Commit, push, and `just switch` on every remaining host, so the new password and key lists reach them.

### The emergency key is lost or exposed

A lost key may turn up in someone else's hands, so treat both the same.

1. Make a new one: [Set it up](#set-it-up), steps 1–2.
2. In `.sops.yaml`, replace the old `age1…` key under `&emergency` with the new one. To drop the emergency key altogether, delete the entry and its anchor instead.
3. On a machine that can still decrypt, run the commands of [A machine is lost or stolen](#a-machine-is-lost-or-stolen), step 2.
4. Test the new key ([Set it up](#set-it-up), step 5), then delete the old one from your password manager.
5. Commit, push, and `just switch` on every host that includes `sops`, so the new password applies.
