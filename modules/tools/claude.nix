{den, ...}: {
  den.aspects.claude = {
    # The desktop app; Claude Code and its tools are NixOS-only
    darwin.homebrew.casks = ["claude"];

    nixos = {
      host,
      lib,
      pkgs,
      ...
    }: {
      environment.systemPackages = with pkgs; [
        claude-code
        nodejs # plugin hooks run node, ponytail's among them
        mcp-nixos # started by the .mcp.json in idn and idn-primer
      ];

      environment.variables = {
        # Claude writes its commands for bash. Under zsh, the login shell, they
        # trip on zsh's glob rules and on ~/.zshrc's aliases and zoxide cd.
        CLAUDE_CODE_SHELL = lib.getExe pkgs.bashInteractive;

        # Claude Code keeps its main config in ~/.claude.json, outside ~/.claude,
        # and replaces it by rename, which a persisted single file does not
        # survive. On impermanent hosts, point it into the persisted directory.
        CLAUDE_CONFIG_DIR = lib.mkIf (host.hasAspect den.aspects.impermanence) "$HOME/.claude";
      };
    };

    persistHome = {
      directories = [
        ".claude"
      ];
    };
  };
}
