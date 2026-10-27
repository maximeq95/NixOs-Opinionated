# Roles of the users: each user of `roles.users` gets Home Manager with the
# modules of their roles, `flake.modules.homeManager.<role>`.
{ config, inputs, ... }:
let
  inherit (config.flake) overlays;
  inherit (config.flake.modules) nixos;
  # Every Home Manager module of this flake is a role, except the one the
  # roles share.
  roles = removeAttrs config.flake.modules.homeManager [ "common" ];
  roleNames = builtins.attrNames roles;
in
{
  flake.modules.nixos.roles =
    { config, lib, ... }:
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        nixos.unfree
      ];

      options.roles.users = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf (lib.types.enum roleNames));
        default = { };
        example = {
          alice = [
            "base"
            "ops"
          ];
        };
        description = ''
          Roles of each user, who gets a Home Manager configuration importing
          them. Available roles: ${lib.concatStringsSep ", " roleNames}. Role
          options, like any other Home Manager setting, go in
          `home-manager.users.<name>`.
        '';
      };

      config = {
        # Shared with Home Manager through `home-manager.useGlobalPkgs`.
        nixpkgs.overlays = [ overlays.default ];

        home-manager = {
          useGlobalPkgs = lib.mkDefault true;
          useUserPackages = lib.mkDefault true;
          backupFileExtension = lib.mkDefault "hm-backup";

          users = lib.mapAttrs (_: userRoles: {
            imports = map (role: roles.${role}) userRoles;
            home.stateVersion = lib.mkDefault config.system.stateVersion;
          }) config.roles.users;
        };
      };
    };
}
