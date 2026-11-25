# Turns a Den host into a check-only disko install test: disko's
# system.build.installTest formats the host's layout on empty disks, installs
# the host onto them and boots it, all in one VM test that lands in
# checks.<system>.<host name>. Used by modules/checks/install.nix; the leading
# underscore keeps import-tree from loading it as a module.
#
# Every test checks the booted mounts against the layout aspects' own disko
# declaration (modules/system/disko.nix), then runs its extraChecks.
{
  inputs,
  lib,
}: {
  users ? {},
  extraChecks ? "",
  bootCommands ? "",
  extraModules ? [],
}: {config, ...}: let
  layoutChecks = {config, ...}: let
    # Mounts and swapfiles as the disko declaration has them; a LUKS
    # partition's content is mounted from its mapper device
    mountsOf = device: c:
      if c.type == "luks"
      then mountsOf "/dev/mapper/${c.name}" c.content
      else if c.type == "btrfs"
      then
        lib.optional (c.mountpoint != null) {
          target = c.mountpoint;
          inherit device;
          fstype = "btrfs";
          subvol = null;
          options = c.mountOptions;
        }
        ++ lib.concatMap (s:
          lib.optional (s.mountpoint != null) {
            target = s.mountpoint;
            inherit device;
            fstype = "btrfs";
            subvol = s.name;
            options = s.mountOptions;
          }) (lib.attrValues c.subvolumes)
      else if c.type == "filesystem" && c.mountpoint != null
      then [
        {
          target = c.mountpoint;
          inherit device;
          fstype = c.format;
          subvol = null;
          options = c.mountOptions;
        }
      ]
      else [];
    mounts = lib.concatMap (disk:
      lib.concatMap (p: lib.optionals (p.content != null) (mountsOf p.device p.content))
      (lib.attrValues disk.content.partitions))
    (lib.attrValues config.disko.devices.disk);
  in {
    disko.tests = {
      inherit bootCommands;
      extraChecks = ''
        import json

        layout = {m["target"]: m for m in json.loads(r"""${builtins.toJSON mounts}""")}
        swapfiles = json.loads(r"""${builtins.toJSON (map (s: s.device) config.swapDevices)}""")

        def same_subvol(a, b):
            return a.lstrip("/") == b.lstrip("/")

        with subtest("the mounts match the layout"):
            for target, want in layout.items():
                machine.wait_until_succeeds(f"mountpoint -q {target}", timeout=60)
                got = json.loads(machine.succeed(f"findmnt -J -o SOURCE,FSTYPE,FSROOT -M {target}"))["filesystems"][0]
                source = got["source"].split("[")[0]
                source_dev, want_dev = machine.succeed(f"readlink -f {source} {want['device']}").split()
                assert source_dev == want_dev, f"{target} is on {source}, not {want['device']}"
                assert got["fstype"] == want["fstype"], f"{target} is {got['fstype']}, not {want['fstype']}"
                fsroot = "/" + want["subvol"].lstrip("/") if want["subvol"] else "/"
                assert got["fsroot"] == fsroot, f"{target} mounts {got['fsroot']}, not {fsroot}"
            active = machine.succeed("swapon --show=NAME --noheadings").split()
            for swapfile in swapfiles:
                assert swapfile in active, f"{swapfile} isn't swapped on: {active}"

        with subtest("fstab names each subvolume once (F-12)"):
            for line in machine.succeed("cat /etc/fstab").splitlines():
                fields = line.split()
                if line.startswith("#") or len(fields) < 4 or fields[2] != "btrfs":
                    continue
                want = layout.get(fields[1])
                assert want, f"not in the layout: {line}"
                options = fields[3].split(",")
                subvols = [o.removeprefix("subvol=") for o in options if o.startswith("subvol=")]
                if want["subvol"]:
                    assert len(subvols) == 1 and same_subvol(subvols[0], want["subvol"]), f"want subvol={want['subvol']} once: {line}"
                else:
                    assert subvols == [], f"a whole-filesystem mount has no subvol=: {line}"
                missing = [o for o in want["options"] if o not in options]
                assert not missing, f"{missing} missing: {line}"
            # What the kernel mounted, as NC-01 checks on vermilion
            assert "subvol=/root" in machine.succeed("findmnt -no OPTIONS /").strip().split(",")

        ${extraChecks}
      '';
    };
  };
in {
  inherit users;
  intoAttr = ["checks" config.system config.name];

  instantiate = args:
    (inputs.nixpkgs.lib.nixosSystem (args
      // {
        modules =
          args.modules
          ++ extraModules
          ++ [
            layoutChecks
            # The nix aspect puts the repo itself in the registry, which
            # would re-run every test on every commit
            {nix.registry = lib.mkForce {};}
          ];
      }))
    .config
    .system
    .build
    .installTest;
}
