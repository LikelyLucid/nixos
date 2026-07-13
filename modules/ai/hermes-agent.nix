{ inputs, ... }:
{
  nixos.modules.desktop =
    { config, ... }:
    {
      imports = [ inputs.hermes-agent.nixosModules.default ];

      sops.secrets.hermes-env = {
        owner = "hermes";
        group = "hermes";
      };

      services.hermes-agent = {
        enable = true;
        addToSystemPackages = true;
        environmentFiles = [ config.sops.secrets.hermes-env.path ];
        settings.model = {
          default = "kimi-k2.7-code";
          provider = "opencode-go";
        };
      };
    };
}
