{
  den.aspects.audio = {
    nixos = {
      # Enable sound with pipewire.
      services = {
        pulseaudio.enable = false;

        pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          # Uncomment the following line if you want to use JACK applications
          # jack.enable = true;
        };
      };

      security.rtkit.enable = true;
    };
  };
}
