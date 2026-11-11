{den, ...}: {
  den.aspects.loophole = {
    includes = with den.aspects; [
      # WSL only
      wsl

      # Base
      nix
      unstable
      sudo
      openssh
      shell
      devel
      sops
      deploy-safety
    ];

    # Published to the fleet's SSH roster (see system/openssh.nix)
    ssh-keys.users.steve = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO+ge++JIgIQHrr14P1u0K+rF/NzfaTiBz+TRMmUfMHO steve@loophole";

    nixos.security.pki.certificateFiles = [
      ./certs/corporate.pem # Expires on 2035-09-03
      ./certs/zscaler.pem # Expires on 2042-05-06
    ];
  };
}
