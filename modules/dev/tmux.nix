{ ... }:
{
  homeManager.modules.common =
    { pkgs, ... }:
    {
      programs.tmux = {
        enable = true;
        terminal = "tmux-256color";
        baseIndex = 1;
        clock24 = true;
        customPaneNavigationAndResize = true;
        escapeTime = 0;
        focusEvents = true;
        historyLimit = 100000;
        keyMode = "vi";
        mouse = true;
        prefix = "C-a";
        resizeAmount = 3;
        sensibleOnTop = true;

        plugins = with pkgs.tmuxPlugins; [
          {
            plugin = resurrect;
            extraConfig = ''
              set -g @resurrect-strategy-nvim 'session'
            '';
          }
          {
            plugin = continuum;
            extraConfig = ''
              set -g @continuum-restore 'on'
              set -g @continuum-save-interval '15'
            '';
          }
        ];

        extraConfig = ''
          # Terminal behavior
          set -as terminal-features ",*:RGB"
          set -as terminal-features ",*:extkeys"
          set -s extended-keys on
          set -g set-clipboard on
          set -g renumber-windows on
          set -g detach-on-destroy off
          set -g set-titles on
          set -g set-titles-string "#S:#I #W"
          set -g automatic-rename on
          set -g automatic-rename-format "#{b:pane_current_path}"
          set -g word-separators " -_@./"
          set -s copy-command 'if command -v wl-copy >/dev/null 2>&1; then wl-copy; elif command -v clip.exe >/dev/null 2>&1; then clip.exe; elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard -in; fi'

          # Windows and panes inherit the active working directory
          bind -N "Create window here" c new-window -c "#{pane_current_path}"
          bind -N "Split pane right" | split-window -h -c "#{pane_current_path}"
          bind -N "Split pane below" - split-window -v -c "#{pane_current_path}"
          unbind '"'
          unbind %

          bind -r -N "Select previous window" p previous-window
          bind -r -N "Select next window" n next-window
          bind -r -N "Select last window" Tab last-window
          bind -N "Swap pane backward" < swap-pane -U
          bind -N "Swap pane forward" > swap-pane -D
          bind -N "Create a named session" N command-prompt -p "new session:" "new-session -A -s '%%'"

          # Useful popups keep the main layout intact
          bind -N "Open scratch terminal" Space display-popup -d "#{pane_current_path}" -w "90%" -h "90%" -E
          bind -N "Open lazygit" g if-shell 'command -v lazygit >/dev/null 2>&1' 'display-popup -d "#{pane_current_path}" -w "95%" -h "95%" -E lazygit' 'display-message "lazygit is not installed"'
          bind -N "Show key bindings" ? display-popup -T " tmux key bindings " -w "85%" -h "85%" -E "tmux list-keys -N | sort | less -R"

          # Vim-style copy mode with system clipboard integration
          bind -T copy-mode-vi v send -X begin-selection
          bind -T copy-mode-vi V send -X select-line
          bind -T copy-mode-vi C-v send -X rectangle-toggle
          bind -T copy-mode-vi y send -X copy-selection-and-cancel
          bind -T copy-mode-vi Escape send -X cancel
          bind -N "Paste latest buffer" P paste-buffer

          # Reload the Home Manager generated config
          bind -N "Reload tmux configuration" r source-file ~/.config/tmux/tmux.conf \; display-message "tmux configuration reloaded"

          # Quiet one-line status, shaped like the Neovim statusline
          set -g status on
          set -g status-position bottom
          set -g status-interval 5
          set -g status-justify left
          set -g status-left-length 32
          set -g status-right-length 120
          set -g status-style "bg=default,fg=colour15"
          set -g status-left "#[bg=colour12,fg=colour0,bold] #{?client_prefix,COMMAND,#S} #[default]"
          set -g status-right "#[fg=colour8]#{b:pane_current_path}  #[fg=colour12]│ #[fg=colour15]#{user}@#H  #[fg=colour12]│ #[fg=colour15]%a %d %b  %H:%M "

          set -g window-status-separator ""
          set -g window-status-format "#[fg=colour8] #I #W#{?window_zoomed_flag, 󰊓,} "
          set -g window-status-current-format "#[bg=colour0,fg=colour12,bold] #I #W#{?window_zoomed_flag, 󰊓,} "
          set -g window-status-last-style "fg=colour15"
          set -g window-status-activity-style "fg=colour12,bold"
          set -g window-status-bell-style "fg=colour9,bold"

          # Focus, prompts, menus, and popups share one accent
          set -g pane-border-status off
          set -g pane-border-style "fg=colour8"
          set -g pane-active-border-style "fg=colour12"
          set -g display-panes-colour colour8
          set -g display-panes-active-colour colour12
          set -g message-style "bg=colour0,fg=colour15"
          set -g message-command-style "bg=colour12,fg=colour0,bold"
          set -g mode-style "bg=colour12,fg=colour0,bold"
          set -g clock-mode-colour colour12
          set -g popup-style "bg=colour0,fg=colour15"
          set -g popup-border-style "fg=colour12"
          set -g menu-style "bg=colour0,fg=colour15"
          set -g menu-selected-style "bg=colour12,fg=colour0,bold"
          set -g menu-border-style "fg=colour12"

          # Wallust supplies the live desktop palette.
          if-shell 'test -f ~/.config/tmux/wallust.conf' 'source-file ~/.config/tmux/wallust.conf'
        '';
      };
    };
}
