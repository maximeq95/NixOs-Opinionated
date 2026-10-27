# LLM role: AI assistant CLI for the selected provider, plus AI plugins for
# IntelliJ IDEA when the dev role is imported too.
{ config, ... }:
let
  inherit (config.flake.modules) homeManager;
in
{
  flake.modules.homeManager.llm =
    {
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      cfg = config.roles.llm;

      # Each provider lists the packages it installs and the unfree package names
      # they require. Adding a provider means adding an entry here.
      providers = {
        github-copilot = {
          packages = [ pkgs.github-copilot-cli ];
          unfree = [ "github-copilot-cli" ];
        };
      };

      provider = providers.${cfg.provider};
    in
    {
      imports = [ homeManager.common ];

      options.roles.llm = {
        provider = lib.mkOption {
          type = lib.types.enum (builtins.attrNames providers);
          default = "github-copilot";
          description = "LLM provider whose tooling is installed.";
        };

        intellijPlugins = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "org.jetbrains.junie"
            "com.intellij.mcpServer"
            "com.intellij.ml.llm"
            "com.agentport.jetbrains-acp"
            "com.intellij.air"
          ];
          description = "AI plugins added to IntelliJ IDEA when the dev role is imported too.";
        };
      };

      config = lib.mkMerge [
        {
          home.packages = provider.packages;
          roles.unfreePackages = provider.unfree;
        }
        # `roles.dev` only exists when the dev role is imported: `lib.mkIf`
        # cannot guard an option that may not exist, so its presence is tested.
        (lib.optionalAttrs (options.roles ? dev) {
          roles.dev.intellij.plugins = cfg.intellijPlugins;
        })
      ];
    };
}
