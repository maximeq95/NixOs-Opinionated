# NixOS-WSL defaults. Requires the NixOS-WSL module (imported by the flake).
{ config, lib, ... }:
let
  cfg = config.opinionated.wsl;
in
{
  options.opinionated.wsl = {
    enable = lib.mkEnableOption "opinionated NixOS-WSL defaults";
  };

  config = lib.mkIf cfg.enable {
    wsl = {
      enable = true;
      # Keeps Windows binaries out of $PATH, so commands always resolve to
      # their Nix-provided version.
      interop.includePath = lib.mkDefault false;
      useWindowsDriver = lib.mkDefault true;
    };
  };
}
