{den, ...}: {
  den.aspects.shell = {
    # pkgs.unstable comes from the unstable aspect
    includes = [den.aspects.unstable];

    os = {pkgs, ...}: {
      # Configure zsh as an interactive shell
      programs.zsh = {
        enable = true;
        enableGlobalCompInit = false; # ~/.zshrc runs compinit itself
        promptInit = ""; # skip the default `prompt suse`; Pure replaces it
      };

      environment.systemPackages = with pkgs; [
        atuin
        bat
        btop
        curl
        fastfetch
        fzf
        git
        just
        mc
        mmv
        msedit # just for the fun of it
        pv
        ripgrep
        rsync
        tree
        wget
        xdg-utils
        zoxide

        # zsh plugins; ~/.zshrc loads them from /run/current-system/sw
        zsh-autosuggestions
        zsh-completions
        zsh-fast-syntax-highlighting
        zsh-fzf-tab
      ];

      # zsh-fzf-tab installs to share/fzf-tab, outside the share/zsh that is linked
      environment.pathsToLink = ["/share/fzf-tab"];
    };

    # Pure 1.28+ for prompt_pure_precustom, which ~/.zshrc uses. Stable NixOS
    # hosts (loophole) fall back to unstable's until their pkgs has it.
    nixos = {
      lib,
      pkgs,
      ...
    }: {
      environment.systemPackages = [
        (
          if lib.versionAtLeast pkgs.pure-prompt.version "1.28"
          then pkgs.pure-prompt
          else pkgs.unstable.pure-prompt
        )
      ];
    };

    darwin = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        coreutils
        gnutar # macOS tar fails me sometimes
        nano
        unstable.pure-prompt # see nixos above
      ];
    };

    persistHome = {
      directories = [
        ".local/share/atuin"
        ".local/share/zoxide"
      ];
      files = [
        ".config/btop/btop.conf"
      ];
    };
  };
}
