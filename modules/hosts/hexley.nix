{den, ...}: {
  den.aspects.hexley = {
    includes = with den.aspects; [
      # For macOS only
      nix-darwin
      darwin-defaults

      # Base
      nix
      unstable
      networking
      sudo
      openssh
      shell
      tailscale

      # Misc. shell
      devel
      media-cli

      # Desktop
      desktop-base
      fonts
      firefox
      helium
      tor
      media
      claude

      # Services
      docker
    ];

    # Published to the fleet's SSH roster (see system/openssh.nix)
    ssh-keys.users.steve = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG9mUymT0rLNsntCzJp7Na4Rwj9fAMgfh1oSYmXuRvRK steve@hexley";

    darwin.system = {
      # Disable the startup chime
      startup.chime = false;

      defaults = {
        dock.persistent-apps = [
          "/Applications/Firefox.app"
          "/Applications/Proton Mail.app"
          "/System/Applications/Mail.app"
          "/System/Applications/Messages.app"
          "/System/Applications/Calendar.app"
          "/System/Applications/Notes.app"
          "/System/Applications/Reminders.app"
          "/System/Applications/Photos.app"
          "/Applications/Ghostty.app"
        ];
      };
    };
  };
}
