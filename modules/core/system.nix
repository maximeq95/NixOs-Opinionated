# System-wide Nix and NixOS defaults.
{
  flake.modules.nixos.core =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.opinionated.system;
    in
    {
      options.opinionated.system = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to apply the opinionated system-wide NixOS defaults.";
        };

        flakePath = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "/etc/nixos";
          description = "Flake used by `nh os` when no path is given (exported as NH_FLAKE).";
        };

        clean = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to periodically remove old generations and garbage-collect the store with `nh clean`.";
          };
          dates = lib.mkOption {
            type = lib.types.str;
            default = "weekly";
            description = "systemd calendar expression for the cleanup and store optimisation timers.";
          };
          keepSince = lib.mkOption {
            type = lib.types.str;
            default = "14d";
            description = "Generations younger than this are kept by `nh clean`.";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        time.timeZone = lib.mkDefault "Europe/Paris";
        fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

        # Written to /etc/nix/nix.conf, so these apply to every user.
        nix.settings = {
          experimental-features = [
            "nix-command"
            "flakes"
            "configurable-impure-env"
          ];
          impure-env = [ "NIX_CURL_FLAGS" ];
          trusted-users = [
            "root"
            "@wheel"
          ];
        };

        # Keeps /nix/store from growing unbounded, which matters most on WSL's
        # size-capped virtual disk: old generations are removed and the store is
        # garbage-collected, then identical files are hardlinked.
        programs.nh = {
          enable = true;
          flake = lib.mkIf (cfg.flakePath != null) cfg.flakePath;
          clean = lib.mkIf cfg.clean.enable {
            enable = true;
            inherit (cfg.clean) dates;
            extraArgs = "--keep-since ${cfg.clean.keepSince}";
          };
        };
        nix.optimise = lib.mkIf cfg.clean.enable {
          automatic = true;
          dates = [ cfg.clean.dates ];
        };
      };
    };
}
