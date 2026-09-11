{ ... }:
{
  homeManager.modules.desktop =
    { pkgs, ... }:
    let
      audio_sink_watchdog = pkgs.writeShellApplication {
        name = "audio-sink-watchdog";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.jq
          pkgs.pipewire
          pkgs.systemd
        ];
        text = ''
          set -euo pipefail

          # Work around WirePlumber occasionally failing to enumerate the Intel
          # SOF/cAVS card profiles at session start: the card device exists but no
          # sinks are created, so pipewire-pulse exposes only its "auto_null"
          # fallback sink (Dummy Output). WirePlumber never retries failed device
          # activation, so audio stays broken until it is restarted. Restarting
          # only WirePlumber re-enumerates the card; running streams survive and
          # relink automatically. Back off after a restart attempt so a persistent
          # enumeration failure cannot turn this into a restart loop.

          state_dir="''${XDG_RUNTIME_DIR:-/tmp}/audio-sink-watchdog"
          marker="$state_dir/last-restart"
          cooldown=600

          mkdir -p "$state_dir"

          # Nothing to do without an ALSA sound card.
          if ! grep -qE '^[[:space:]]*[0-9]+ \[' /proc/asound/cards; then
            exit 0
          fi

          now=$(date +%s)
          if [[ -f $marker ]]; then
            last_restart=$(<"$marker") || last_restart=0
            if [[ $last_restart =~ ^[0-9]+$ ]] && (( now - last_restart < cooldown )); then
              exit 0
            fi
          fi

          # Prints "<total sinks> <placeholder sinks>", or fails when PipeWire is
          # unreachable.
          sink_counts() {
            local dump
            dump=$(pw-dump 2>/dev/null) || return 1
            jq -r '
              def sp: (.info.props // {});
              [ .[]
                | select(.type == "PipeWire:Interface:Node")
                | select(sp."media.class" == "Audio/Sink")
              ] as $sinks
              | "\($sinks | length) \([ $sinks[]
                  | select(
                      (sp."node.name" == "auto_null")
                      or (sp."node.description" == "Dummy Output")
                    )
                ] | length)"
            ' <<<"$dump" || return 1
          }

          # Broken = at least one sink exists and every sink is the placeholder.
          is_broken() {
            local counts total placeholders
            counts=$(sink_counts) || return 1
            total="''${counts%% *}"
            placeholders="''${counts##* }"
            (( total > 0 && placeholders == total ))
          }

          is_broken || exit 0
          # Re-check briefly so a transient startup state is not acted on.
          sleep 5
          is_broken || exit 0

          printf '%s\n' "$now" >"$marker"
          echo "audio-sink-watchdog: only Dummy Output present; restarting wireplumber"
          systemctl --user restart wireplumber.service || true

          for _ in {1..20}; do
            sleep 1
            counts=$(sink_counts) || continue
            total="''${counts%% *}"
            placeholders="''${counts##* }"
            if (( total > placeholders )); then
              echo "audio-sink-watchdog: recovered; real audio sink present"
              exit 0
            fi
          done

          echo "audio-sink-watchdog: re-probe did not restore a real sink; backing off for ''${cooldown}s"
        '';
      };
    in
    {
      ############################################
      # AUDIO SINK WATCHDOG
      ############################################
      # Detects the WirePlumber SOF/cAVS enumeration failure (card present but
      # only the pipewire-pulse "Dummy Output" sink exists) and re-probes
      # WirePlumber automatically; see the script comment above for details.

      systemd.user.services.audio-sink-watchdog = {
        Unit = {
          Description = "Re-probe WirePlumber when only the Dummy Output sink exists";
          After = [ "pipewire.service" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${audio_sink_watchdog}/bin/audio-sink-watchdog";
        };
      };

      systemd.user.timers.audio-sink-watchdog = {
        Unit.Description = "Periodic check for the Dummy-Output-only sink state";
        Timer = {
          OnStartupSec = "20s";
          OnUnitActiveSec = "30s";
          AccuracySec = "5s";
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
}
