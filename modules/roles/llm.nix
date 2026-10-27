# LLM role: AI assistant CLI for the selected provider, plus AI plugins for
# IntelliJ IDEA when the dev role is enabled.
{
  opinionated.roles.llm.description = "AI assistant tooling";

  flake.modules.homeManager.roles =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.opinionated.roles.llm;

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
      options.opinionated.roles.llm = {
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
          description = "AI plugins added to IntelliJ IDEA when the dev role is enabled.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = provider.packages;
        opinionated.unfreePackages = provider.unfree;
        opinionated.roles.dev.intellij.plugins =
          lib.mkIf config.opinionated.roles.dev.enable cfg.intellijPlugins;
      };
    };
}
