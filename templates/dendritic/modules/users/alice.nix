# Alice's Home Manager settings, on top of her roles: role options and any
# other Home Manager setting.
{ inputs, ... }:
{
  flake.modules.homeManager.alice = {
    # A role taken directly as a module, outside `roles.users`.
    imports = [ inputs.nixos-roles.modules.homeManager.llm ];

    programs.git.settings.user = {
      name = "Alice";
      email = "alice@example.com";
    };

    roles.ops.azure.enable = true;
  };
}
