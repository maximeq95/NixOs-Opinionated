# Packages of this flake are distributed through overlays: the module of each
# package contributes `overlays.<package>`, and `overlays.default` composes
# them all (an overlay cannot be merged from several files).
{ config, lib, ... }:
{
  flake.overlays.default = lib.composeManyExtensions (
    lib.attrValues (removeAttrs config.flake.overlays [ "default" ])
  );
}
