{ config, pkgs, ... }:

{
  sops.secrets.GEMINI_API_KEY = {
    # This will be the path to the secret in the YAML file.
    # The user will need to add this to their secrets.yaml
  };

  

  
}
