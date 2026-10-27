# Unfree packages: each role lists the unfree packages it needs, and NixOS
# collects them from every Home Manager user into its allow list.
{
  flake.modules.nixos.unfree =
    { config, lib, ... }:
    let
      cfg = config.roles;
    in
    {
      options.roles = {
        unfreePackages = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "vscode" ];
          description = ''
            Names (as returned by `lib.getName`) of unfree packages allowed on
            this system. The roles of `roles.users` add the ones they need; add
            your own entries here rather than setting
            `nixpkgs.config.allowUnfreePredicate`.
          '';
        };

        manageUnfreePackages = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Whether to set `nixpkgs.config.allowUnfreePredicate` from
            {option}`roles.unfreePackages`. Disable it to provide your own
            predicate.
          '';
        };
      };

      # The list is only forced when an unfree package is evaluated, which
      # keeps nixpkgs instantiation independent from Home Manager evaluation.
      config.nixpkgs.config = lib.mkIf cfg.manageUnfreePackages {
        allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) cfg.unfreePackages;
      };
    };

  flake.modules.nixos.roles =
    { config, lib, ... }:
    {
      # This only works with useGlobalPkgs, where Home Manager shares the
      # system nixpkgs instance.
      roles.unfreePackages = lib.concatMap (user: user.roles.unfreePackages or [ ]) (
        builtins.attrValues config.home-manager.users
      );
    };

  flake.modules.homeManager.common =
    { lib, ... }:
    {
      options.roles.unfreePackages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Unfree packages (by `lib.getName`) needed by the roles. On NixOS they
          are added to the system-level `roles.unfreePackages`; with standalone
          Home Manager, allow them in your `pkgs`.
        '';
      };
    };
}
