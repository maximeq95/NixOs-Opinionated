# The core: the NixOS features every platform module includes. Each of them
# can also be imported alone.
{ config, ... }:
{
  flake.modules.nixos.core.imports = with config.flake.modules.nixos; [
    nix
    nh
    fonts
    time-zone
    roles
  ];
}
