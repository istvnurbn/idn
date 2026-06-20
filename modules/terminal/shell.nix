{
  den.aspects.shell = {
    os = { pkgs, ... }: {
      # Configure zsh as an interactive shell
      programs.zsh.enable = true;

      environment.systemPackages = with pkgs; [
        fzf
        zoxide
        bat
        mc
        wget
        curl
      ];
    };
  };
}
