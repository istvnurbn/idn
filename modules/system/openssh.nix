{den, ...}: {
  den.aspects.openssh = {
    host,
    user,
    ...
  }: {
    nixos = {lib, ...}: {
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
          PerSourcePenalties = "crash:3600s authfail:3600s max:86400s";
          X11Forwarding = false;
          # Skip slow/unreliable reverse-DNS lookups on connect
          UseDns = false;
          # Unbind stale forwarded sockets (e.g. gpg-agent) before rebinding
          StreamLocalBindUnlink = true;
        };

        # Only trust the root-managed authorized_keys.d (populated declaratively below)
        authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];

        knownHosts = {
          vermilion = {
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIfJ4iMClvTaqIYrMZNdro5oGSLk8LYG8awsuZyez7O5";
            extraHostNames = ["vermilion.local"];
          };

          # Avoid a TOFU prompt on the first SSH-based git clone from a fresh host.
          "github.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
        };

        # Default host keys, rooted under /persist when the impermanence
        # aspect is present so they survive the root wipe.
        hostKeys = let
          dir =
            if host.hasAspect den.aspects.impermanence
            then "/persist/etc/ssh"
            else "/etc/ssh";
        in [
          {
            path = "${dir}/ssh_host_ed25519_key";
            type = "ed25519";
          }
          {
            bits = 4096;
            openSSHFormat = true;
            path = "${dir}/ssh_host_rsa_key";
            type = "rsa";
          }
        ];
      };

      users.users.${user.name}.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMDFAQW9uPhDsi+CiCxfwon12iT0Earea6CznTniv1Ta steve@vermilion"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG9mUymT0rLNsntCzJp7Na4Rwj9fAMgfh1oSYmXuRvRK steve@hexley"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO+ge++JIgIQHrr14P1u0K+rF/NzfaTiBz+TRMmUfMHO steve@loophole"
      ];
    };

    darwin = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        openssh
      ];
    };

    impermanence = {
      directories = [
        "/etc/ssh"
      ];
    };
  };
}
