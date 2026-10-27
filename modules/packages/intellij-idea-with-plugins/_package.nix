# IntelliJ IDEA bundled with JetBrains Marketplace plugins, each at the latest
# version compatible with the IDE. Select them with
# `intellij-idea-with-plugins.override { pluginIds = [ ... ]; }`, and the IDE
# with `.override { intellij-idea = intellij-idea-oss; }`.
{
  lib,
  jetbrains,
  intellij-idea,
  # `pluginsForIde ide pluginIds` from nix-jetbrains-plugins.
  pluginsForIde,
  # JetBrains Marketplace plugin IDs.
  pluginIds ? [ ],
}:
jetbrains.plugins.addPlugins intellij-idea (lib.attrValues (pluginsForIde intellij-idea pluginIds))
