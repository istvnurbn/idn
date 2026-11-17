{den, ...}: {
  den.aspects.claude = {
    # pkgs.unstable comes from the unstable aspect
    includes = [den.aspects.unstable];

    os = {
      lib,
      pkgs,
      ...
    }: {
      environment.systemPackages = with pkgs; [
        unstable.claude-code
        nodejs # plugin hooks run node, ponytail's among them
        # Started by the .mcp.json in idn and idn-primer. From unstable because
        # stable lagged far behind, without 26.05 for a long time.
        unstable.mcp-nixos
      ];

      # Claude writes its commands for bash. Under zsh, the login shell, they
      # trip on zsh's glob rules and on ~/.zshrc's aliases and zoxide cd.
      environment.variables.CLAUDE_CODE_SHELL = lib.getExe pkgs.bashInteractive;
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
