# Base role: zsh (oh-my-zsh, autosuggestions, syntax highlighting) as login
# shell, keychain, and direnv with nix-direnv.
{
  # zsh becomes the login shell of the users given the base role.
  flake.modules.nixos.roles =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      baseUsers = lib.filterAttrs (_: roles: builtins.elem "base" roles) config.roles.users;
    in
    {
      programs.zsh.enable = lib.mkIf (baseUsers != { }) true;
      users.users = lib.mapAttrs (_: _: { shell = pkgs.zsh; }) baseUsers;
    };

  flake.modules.homeManager.base =
    { config, lib, ... }:
    {
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
    };
}
