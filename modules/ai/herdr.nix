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

      herdr_sidebar = pkgs.rustPlatform.buildRustPackage {
        pname = "herdr-sidebar";
        version = "0.7.0";
        src = inputs.herdr-sidebar + "/plugins/herdr-sidebar";
        cargoHash = "sha256-naQDuURfA9UqwtmnHrvh4hZR4V5+C1SYeJhxZ1weuwI=";
        dontCargoInstall = true;
        doCheck = false;

        postInstall = ''
          install -Dm644 herdr-plugin.toml $out/herdr-plugin.toml
          install -Dm755 target/${pkgs.stdenv.hostPlatform.rust.rustcTargetSpec}/release/herdr-sidebar $out/target/release/herdr-sidebar
          install -Dm755 target/${pkgs.stdenv.hostPlatform.rust.rustcTargetSpec}/release/herdr-sidebar-ensure $out/target/release/herdr-sidebar-ensure
          cp -r scripts $out/
          patchShebangs $out/scripts/*.sh
        '';
      };

      herdr_nvim = pkgs.rustPlatform.buildRustPackage {
        pname = "herdr-nvim";
        version = "0.1.1";
        src = inputs.herdr-nvim;
        cargoLock.lockFile = inputs.herdr-nvim + "/Cargo.lock";
        dontCargoInstall = true;
        doCheck = false;

        postInstall = ''
          install -Dm644 herdr-plugin.toml $out/herdr-plugin.toml
          install -Dm755 target/${pkgs.stdenv.hostPlatform.rust.rustcTargetSpec}/release/herdr-nvim $out/bin/herdr-nvim
          cp -r herdr lua $out/
          patchShebangs $out/herdr/*.sh
        '';
      };

      herdr_automatic_rename = pkgs.stdenvNoCC.mkDerivation {
        pname = "herdr-automatic-rename";
        version = "0.7.0";
        src = inputs.herdr-automatic-rename;
        dontBuild = true;

        installPhase = ''
          runHook preInstall
          mkdir -p $out
          install -Dm644 herdr-plugin.toml $out/herdr-plugin.toml
          install -Dm755 automatic-rename.sh naming.sh icons.sh $out/
          cp -r shell $out/
          patchShebangs $out/*.sh $out/shell/*
          runHook postInstall
        '';
      };

      herdr_board = pkgs.rustPlatform.buildRustPackage {
        pname = "herdr-board";
        version = "0.15.0";
        src = inputs.herdr-board;
        cargoLock.lockFile = inputs.herdr-board + "/Cargo.lock";
        cargoBuildFlags = [
          "-p"
          "board-cli"
        ];
        dontCargoInstall = true;
        doCheck = false;

        postInstall = ''
          install -Dm644 herdr-plugin.toml $out/herdr-plugin.toml
          install -Dm755 target/${pkgs.stdenv.hostPlatform.rust.rustcTargetSpec}/release/board $out/target/release/board
          install -Dm755 scripts/open-board.sh $out/scripts/open-board.sh
          patchShebangs $out/scripts/open-board.sh
        '';
      };

      herdr_navigator = pkgs.rustPlatform.buildRustPackage {
        pname = "herdr-navigator";
        version = "0.3.6";
        src = inputs.herdr-navigator;
        cargoLock.lockFile = inputs.herdr-navigator + "/Cargo.lock";
        dontCargoInstall = true;

        postInstall = ''
          install -Dm644 herdr-plugin.toml $out/herdr-plugin.toml
          install -Dm755 target/${pkgs.stdenv.hostPlatform.rust.rustcTargetSpec}/release/herdr-navigator $out/target/release/herdr-navigator
        '';
      };

      herdr_memex = pkgs.rustPlatform.buildRustPackage {
        pname = "memex";
        version = "0.11.2";
        src = inputs.memex;
        cargoLock.lockFile = inputs.memex + "/Cargo.lock";
        nativeBuildInputs = [ pkgs.pkg-config ];
        buildInputs = [
          pkgs.openssl
          pkgs.onnxruntime
        ];
        dontCargoInstall = true;
        doCheck = false;

        postInstall = ''
          install -Dm644 herdr-plugin.toml $out/herdr-plugin.toml
          install -Dm755 target/${pkgs.stdenv.hostPlatform.rust.rustcTargetSpec}/release/memex $out/bin/memex
          cp -r herdr $out/
          patchShebangs $out/herdr/*.sh
        '';
      };

      herdr_hunk_diff_src = pkgs.runCommand "herdr-hunk-diff-source" { } ''
        cp -r ${inputs.herdr-hunk-diff} $out
        chmod -R u+w $out
        ${pkgs.jq}/bin/jq \
          '.scripts = {"build": "tsc -p tsconfig.json"} | .dependencies = {"hunkdiff": "0.18.1", "smol-toml": "1.7.1"} | .devDependencies = {"@types/node": "22.20.1", "typescript": "5.9.3"}' \
          $out/package.json > $out/package.json.tmp
        mv $out/package.json.tmp $out/package.json
        cp ${./herdr-hunk-diff-package-lock.json} $out/package-lock.json
      '';

      herdr_hunk_diff = pkgs.buildNpmPackage {
        pname = "herdr-hunk-diff";
        version = "0.1.0";
        src = herdr_hunk_diff_src;
        npmDepsHash = "sha256-Lt6gd9PAyW1YsQADhjI3maru7tJZUAZAFoneZsq6lHA=";
        npmDepsFetcherVersion = 2;
        npmRebuildFlags = [ "--ignore-scripts" ];
        npmBuildScript = "build";

        installPhase = ''
          runHook preInstall
          mkdir -p $out
          install -Dm644 herdr-plugin.toml package.json package-lock.json -t $out
          cp -r dist node_modules $out/
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
      packages.herdr-sidebar = herdr_sidebar;
      packages.herdr-nvim = herdr_nvim;
      packages.herdr-automatic-rename = herdr_automatic_rename;
      packages.herdr-board = herdr_board;
      packages.herdr-navigator = herdr_navigator;
      packages.herdr-memex = herdr_memex;
      packages.herdr-hunk-diff = herdr_hunk_diff;
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
      herdr-sidebar = config.flake.packages.${final.stdenv.hostPlatform.system}.herdr-sidebar;
      herdr-nvim = config.flake.packages.${final.stdenv.hostPlatform.system}.herdr-nvim;
      herdr-automatic-rename =
        config.flake.packages.${final.stdenv.hostPlatform.system}.herdr-automatic-rename;
      herdr-board = config.flake.packages.${final.stdenv.hostPlatform.system}.herdr-board;
      herdr-navigator = config.flake.packages.${final.stdenv.hostPlatform.system}.herdr-navigator;
      herdr-memex = config.flake.packages.${final.stdenv.hostPlatform.system}.herdr-memex;
      herdr-hunk-diff = config.flake.packages.${final.stdenv.hostPlatform.system}.herdr-hunk-diff;
    })
  ];

  homeManager.modules.common =
    { lib, pkgs, ... }:
    {
      home.packages = [
        pkgs.herdr
        pkgs.fzf
        pkgs.jq
        pkgs.herdr-memex
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
          kitty_graphics = true
          pane_history = true

          [[keys.command]]
          key = "prefix+space"
          type = "plugin_action"
          command = "jt.command-palette.open"
          description = "Command palette"

          [[keys.command]]
          key = "prefix+shift+s"
          type = "plugin_action"
          command = "herdr-sidebar.open-sidebar"
          description = "Toggle Herdr sidebar"

          [[keys.command]]
          key = "prefix+shift+e"
          type = "plugin_action"
          command = "chmarax.herdr-nvim.toggle"
          description = "Toggle nvim sidebar"

          [[keys.command]]
          key = "prefix+shift+o"
          type = "plugin_action"
          command = "chmarax.herdr-nvim.pick-file"
          description = "Open file from agent output"

          [[keys.command]]
          key = "prefix+t"
          type = "plugin_action"
          command = "herdr-navigator.open"
          description = "Open Herdr Navigator"

          [[keys.command]]
          key = "prefix+m"
          type = "plugin_action"
          command = "nicosuave.memex.palette"
          description = "Open memex session palette"

          [[keys.command]]
          key = "prefix+shift+k"
          type = "shell"
          command = "herdr plugin action invoke open-board --plugin herdr-board"
          description = "Open Herdr Board"

          [[keys.command]]
          key = "prefix+shift+r"
          type = "plugin_action"
          command = "herdr-automatic-rename.reset"
          description = "Reset automatic tab naming"

          [[keys.command]]
          key = "prefix+shift+h"
          type = "plugin_action"
          command = "jhochenbaum.hunkdiff.review"
          description = "Review changes in hunk"

          [[keys.command]]
          key = "prefix+shift+f"
          type = "plugin_action"
          command = "jhochenbaum.hunkdiff.send-review"
          description = "Send hunk review to agent"
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
          ${lib.getExe pkgs.herdr} plugin link ${pkgs.herdr-sidebar}
        run env HERDR_SOCKET_PATH="$activation_socket" \
          ${lib.getExe pkgs.herdr} plugin link ${pkgs.herdr-nvim}
        run env HERDR_SOCKET_PATH="$activation_socket" \
          ${lib.getExe pkgs.herdr} plugin link ${pkgs.herdr-automatic-rename}
        run env HERDR_SOCKET_PATH="$activation_socket" \
          ${lib.getExe pkgs.herdr} plugin link ${pkgs.herdr-board}
        run env HERDR_SOCKET_PATH="$activation_socket" \
          ${lib.getExe pkgs.herdr} plugin link ${pkgs.herdr-navigator}
        run env HERDR_SOCKET_PATH="$activation_socket" \
          ${lib.getExe pkgs.herdr} plugin link ${pkgs.herdr-memex}
        run env HERDR_SOCKET_PATH="$activation_socket" \
          ${lib.getExe pkgs.herdr} plugin link ${pkgs.herdr-hunk-diff}
      '';
    };
}
