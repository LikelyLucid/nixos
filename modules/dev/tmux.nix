{ pkgs, ... }:
{
  home.packages = with pkgs; [ tmux ];
  
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    historyLimit = 50000;
    keyMode = "vi";
    mouse = true;
    
    extraConfig = ''
      # Prefix: Ctrl+A (like screen)
      unbind C-b
      set -g prefix C-a
      bind C-a send-prefix
      
      # Split panes with | and -
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %
      
      # Reload config
      bind r source-file ~/.tmux.conf
      
      # Status bar
      set -g status-style "bg=#1e1e2e,fg=#cdd6f4"
      set -g status-left "#[fg=#89b4fa,bold] #S "
      set -g status-right "#[fg=#a6e3a1] %H:%M #[fg=#cba6f7]#(curl -s wttr.in/?format='%t') "
      
      # Pane borders
      set -g pane-border-style "fg=#45475a"
      set -g pane-active-border-style "fg=#89b4fa"
      
      # Messages
      set -g message-style "bg=#313244,fg=#cdd6f4"
      
      # Enable true color
      set -ga terminal-overrides ",xterm-256color:Tc"
    '';
  };
}
