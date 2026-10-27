# `nix flake init -t` templates: one per directory of ./templates, named
# after the platform it targets.
{ lib, ... }:
{
  flake.templates = lib.mapAttrs (name: _: {
    path = ../templates/${name};
    description = "NixOS host on the `${name}` platform consuming nixos-opinionated";
  }) (builtins.readDir ../templates);
}
