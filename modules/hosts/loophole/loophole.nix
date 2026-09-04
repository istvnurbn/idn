{den, ...}: {
  den.aspects.loophole = {
    includes = with den.aspects; [
      # WSL only
      wsl

      # Base
      nix
      overlays
      sudo
      openssh
      shell
      devel
      deploy-safety
    ];

    nixos.security.pki.certificateFiles = [
      ./certs/corporate.pem # Expires on 2035-09-03
      ./certs/zscaler.pem # Expires on 2042-05-06
    ];
  };
}
