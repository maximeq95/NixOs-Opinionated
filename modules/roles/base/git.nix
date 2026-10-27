# Base role: git with delta as pager. The identity is left to the user, in
# `programs.git.settings.user.{name,email}`.
{
  flake.modules.homeManager.base = {
    programs.git = {
      enable = true;
      settings = {
        core.autocrlf = "input";
        push.autoSetupRemote = true;
        pull.rebase = true;
      };
    };

    # Syntax-highlighted, side-by-side diffs as git's pager (diff/log/show/blame).
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
    };
  };
}
