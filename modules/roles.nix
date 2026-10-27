# Roles: sets of Home Manager settings a user gets through
# `opinionated.users.<name>.roles`. A role registers itself in
# `opinionated.roles.<role>`, which declares the Home Manager option
# `opinionated.roles.<role>.enable`; its files contribute their settings to
# `flake.modules.homeManager.roles`, guarded by that option.
{ config, lib, ... }:
{
  options.opinionated.roles = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.description = lib.mkOption {
          type = lib.types.str;
          description = "What the role provides, shown in its `enable` option.";
        };
      }
    );
    default = { };
    description = "The roles, by name.";
  };

  config.flake.modules.homeManager.roles.options.opinionated.roles = lib.mapAttrs (name: role: {
    enable = lib.mkEnableOption "the ${name} role (${role.description})";
  }) config.opinionated.roles;
}
