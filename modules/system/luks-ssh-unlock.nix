# Fallback unlock over SSH from the initrd, for when the local display or
# keyboard doesn't come up. The TPM and the console prompt keep working;
# whichever answers first unlocks the disk. Desktops only: servers stay
# unencrypted, so they never need it.
#
#   ssh -p 2222 root@<host>    # lands straight in the passphrase prompt
#
# The initrd only gets wired Ethernet with DHCP (no Wi-Fi, no Tailscale), so
# this works from the LAN. The host's NIC driver has to be in its
# boot.initrd.availableKernelModules (see hosts/vermilion.nix).
#
# The initrd sits on the unencrypted ESP, so its host key is readable by
# anyone with the disk: use a dedicated key, never the real host key.
# Create it before the first switch/install (the boot loader copies it):
#   sudo install -d -m 700 <dir> && sudo ssh-keygen -t ed25519 -N "" -f <dir>/ssh_host_ed25519_key
{den, ...}: {
  den.aspects.luks-ssh-unlock.includes = with den.aspects; [
    # The prompt this forwards
    luks
    # userKeys below are the keys openssh.nix authorizes
    openssh
  ];

  den.aspects.luks-ssh-unlock.nixos = {
    config,
    host,
    lib,
    ...
  }: let
    keyDir =
      if host.hasAspect den.aspects.impermanence
      then "/persist/etc/secrets/initrd"
      else "/etc/secrets/initrd";
    # The keys allowed to log in normally (see openssh.nix)
    userKeys = lib.concatMap (u: u.openssh.authorizedKeys.keys) (lib.attrValues config.users.users);
  in {
    boot.initrd = {
      # DHCP on wired interfaces. The initrd knows the hostname, so a router
      # that registers DHCP names resolves it.
      systemd.network = {
        enable = true;
        networks."10-initrd-ethernet" = {
          matchConfig = {
            Type = "ether";
            Kind = "!*";
          };
          networkConfig.DHCP = "yes";
        };
      };
      # NetworkManager takes over in stage 2; don't leave the initrd's lease behind
      network.flushBeforeStage2 = true;

      network.ssh = {
        enable = true;
        # Own port, so this host key doesn't clash with the real one in known_hosts
        port = 2222;
        hostKeys = ["${keyDir}/ssh_host_ed25519_key"];
        # These logins can only answer the passphrase prompt
        authorizedKeys = map (k: ''restrict,pty,command="/bin/systemd-tty-ask-password-agent" ${k}'') userKeys;
      };
    };
  };
}
