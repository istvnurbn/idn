{den, ...}: {
  den.aspects.loophole = {
    includes = with den.aspects; [
      # WSL only
      wsl

      # Base
      nix
      sudo
      openssh
      shell
      devel
      deploy-safety
    ];

    # No ssh-keys here: a key on this company laptop mustn't log in to the
    # fleet (system/openssh.nix), where sudo asks no password

    nixos.security.pki.certificateFiles = [
      ./certs/corporate.pem # Expires on 2035-09-03
      ./certs/zscaler.pem # Expires on 2042-05-06
    ];
  };
}
