# IntelliJ IDEA with JetBrains Marketplace plugins, resolved by
# nix-jetbrains-plugins against the packaged IDE version.
{ inputs, ... }:
{
  flake.overlays.intellij-idea-with-plugins = final: _prev: {
    intellij-idea-with-plugins = final.callPackage ./_package.nix {
      pluginsForIde = inputs.nix-jetbrains-plugins.lib.pluginsForIde final;
    };
  };
}
