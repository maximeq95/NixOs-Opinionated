{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    opinionated = {
      url = "github:pchesneau/NixOs-opinionated";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, opinionated, ... }:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          opinionated.nixosModules.wsl
          ./configuration.nix
        ];
      };
    };
}
