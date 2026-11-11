{den, ...}: {
  den.aspects.claude = {
    # pkgs.unstable comes from the overlays aspect
    includes = [den.aspects.overlays];

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
