# Ops role: Kubernetes, Helm, Flux, Terraform and (optionally) Azure tooling.
{ config, ... }:
let
  inherit (config.flake.modules) homeManager;
in
{
  flake.modules.homeManager.ops =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.roles.ops;
    in
    {
      imports = [ homeManager.common ];

      options.roles.ops.azure.enable = lib.mkEnableOption "Azure CLI and its oh-my-zsh plugin";

      config = {
        home.packages =
          with pkgs;
          [
            kubectl
            kubernetes-helm
            fluxcd
          ]
          ++ lib.optional cfg.azure.enable azure-cli;

        programs.zsh.oh-my-zsh.plugins = [
          "kubectl"
          "kubectx"
          "helm"
          "terraform"
          "ansible"
        ]
        ++ lib.optional cfg.azure.enable "azure";

        programs.lazyvim.extras.lang.terraform = {
          enable = true;
          installDependencies = true;
        };

        # Pulled in by the LazyVim `lang.terraform` extra.
        roles.unfreePackages = [ "terraform" ];
      };
    };
}
