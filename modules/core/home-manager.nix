# Home Manager integration: every user of `opinionated.users` gets a Home
# Manager configuration with the roles they are given.
{ config, inputs, ... }:
let
  roleNames = builtins.attrNames config.opinionated.roles;
  inherit (config.flake) homeModules;
in
{
  flake.modules.nixos.core =
    { config, lib, ... }:
    let
      cfg = config.opinionated;

      userModule =
        { name, ... }:
        {
          options = {
            roles = lib.mkOption {
              type = lib.types.listOf (lib.types.enum roleNames);
              default = [ "base" ];
              example = [
                "base"
                "ops"
                "dev"
              ];
              description = ''
                Home Manager roles enabled for this user. Available roles:
                ${lib.concatStringsSep ", " roleNames}. Role-specific options
                are set through `home-manager.users.<name>.opinionated.roles.<role>`.
              '';
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
      imports = [ inputs.home-manager.nixosModules.home-manager ];

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
          sharedModules = [ homeModules.roles ];

          users = lib.mapAttrs (name: user: {
            home = {
              username = lib.mkDefault name;
              homeDirectory = lib.mkDefault user.homeDirectory;
              stateVersion = lib.mkDefault config.system.stateVersion;
            };
            opinionated.roles = lib.genAttrs user.roles (_: {
              enable = true;
            });
          }) cfg.users;
        };
      };
    };
}
