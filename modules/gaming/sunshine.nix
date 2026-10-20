{
  den.aspects.sunshine = {
    nixos = {
      services.sunshine = {
        enable = true;
        autoStart = true;
        capSysAdmin = true;
        openFirewall = true;
        settings = {
          sunshine_name = "Sunshine";
          locale = "en";
          origin_web_ui_allowed = "lan";
          lan_encryption_mode = 0;
          capture = "kms";
          min_threads = 6;
          encoder = "vulkan";
          vk_tune = 2;
        };
      };
    };

    persistHome = {
      directories = [
        ".config/sunshine"
      ];
    };
  };
}
