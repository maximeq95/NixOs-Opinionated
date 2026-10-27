# Base role: git with delta as pager, and the git identity of each user.
{
  flake.modules.nixos.core =
    { config, lib, ... }:
    let
      cfg = config.opinionated;
    in
    {
      options.opinionated.users = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options.git = {
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
          }
        );
      };

      config = lib.mkIf cfg.home.enable {
        home-manager.users = lib.mapAttrs (_: user: {
          opinionated.roles.base.git = lib.filterAttrs (_: v: v != null) user.git;
        }) cfg.users;
      };
    };

  flake.modules.homeManager.roles =
    { config, lib, ... }:
    let
      cfg = config.opinionated.roles.base;
    in
    {
      options.opinionated.roles.base.git = {
        userName = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Git author name.";
        };
        userEmail = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Git author email.";
        };
      };

      config = lib.mkIf cfg.enable {
        programs.git = {
          enable = true;
          settings = {
            user = lib.filterAttrs (_: v: v != null) {
              name = cfg.git.userName;
              email = cfg.git.userEmail;
            };
            core.autocrlf = "input";
            push.autoSetupRemote = true;
            pull.rebase = true;
          };
        };

        # Syntax-highlighted, side-by-side diffs as git's pager (diff/log/show/blame).
        programs.delta = {
          enable = true;
          enableGitIntegration = true;
        };
      };
    };
}
