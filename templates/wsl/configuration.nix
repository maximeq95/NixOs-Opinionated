{ ... }:
{
  system.stateVersion = "26.05";

  opinionated = {
    system.enable = true;
    wsl.enable = true;

    users.alice = {
      roles = [
        "base"
        "ops"
        "dev"
        "llm"
      ];
      git = {
        userName = "Alice";
        userEmail = "alice@example.com";
      };
    };
  };

  # Role-specific options and any other Home Manager setting:
  # home-manager.users.alice.opinionated.roles.ops.azure.enable = true;
}
