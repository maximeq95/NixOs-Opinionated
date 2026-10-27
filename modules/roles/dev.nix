# Dev role: IntelliJ IDEA (with plugins) and Java tooling for LazyVim.
{ config, ... }:
let
  inherit (config.flake.modules) homeManager;
in
{
  flake.modules.homeManager.dev =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.roles.dev;
    in
    {
      imports = [ homeManager.common ];

      options.roles.dev.intellij = {
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

      config = lib.mkMerge [
        {
          programs.lazyvim.extraPackages = [ pkgs.jdt-language-server ];
          roles.dev.intellij.plugins = [ "com.intellij.plugins.watcher" ];
        }
        (lib.mkIf cfg.intellij.enable {
          # From `overlays.default`.
          home.packages = [
            (pkgs.intellij-idea-with-plugins.override {
              pluginIds = lib.unique cfg.intellij.plugins;
            })
          ];
          roles.unfreePackages = [
            "intellij-idea"
            "intellij-idea-with-plugins"
          ];
        })
      ];
    };
}
