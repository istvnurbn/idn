# Extra hardening for servers reachable from the open internet, on top of server-base.nix.
{
  den.aspects.server-internet-facing.nixos = {lib, ...}: {
    boot.kernel.sysctl = {
      # Reverse-path filtering: drop packets whose source address wouldn't
      # be routed back out the interface they arrived on (anti-spoofing).
      "net.ipv4.conf.all.rp_filter" = lib.mkDefault 1;
      "net.ipv4.conf.default.rp_filter" = lib.mkDefault 1;

      # Don't let the network tell us to change our routes (MITM vector),
      # and don't act as a relay for source-routed packets.
      "net.ipv4.conf.all.accept_redirects" = lib.mkDefault 0;
      "net.ipv4.conf.all.send_redirects" = lib.mkDefault 0;
      "net.ipv4.conf.all.accept_source_route" = lib.mkDefault 0;
      "net.ipv6.conf.all.accept_redirects" = lib.mkDefault 0;
      "net.ipv6.conf.all.accept_source_route" = lib.mkDefault 0;

      # SYN flood protection. Likely already the kernel default; set
      # explicitly so the intent is documented.
      "net.ipv4.tcp_syncookies" = lib.mkDefault 1;

      # Reduce kernel info leakage to unprivileged processes.
      "kernel.dmesg_restrict" = lib.mkDefault 1;
      "kernel.kptr_restrict" = lib.mkDefault 2;
    };

    security.protectKernelImage = true;

    # Blocks runtime module loading/unloading after boot. Safe on most cloud
    # VMs, but verify against a real boot before relying on it — if
    # something needs to lazy-load a module later, add it to
    # boot.kernelModules first.
    security.lockKernelModules = true;
  };
}
