# Platform-agnostic core: system defaults, Home Manager users and roles, and
# the declaration of the platform selected by the imported platform module.
{
  inputs,
  roles,
  platforms,
  homeModule,
}:
{ lib, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./common.nix
    ./system.nix
    (import ./home.nix { inherit roles homeModule; })
  ];

  # Read-only without a default: a default would count as a definition.
  options.opinionated.platform = lib.mkOption {
    type = lib.types.enum platforms.names;
    readOnly = true;
    description = ''
      Platform of this host, set by the imported platform module
      (`nixosModules.<platform>`) and undefined when only the core is
      imported. Being read-only, it makes importing two platform modules an
      evaluation error.
    '';
  };
}
