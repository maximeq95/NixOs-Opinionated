# Base role: modern CLI tools. Its other files add the shell, git, Zellij,
# Starship and LazyVim.
{ config, ... }:
let
  inherit (config.flake.modules) homeManager;
in
{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      imports = [ homeManager.common ];

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

      programs.home-manager.enable = true;

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

      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
      };
    };
}
