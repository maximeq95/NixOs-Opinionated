# IntelliJ IDEA with JetBrains Marketplace plugins, resolved by
# nix-jetbrains-plugins against the packaged IDE version.
{ inputs, lib, ... }:
{
  flake.overlays.intellij-idea-with-plugins = final: _prev: {
    intellij-idea-with-plugins = lib.callPackageWith (
      final
      // {
        pluginsForIde = inputs.nix-jetbrains-plugins.lib.pluginsForIde final;
      }
    ) ../../pkgs/intellij-idea-with-plugins/package.nix { };
  };
}
