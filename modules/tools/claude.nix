{den, ...}: {
  den.aspects.claude = {
    # pkgs.unstable comes from the unstable aspect
    includes = [den.aspects.unstable];

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
