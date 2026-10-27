# Flake-level plumbing: supported systems, and the published modules.
#
# Features contribute to `flake.modules.<class>.<name>` (several files may
# contribute to the same module); `nixosModules` and `homeModules` publish
# them with a `key`, so the module system deduplicates a module imported
# several times, e.g. the core shared by every platform module.
{
  config,
  inputs,
  lib,
  ...
}:
let
  keyed = output: name: module: {
    key = "nixos-opinionated#${output}.${name}";
    imports = [ module ];
  };
in
{
  imports = [
    inputs.flake-parts.flakeModules.modules
    inputs.home-manager.flakeModules.home-manager
  ];

  systems = [ "x86_64-linux" ];

  flake = {
    nixosModules = lib.mapAttrs (keyed "nixosModules") config.flake.modules.nixos;
    homeModules = lib.mapAttrs (keyed "homeModules") config.flake.modules.homeManager;
  };
}
