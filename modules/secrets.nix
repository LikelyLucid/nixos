{ ... }:
{
  sops = {
    age.keyFile = "/home/lucid/.secrets/age.agekey";
    defaultSopsFile = ../secrets/secrets.yaml;
    secrets = {
      gemini_api_key = { };
      tailscale-auth-key = { };
    };
  };
}
