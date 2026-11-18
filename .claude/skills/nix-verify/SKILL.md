---
name: nix-verify
description: >
  Prove what a change to this flake does to every host and VM test: drvPaths
  before vs after, nix flake check, and what is still pending on the other
  machine. Use after editing Nix files in idn, before calling the work done or
  writing its commit message, and whenever the user asks to check, verify or
  prove a change.
---

Identical drvPath means identical system: that is the bar for a refactor. For an intended change, every changed check needs a reason. Run everything with bash from the repo root.

## 1. Snapshot

`snapshot.nix`, next to this file, prints the drvPath of every `checks.<system>.<name>`: `host-<name>` is that host's toplevel, `vm-*` are the VM tests. Each run takes about a minute.

```bash
R=$(git rev-parse --show-toplevel) S=<scratchpad>/nix-verify; mkdir -p "$S"
nix eval --json --impure --expr "import $R/.claude/skills/nix-verify/snapshot.nix \"git+file://$R?rev=$(git rev-parse HEAD)\"" >"$S/before.json" 2>"$S/before.err"
nix eval --json --impure --expr "import $R/.claude/skills/nix-verify/snapshot.nix \"$R\"" >"$S/after.json" 2>"$S/after.err"
```

- **Baseline.** About to edit? Snapshot `"$R"` as `before` first, so other uncommitted changes in the tree don't count. Already edited: use HEAD as above, and say so if `git status` shows uncommitted changes that aren't part of this change.
- **New files.** The flake only sees files git knows. If `git status --short` shows `??` on a `.nix` file the change needs, `git add -N` it and snapshot `after` again.

## 2. Compare

```bash
jq -rn --slurpfile b "$S/before.json" --slurpfile a "$S/after.json" '
  ($b + $a | map([paths(strings)]) | add | unique)[] as $p
  | [($b[0] | getpath($p)), ($a[0] | getpath($p))] as [$x, $y]
  | (if $x == $y then "same" elif $x == null then "added" elif $y == null then "removed" else "CHANGED" end) + "\t" + ($p | join("."))'
diff <(grep -i warning "$S/before.err") <(grep -i warning "$S/after.err")   # new eval warnings
```

Find the cause of any change that isn't plainly the intended one. Step 1 put every system's `.drv` files in the local store, so this works for Linux hosts on the Mac too:

```bash
nix run --inputs-from . nixpkgs#nix-diff -- --color never <before .drv> <after .drv> | head -80
```

## 3. Check

`nix flake check --no-update-lock-file`: `just check` without lock-file writes. It builds this machine's platform only (`host-*`, `treefmt`, `check-flake-file`, and on Linux the VM tests).

## 4. Report

1. A table: check, then same / CHANGED / added / removed, and for each change why: intended (say how), or the nix-diff cause.
2. New warnings, or "none".
3. `nix flake check`: passed, or the error.
4. **Pending**: the changed or added checks of the other platform, as one command to run there after pulling. x86_64-linux builds on vermilion, aarch64-darwin on hexley. Nothing changed there: say "nothing pending".

   ```bash
   nix build -L --no-link .#checks.x86_64-linux.host-vermilion .#checks.x86_64-linux.vm-server
   ```

Don't SSH to the other machine unless the user asks. For a commit message, use the caveman-commit skill.
