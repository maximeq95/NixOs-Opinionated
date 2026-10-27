# Home Manager integration and role-based user declarations.
{ roles, homeModule }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.opinionated;
  hasBase = user: builtins.elem "base" user.roles;

  userModule =
    { name, ... }:
    {
      options = {
        roles = lib.mkOption {
          type = lib.types.listOf (lib.types.enum roles.names);
          default = [ "base" ];
          example = [
            "base"
            "ops"
            "dev"
          ];
          description = ''
            Home Manager roles enabled for this user. Available roles:
            ${lib.concatStringsSep ", " roles.names}. Role-specific options
            are set through `home-manager.users.<name>.opinionated.roles.<role>`.
          '';
        };

        git = {
          userName = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Git author name (used by the `base` role).";
          };
          userEmail = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Git author email (used by the `base` role).";
          };
        };

        homeDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/home/${name}";
          description = "Home directory of the user.";
        };
      };
    };
in
{
  options.opinionated = {
    home.enable = lib.mkOption {
      type = lib.types.bool;
      default = cfg.users != { };
      defaultText = lib.literalExpression "config.opinionated.users != { }";
      description = "Whether to configure Home Manager with the opinionated defaults and roles.";
    };

    users = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule userModule);
      default = { };
      example = lib.literalExpression ''
        {
          alice = {
            roles = [ "base" "ops" ];
            git = { userName = "Alice"; userEmail = "alice@example.com"; };
          };
        }
      '';
      description = "Users managed by Home Manager, with the roles they get.";
    };
  };

  config = lib.mkIf cfg.home.enable {
    home-manager = {
      useGlobalPkgs = lib.mkDefault true;
      useUserPackages = lib.mkDefault true;
      backupFileExtension = lib.mkDefault "hm-backup";
      sharedModules = [ homeModule ];

      users = lib.mapAttrs (name: user: {
        home = {
          username = lib.mkDefault name;
          homeDirectory = lib.mkDefault user.homeDirectory;
          stateVersion = lib.mkDefault config.system.stateVersion;
        };
        opinionated.roles = lib.mkMerge [
          (lib.genAttrs user.roles (_: {
            enable = true;
          }))
          { base.git = lib.filterAttrs (_: v: v != null) user.git; }
        ];
      }) cfg.users;
    };

    # Unfree packages requested by each user's roles. This only works with
    # useGlobalPkgs, where Home Manager shares the system nixpkgs instance.
    opinionated.unfreePackages = lib.concatMap (hmUser: hmUser.opinionated.unfreePackages) (
      builtins.attrValues config.home-manager.users
    );

    programs.zsh.enable = lib.mkIf (lib.any hasBase (builtins.attrValues cfg.users)) true;
    users.users = lib.mapAttrs (_: _: { shell = pkgs.zsh; }) (lib.filterAttrs (_: hasBase) cfg.users);
  };
}
