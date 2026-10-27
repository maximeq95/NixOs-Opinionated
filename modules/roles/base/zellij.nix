# Base role: Zellij terminal multiplexer, attached on shell startup.
{
  flake.modules.homeManager.roles =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = lib.mkIf config.opinionated.roles.base.enable {
        programs.zellij = {
          enable = true;
          enableZshIntegration = true;
          plugins = with pkgs.zellijPlugins; [ autolock ];
          settings = {
            theme = "catppuccin-mocha";
            show_startup_tips = false;
          };
          attachExistingSession = true;
        };
      };
    };
}
