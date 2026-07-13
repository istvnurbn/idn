{den, ...}: {
  den.aspects.hexley = {
    includes = with den.aspects; [
      # For macOS only
      nix-darwin
      nix-homebrew
      darwin-security
      darwin-defaults
      darwin-privacy

      # Base
      nix
      overlays
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

      # Services
      docker
    ];

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
        trackpad = {
          # Enable tap to click
          Clicking = true;

          # Disable tap to drag
          Dragging = false;
        };
      };
    };
  };
}
