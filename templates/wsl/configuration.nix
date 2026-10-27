{ ... }:
{
  system.stateVersion = "26.05";

  # Users and their roles: base, ops, dev, llm.
  roles.users.alice = [
    "base"
    "ops"
    "dev"
    "llm"
  ];

  # Role options, like any other Home Manager setting.
  home-manager.users.alice = {
    programs.git.settings.user = {
      name = "Alice";
      email = "alice@example.com";
    };
    # roles.ops.azure.enable = true;
  };
}
