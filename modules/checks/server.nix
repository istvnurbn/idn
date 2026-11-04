# Server VM tests: the aspects headless servers share, booted next to a
# client machine. vm-server is the baseline every server gets;
# vm-internet-facing adds the hardening for publicly reachable boxes.
# Hardware, disks and bootloaders stay out: the VM boots its kernel directly.
#
#   nix build .#checks.x86_64-linux.vm-server -L
#   nix run .#checks.x86_64-linux.vm-server.driverInteractive
{
  den,
  inputs,
  lib,
  ...
}: let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  keys = import "${pkgs.path}/nixos/tests/ssh-keys.nix" pkgs;
  vmTest = import ./_vm-test.nix {inherit inputs lib;};

  # The client's key, next to the real ones, for every user sshd lets in
  clientKey = {config, ...}: {
    users.users = lib.genAttrs config.services.openssh.settings.AllowUsers (_: {
      openssh.authorizedKeys.keys = [keys.snakeOilEd25519PublicKey];
    });
  };

  # What every server must do. The script reads names from the machine, but
  # expectations are declared here: a server that loses its hardening fails
  # instead of skipping a subtest.
  serverTest = {lockedModules}:
    vmTest {
      users.steve = {};
      nodes.client = {};
      extraModules = [clientKey];

      testScript = {nodes, ...}: let
        host = nodes.machine.networking.hostName;
        user = lib.head nodes.machine.services.openssh.settings.AllowUsers;
        homes = lib.attrNames (nodes.machine.home-manager.users or {});
      in ''
        # -n keeps ssh off stdin: that's the VM console the driver sends its
        # commands over, and ssh would swallow them
        ssh = "${pkgs.openssh}/bin/ssh -n -i /root/key -o BatchMode=yes -o StrictHostKeyChecking=no"

        start_all()
        machine.wait_for_unit("multi-user.target")
        ${lib.concatMapStrings (home: "machine.wait_for_unit(\"home-manager-${home}.service\")\n") homes}
        ${lib.optionalString lockedModules ''
          with subtest("kernel modules are locked after boot"):
              machine.wait_for_unit("disable-kernel-module-loading.service")
              assert machine.succeed("cat /proc/sys/kernel/modules_disabled").strip() == "1"
        ''}
        with subtest("the firewall drops ports nobody opened"):
            machine.succeed("systemd-run --unit=probe ${pkgs.python3}/bin/python3 -m http.server 8080")
            machine.wait_for_open_port(8080)
            client.fail("curl --max-time 3 http://${host}:8080")

        client.succeed("install -m 600 ${keys.snakeOilEd25519PrivateKey} /root/key")
        machine.wait_for_unit("sshd.service")

        with subtest("${user} logs in with a key"):
            client.succeed(f"{ssh} ${user}@${host} true")

        with subtest("root is refused, and keys are the only method offered"):
            out = client.fail(f"{ssh} root@${host} true 2>&1")
            # repr: ssh ends its messages in \r\n, and the build log drops
            # everything before a carriage return
            assert "Permission denied (publickey)" in out, repr(out)

        with subtest("one failed login locks the client out (PerSourcePenalties)"):
            client.wait_until_fails(f"{ssh} ${user}@${host} true", timeout=30)
      '';
    };

  # What every server shares: loophole's base aspects plus server-base
  shared = with den.aspects; [server-base nix overlays sudo openssh shell deploy-safety];
in {
  den.hosts.x86_64-linux.vm-server = serverTest {lockedModules = false;};
  den.aspects.vm-server.includes = shared;

  den.hosts.x86_64-linux.vm-internet-facing = serverTest {lockedModules = true;};
  den.aspects.vm-internet-facing.includes = shared ++ [den.aspects.server-internet-facing];
}
