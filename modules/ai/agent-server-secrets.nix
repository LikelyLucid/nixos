{ inputs, ... }:
{
  nixos.modules.agent-server =
    { config, ... }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];
      sops = {
        defaultSopsFile = ../../secrets/agent-server.yaml;
        # Enroll the target's SSH identity once, without copying private keys.
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        secrets = {
          agent-proxy-api-key = {
            key = "cli-proxy-api-key";
            owner = "lucid";
            mode = "0400";
            restartUnits = [ "agent-proxy-config.service" ];
          };
          agent-proxy-base-url = {
            key = "cli-proxy-base-url";
            owner = "lucid";
            mode = "0400";
            restartUnits = [ "agent-proxy-config.service" ];
          };
          tailscale-auth-key.mode = "0400";
        };
      };
      services.tailscale = {
        authKeyFile = config.sops.secrets.tailscale-auth-key.path;
        extraUpFlags = [
          "--ssh"
          "--operator=lucid"
        ];
      };
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.agent-server-enroll-secrets = pkgs.writeShellApplication {
        name = "agent-server-enroll-secrets";
        runtimeInputs = with pkgs; [
          coreutils
          git
          openssh
          sops
          ssh-to-age
          util-linux
          yq-go
        ];
        text = builtins.readFile ../../scripts/enroll-agent-server-secrets.sh;
      };
    };
}
