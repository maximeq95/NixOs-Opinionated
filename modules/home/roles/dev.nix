# Dev role: IntelliJ IDEA (with plugins) and Java tooling for LazyVim.
{
  config,
  lib,
  pkgs,
  opinionatedInputs,
  ...
}:
let
  cfg = config.opinionated.roles.dev;
in
{
  options.opinionated.roles.dev = {
    enable = lib.mkEnableOption "the dev role (IntelliJ IDEA, Java tooling)";

    intellij = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to install IntelliJ IDEA.";
      };
      plugins = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "com.intellij.plugins.watcher" ];
        description = ''
          JetBrains Marketplace plugin IDs bundled with IntelliJ IDEA, each at
          the latest version compatible with the packaged IDE. Other roles
          append to this list.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        programs.lazyvim.extraPackages = [ pkgs.jdt-language-server ];
        opinionated.roles.dev.intellij.plugins = [ "com.intellij.plugins.watcher" ];
      }
      (lib.mkIf cfg.intellij.enable {
        home.packages = [
          (opinionatedInputs.nix-jetbrains-plugins.lib.buildIdeWithPlugins pkgs "idea" (
            lib.unique cfg.intellij.plugins
          ))
        ];
        opinionated.unfreePackages = [
          "idea"
          "intellij-idea"
          "intellij-idea-with-plugins"
          "idea-with-plugins"
        ];
      })
    ]
  );
}
