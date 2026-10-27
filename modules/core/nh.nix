# nh, with a store cleanup: old generations are removed and the store is
# garbage-collected, then identical files are hardlinked. It keeps /nix/store
# from growing unbounded, which matters most on WSL's size-capped disk.
{
  flake.modules.nixos.nh =
    { config, lib, ... }:
    {
      programs.nh = {
        enable = lib.mkDefault true;
        # Flake used by `nh os` when no path is given (exported as NH_FLAKE).
        flake = lib.mkDefault "/etc/nixos";
        clean = {
          enable = lib.mkDefault true;
          dates = lib.mkDefault "weekly";
          extraArgs = lib.mkDefault "--keep-since 14d";
        };
      };

      nix.optimise = {
        automatic = lib.mkDefault config.programs.nh.clean.enable;
        dates = lib.mkDefault [ config.programs.nh.clean.dates ];
      };
    };
}
