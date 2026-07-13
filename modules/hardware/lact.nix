{
  den.aspects.lact = {
    nixos = {
      # Enable LACT, a tool for monitoring, configuring and overclocking GPUs
      services.lact.enable = true;
    };
  };
}
