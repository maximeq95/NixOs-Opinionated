# Unfree packages: roles list the unfree packages they need, which are
# collected into the system-level allow list.
{
  flake.modules.nixos.core =
    { config, lib, ... }:
    let
      cfg = config.opinionated;
    in
    {
      options.opinionated = {
        unfreePackages = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "terraform" ];
          description = ''
            Names (as returned by `lib.getName`) of unfree packages allowed on
            this system. Home Manager roles contribute to this list
            automatically; add your own entries here rather than setting
            `nixpkgs.config.allowUnfreePredicate`.
          '';
        };

        manageUnfreePackages = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Whether to set `nixpkgs.config.allowUnfreePredicate` from
            {option}`opinionated.unfreePackages`. Disable it to provide your own
            predicate.
          '';
        };
      };

      config = lib.mkMerge [
        (lib.mkIf cfg.manageUnfreePackages {
          # The list is only forced when an unfree package is evaluated, which
          # keeps nixpkgs instantiation independent from Home Manager evaluation.
          nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) cfg.unfreePackages;
        })
        (lib.mkIf cfg.home.enable {
          # Unfree packages requested by each user's roles. This only works with
          # useGlobalPkgs, where Home Manager shares the system nixpkgs instance.
          opinionated.unfreePackages = lib.concatMap (hmUser: hmUser.opinionated.unfreePackages) (
            builtins.attrValues config.home-manager.users
          );
        })
      ];
    };

  flake.modules.homeManager.roles =
    { lib, ... }:
    {
      options.opinionated.unfreePackages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Unfree packages (by `lib.getName`) needed by the enabled roles. On NixOS
          they are collected into the system-level `opinionated.unfreePackages`.
        '';
      };
    };
}
