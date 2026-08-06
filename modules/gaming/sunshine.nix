{
  den.aspects.sunshine = {user, ...}: {
    nixos = {
      services.sunshine = {
        enable = true;
        autoStart = true;
        capSysAdmin = false;
        openFirewall = true;
        settings = {
          sunshine_name = "Sunshine";
          locale = "en";
          origin_web_ui_allowed = "lan";
          lan_encryption_mode = 0;
          capture = "kwin";
          min_threads = 6;
          encoder = "vulkan";
          vk_tune = 2;
        };
      };
    };

    impermanence = {
      users.${user.name} = {
        directories = [
          ".config/sunshine"
        ];
      };
    };
  };
}
