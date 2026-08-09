{
  config,
  inputs,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    let
      herdr_workspace_manager = pkgs.rustPlatform.buildRustPackage {
        pname = "herdr-plugin-workspace-manager";
        version = "0.6.0";
        src = inputs.herdr-workspace-manager;
        cargoLock.lockFile = inputs.herdr-workspace-manager + "/Cargo.lock";

        postInstall = ''
          install -Dm644 herdr-plugin.toml $out/herdr-plugin.toml
          substituteInPlace $out/herdr-plugin.toml \
            --replace-fail '["sh", "bin/herdr-workspace-manager"' '["bin/herdr-workspace-manager"'
        '';

        meta = {
          description = "Declarative workspace layouts for Herdr";
          homepage = "https://github.com/razajamil/herdr-plugin-workspace-manager";
          license = pkgs.lib.licenses.mit;
          mainProgram = "herdr-workspace-manager";
          platforms = pkgs.lib.platforms.unix;
        };
      };

      herdr_worktree_setup = pkgs.buildNpmPackage {
        pname = "herdr-worktree-setup";
        version = "0.2.0";
        src = inputs.herdr-worktree-setup;
        npmDepsHash = "sha256-RRO1LUWos3mkaFA3Fb4xwomfn8DrD1Gt67VP7V7xi3w=";
        dontNpmBuild = true;

        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp -r herdr-plugin.toml src node_modules $out/
          substituteInPlace $out/herdr-plugin.toml \
            --replace-fail '["node", "src/setup.js"]' '["${pkgs.lib.getExe pkgs.nodejs}", "src/setup.js"]'
          runHook postInstall
        '';
      };

      herdr_command_palette = pkgs.stdenvNoCC.mkDerivation {
        pname = "herdr-command-palette";
        version = "0.1.0";
        src = inputs.herdr-command-palette;

        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp herdr-plugin.toml open.sh palette.sh $out/
          patchShebangs $out/*.sh
          runHook postInstall
        '';
      };

      herdr_pluck = pkgs.rustPlatform.buildRustPackage {
        pname = "herdr-pluck";
        version = "0.3.0";
        src = inputs.herdr-pluck;
        cargoLock.lockFile = inputs.herdr-pluck + "/Cargo.lock";

        postInstall = ''
          install -Dm644 herdr-plugin.toml $out/herdr-plugin.toml
        '';
      };

      vim_herdr_navigation = pkgs.stdenvNoCC.mkDerivation {
        pname = "vim-herdr-navigation";
        version = "0.1.0";
        src = inputs.vim-herdr-navigation;

        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp -r herdr-plugin.toml navigate.sh editor $out/
          patchShebangs $out/navigate.sh
          runHook postInstall
        '';
      };
    in
    {
      packages.herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
      packages.herdr-workspace-manager = herdr_workspace_manager;
      packages.herdr-worktree-setup = herdr_worktree_setup;
      packages.herdr-command-palette = herdr_command_palette;
      packages.herdr-pluck = herdr_pluck;
      packages.vim-herdr-navigation = vim_herdr_navigation;
    };

  nixos.modules.common.nixpkgs.overlays = [
    (final: _prev: {
      herdr = config.flake.packages.${final.stdenv.hostPlatform.system}.herdr;
      herdr-workspace-manager =
        config.flake.packages.${final.stdenv.hostPlatform.system}.herdr-workspace-manager;
      herdr-worktree-setup =
        config.flake.packages.${final.stdenv.hostPlatform.system}.herdr-worktree-setup;
      herdr-command-palette =
        config.flake.packages.${final.stdenv.hostPlatform.system}.herdr-command-palette;
      herdr-pluck = config.flake.packages.${final.stdenv.hostPlatform.system}.herdr-pluck;
      vim-herdr-navigation =
        config.flake.packages.${final.stdenv.hostPlatform.system}.vim-herdr-navigation;
    })
  ];

  homeManager.modules.common =
    { lib, pkgs, ... }:
    {
      home.packages = [
        pkgs.herdr
        pkgs.fzf
        pkgs.jq
      ];

      xdg.configFile."herdr/config.toml" = {
        force = true;
        text = ''
          onboarding = false

          [ui]
          show_agent_labels_on_pane_borders = true
          agent_panel_sort = "spaces"

          [ui.toast]
          delivery = "system"

          [experimental]
          pane_history = true

          [[keys.command]]
          key = "prefix+space"
          type = "plugin_action"
          command = "jt.command-palette.open"
          description = "Command palette"

          [[keys.command]]
          key = "ctrl+h"
          type = "plugin_action"
          command = "vim-herdr-navigation.left"
          description = "Navigate left (Vim/Herdr)"

          [[keys.command]]
          key = "ctrl+j"
          type = "plugin_action"
          command = "vim-herdr-navigation.down"
          description = "Navigate down (Vim/Herdr)"

          [[keys.command]]
          key = "ctrl+k"
          type = "plugin_action"
          command = "vim-herdr-navigation.up"
          description = "Navigate up (Vim/Herdr)"

          [[keys.command]]
          key = "ctrl+l"
          type = "plugin_action"
          command = "vim-herdr-navigation.right"
          description = "Navigate right (Vim/Herdr)"
        '';
      };

      home.activation.linkHerdrPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        activation_socket=/tmp/herdr-home-manager-$UID.sock
        run rm -f "$activation_socket"
        run env HERDR_SOCKET_PATH="$activation_socket" \
          ${lib.getExe pkgs.herdr} plugin link ${pkgs.herdr-workspace-manager}
        run env HERDR_SOCKET_PATH="$activation_socket" \
          ${lib.getExe pkgs.herdr} plugin link ${pkgs.herdr-worktree-setup}
        run env HERDR_SOCKET_PATH="$activation_socket" \
          ${lib.getExe pkgs.herdr} plugin link ${pkgs.herdr-command-palette}
        run env HERDR_SOCKET_PATH="$activation_socket" \
          ${lib.getExe pkgs.herdr} plugin link ${pkgs.herdr-pluck}
        run env HERDR_SOCKET_PATH="$activation_socket" \
          ${lib.getExe pkgs.herdr} plugin link ${pkgs.vim-herdr-navigation}
      '';
    };
}
