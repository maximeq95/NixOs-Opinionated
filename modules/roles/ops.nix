# Ops role: Kubernetes, Helm, Flux, Terraform and (optionally) Azure tooling.
{
  opinionated.roles.ops.description = "Kubernetes, Helm, Flux, Terraform";

  flake.modules.homeManager.roles =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.opinionated.roles.ops;
    in
    {
      options.opinionated.roles.ops.azure.enable =
        lib.mkEnableOption "Azure CLI and its oh-my-zsh plugin";

      config = lib.mkIf cfg.enable {
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
        opinionated.unfreePackages = [ "terraform" ];
      };
    };
}
