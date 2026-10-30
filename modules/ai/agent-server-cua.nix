{ config, ... }:
{
  nixos.modules.agent-server = { pkgs, ... }: {
    virtualisation.podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    systemd.user.sockets.podman.wantedBy = [ "sockets.target" ];
    environment.systemPackages = [ config.flake.packages.${pkgs.stdenv.hostPlatform.system}.cua ];
  };

  homeManager.modules.agent-server =
    { pkgs, ... }:
    let
      cua = config.flake.packages.${pkgs.stdenv.hostPlatform.system}.cua;
      skills = [
        "cua-spaces"
        "cua-sandboxes"
        "cua-volume"
      ];
      skill_files = builtins.listToAttrs (
        builtins.concatMap (name: [
          {
            name = ".agents/skills/${name}";
            value.source = "${cua.skills}/${name}";
          }
          {
            name = ".local/state/agent-proxy/pi/skills/${name}";
            value.source = "${cua.skills}/${name}";
          }
        ]) skills
      );
    in
    {
      home.file = skill_files;
    };
}
