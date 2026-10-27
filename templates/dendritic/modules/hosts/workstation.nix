# The host: a platform module of nixos-roles, users and their roles.
{ config, inputs, ... }:
let
  inherit (config.flake.modules) nixos homeManager;
in
{
  flake.modules.nixos.workstation = {
    imports = [ inputs.nixos-roles.modules.nixos.wsl ];

    networking.hostName = "workstation";
    system.stateVersion = "26.05";

    # Roles of nixos-roles: base, ops, dev, llm.
    roles.users.alice = [
      "base"
      "ops"
      "dev"
    ];

    # Alice's own Home Manager module, from ../users/alice.nix.
    home-manager.users.alice.imports = [ homeManager.alice ];
  };

  flake.nixosConfigurations.workstation = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      nixos.workstation
      { nixpkgs.hostPlatform = "x86_64-linux"; }
    ];
  };
}
