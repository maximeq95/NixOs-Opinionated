# Flake-level plumbing: supported systems, and the published modules.
#
# Features contribute to `flake.modules.<class>.<name>`, the output dendritic
# flakes consume (several files may contribute to the same module). This is
# flake-parts' `flakeModules.modules`, plus a `key` on every module: a module
# imported several times (directly and through a platform module, say) is
# then imported once. `nixosModules` and `homeModules` publish the same
# modules under the classic output names.
{
  config,
  lib,
  moduleLocation,
  ...
}:
{
  options.flake.modules = lib.mkOption {
    type = with lib.types; lazyAttrsOf (lazyAttrsOf deferredModule);
    default = { };
    description = "Modules published by this flake, by class (`nixos`, `homeManager`) then name.";
    apply = lib.mapAttrs (
      class:
      lib.mapAttrs (
        name: module: {
          key = "nixos-roles#modules.${class}.${name}";
          _class = class;
          _file = "${toString moduleLocation}#modules.${class}.${name}";
          imports = [ module ];
        }
      )
    );
  };

  config = {
    systems = [ "x86_64-linux" ];

    flake = {
      nixosModules = config.flake.modules.nixos;
      homeModules = config.flake.modules.homeManager;
    };
  };
}
