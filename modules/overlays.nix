# Packages of this flake are distributed through overlays. The module of each
# package contributes `overlays.<package>`; `overlays.default` composes them
# all (in name order), since an overlay cannot be merged from several files.
# It is applied to the NixOS configurations importing the core, where Home
# Manager shares the system packages.
{ config, lib, ... }:
let
  inherit (config.flake) overlays;
in
{
  flake.overlays.default = lib.composeManyExtensions (
    lib.attrValues (removeAttrs overlays [ "default" ])
  );

  flake.modules.nixos.core.nixpkgs.overlays = [ overlays.default ];
}
