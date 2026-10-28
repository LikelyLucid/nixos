{ ... }:
{
  nixos.modules.agent-server.nixpkgs.overlays = [
    (_final: prev: {
      herdr-nvim = prev.herdr-nvim.overrideAttrs (old: {
        # LLVM's level-3 optimization of fff-search exceeded 20 minutes during
        # server provisioning. Keep the picker dependency at level 1 here.
        postPatch = (old.postPatch or "") + ''
          cat >> Cargo.toml <<'PROFILE'

          [profile.release.package.fff-search]
          opt-level = 1
          PROFILE
        '';
      });
    })
  ];
}
