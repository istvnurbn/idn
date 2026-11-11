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

    # Claude Code keeps its main config in ~/.claude.json, outside ~/.claude,
    # and replaces it by rename, which a persisted single file does not
    # survive. On impermanent hosts, point it into the persisted directory.
    nixos = {
      host,
      lib,
      ...
    }:
      lib.mkIf (host.hasAspect den.aspects.impermanence) {
        environment.variables.CLAUDE_CONFIG_DIR = "$HOME/.claude";
      };

    persistHome = {
      directories = [
        ".claude"
      ];
    };
  };
}
