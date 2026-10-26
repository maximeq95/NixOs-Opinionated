# Base role: shell (zsh, starship, zellij), git, modern CLI tools and LazyVim.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.opinionated.roles.base;
in
{
  imports = [ ./starship.nix ];

  options.opinionated.roles.base = {
    enable = lib.mkEnableOption "the base role (shell, git, CLI tools, LazyVim)";

    git = {
      userName = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Git author name.";
      };
      userEmail = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Git author email.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      lazyssh
      any-nix-shell
      nom
      up
      nixfmt
      jq
      fzf
      ripgrep
      fd
      bat
    ];

    home.sessionVariables.EDITOR = "nvim";

    programs.home-manager.enable = true;

    # LazyVim, wired through Nix: plugins are injected as pinned `dev` specs
    # pointing at store paths, treesitter parsers are prebuilt, and Mason is
    # disabled (its prebuilt binaries cannot run outside an FHS environment).
    # Consequences: `~/.config/nvim` is read-only and `:Lazy update` does
    # nothing; plugins move when `lazyvim` is updated in flake.lock.
    # Other roles add their own extras and extraPackages.
    programs.lazyvim = {
      enable = true;

      # LSP servers, formatters and linters that LazyVim would otherwise expect
      # Mason to provide. They land on neovim's wrapper PATH, not in the profile.
      extraPackages = with pkgs; [
        nil
        yaml-language-server
        lua-language-server
        stylua
      ];

      extras.lang = {
        nix.enable = true;
        json = {
          enable = true;
          installDependencies = true;
        };
        yaml.enable = true;
        markdown = {
          enable = true;
          installDependencies = true;
          installRuntimeDependencies = true;
        };
      };
    };

    programs.neovim = {
      viAlias = true;
      vimAlias = true;
    };

    programs.zellij = {
      enable = true;
      enableZshIntegration = true;
      plugins = with pkgs.zellijPlugins; [ autolock ];
      settings = {
        theme = "catppuccin-mocha";
        show_startup_tips = false;
      };
      attachExistingSession = true;
    };

    # Modern replacement for `ls`; provides the ls/ll/la/lt aliases.
    programs.eza = {
      enable = true;
      enableZshIntegration = true;
      git = true;
      icons = "auto";
    };

    # Smarter `cd`: tracks visited directories and jumps via frecency (`z foo`).
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.git = {
      enable = true;
      settings = {
        user = lib.filterAttrs (_: v: v != null) {
          name = cfg.git.userName;
          email = cfg.git.userEmail;
        };
        core.autocrlf = "input";
        push.autoSetupRemote = true;
        pull.rebase = true;
      };
    };

    # Syntax-highlighted, side-by-side diffs as git's pager (diff/log/show/blame).
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
    };

    programs.keychain = {
      enable = true;
      enableZshIntegration = true;
      extraFlags = [ "--quiet" ];
    };

    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      enableCompletion = true;
      # Runs after the starship, keychain and direnv hooks (order 1000).
      initContent = lib.mkOrder 1100 ''
        any-nix-shell zsh | source /dev/stdin
        export GIT_AUTO_FETCH_INTERVAL=120 # in seconds
      '';

      history = {
        size = 50000;
        save = 50000;
        path = "${config.xdg.dataHome}/zsh/zsh_history";
        expireDuplicatesFirst = true;
        ignoreDups = true;
        ignoreSpace = true;
        share = true;
      };

      oh-my-zsh = {
        enable = true;
        # Starship provides the prompt (through its own zsh integration, so
        # the oh-my-zsh "starship" plugin must not be loaded as well).
        theme = "";
        # Other roles append their own plugins.
        plugins = [
          "git"
          "ssh"
          "direnv"
          "git-prompt"
          "git-auto-fetch"
        ];
      };

      shellAliases = {
        cat = "bat --paging=never";
        ".." = "cd ..";
        "..." = "cd ../..";
      };
    };

    # Per-directory environments. `nix-direnv` replaces direnv's own `use nix`
    # with a caching implementation that keeps the built shell alive as a GC
    # root, so re-entering a project directory does not re-evaluate the flake.
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
      # The prompt already reports the direnv state, so the export list
      # printed on every directory change is suppressed.
      silent = true;
    };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
