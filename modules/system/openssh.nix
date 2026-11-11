{den, ...}: {
  # Each host aspect publishes its own keys under `ssh-keys`:
  #   ssh-keys.host = "<host public key>";             (optional)
  #   ssh-keys.users.<name> = "<that user's key on this host>";
  den.quirks.ssh-keys.description = "SSH public keys a host publishes to the fleet";

  # Every host sees every host's keys. collectAll rather than collect:
  # collect only reaches sibling scopes, which leaves out hexley (darwin).
  den.policies.ssh-roster = {host, ...}: [
    (den.lib.policy.pipe.from "ssh-keys" [
      (den.lib.policy.pipe.collectAll ({host, ...}: true))
      den.lib.policy.pipe.withProvenance
    ])
  ];
  den.schema.host.includes = [den.policies.ssh-roster];

  den.aspects.openssh = {user, ...}: {
    nixos = {
      lib,
      ssh-keys,
      ...
    }: {
      # Enable the OpenSSH daemon
      services.openssh = {
        enable = true;
        openFirewall = true;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
          AllowUsers = [user.name];
          MaxAuthTries = 3;
          # invaliduser covers names outside AllowUsers (root, admin, ...), which
          # sshd doesn't count as authfail
          PerSourcePenalties = "crash:3600s authfail:3600s invaliduser:3600s max:86400s";
          # Never lock out our own devices on the tailnet (Tailscale's IPv4 and
          # IPv6 ranges)
          PerSourcePenaltyExemptList = "100.64.0.0/10,fd7a:115c:a1e0::/48";
          X11Forwarding = false;
          # Skip slow/unreliable reverse-DNS lookups on connect
          UseDns = false;
          # Unbind stale forwarded sockets (e.g. gpg-agent) before rebinding
          StreamLocalBindUnlink = true;
        };

        # Only trust the root-managed authorized_keys.d (populated declaratively below)
        authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];

        # Fleet hosts that publish a host key, from the ssh-roster pipe
        knownHosts =
          lib.listToAttrs (map (e:
            lib.nameValuePair e.source.host.name {
              publicKey = e.value.host;
              extraHostNames = ["${e.source.host.name}.local"];
            }) (lib.filter (e: e.value ? host) ssh-keys))
          // {
            # Avoid a TOFU prompt on the first SSH-based git clone from a fresh host.
            "github.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
          };
      };

      # This user's key from every host in the fleet
      users.users.${user.name}.openssh.authorizedKeys.keys =
        lib.concatMap (e: lib.toList (e.value.users.${user.name} or [])) ssh-keys;
    };

    darwin = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        openssh
      ];
    };

    # Only the host keys: NixOS rewrites the rest of /etc/ssh on every boot,
    # and a persisted copy would hide it.
    persist = {
      files = [
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    };
  };
}
