{
  den.aspects.claude = {
    os = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        unstable.claude-code
      ];
    };

    darwin.homebrew.casks = ["claude"];

    persistHome = {
      directories = [
        ".claude"
      ];
    };
  };
}
