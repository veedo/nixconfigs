{ self, inputs, ... }:
{
  flake.nixosModules.tmux =
    { pkgs, ... }:
    {
      programs.tmux = {
        enable = true;
        shortcut = "a";
        newSession = true;
        escapeTime = 0;
        historyLimit = 1000000;
        terminal = "screen-256color";
        clock24 = true;
        baseIndex = 1;

        plugins = with pkgs.tmuxPlugins; [
          better-mouse-mode
          sensible
          resurrect
          continuum
        ];

        #  set -g @plugin 'tmux-plugins/tpm'
        #  set -g @plugin 'tmux-plugins/tmux-sensible'
        #  set -g @plugin 'tmux-plugins/tmux-resurrect'
        #  set -g @plugin 'tmux-plugins/tmux-continuum'

        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '5'
          set -g base-index 1

          # Required to pass ctrl-a to a tmux pane
          unbind-key C-a
          bind-key C-a send-prefix

          # split panes using | and -
          bind | split-window -h
          bind - split-window -v
          unbind '"'
          unbind %

          # switch panes using Alt-arrow without prefix
          bind -n M-h select-pane -L
          bind -n M-l select-pane -R
          bind -n M-k select-pane -U
          bind -n M-j select-pane -D

          # Alt + <number> to switch to windows
          bind-key -n M-1 select-window -t 1
          bind-key -n M-2 select-window -t 2
          bind-key -n M-3 select-window -t 3
          bind-key -n M-4 select-window -t 4
          bind-key -n M-5 select-window -t 5

          # Allow ctrl-n/p to be used repeatedly for next/previous window
          bind-key -r ^N next-window
          bind-key -r ^P previous-window

          # K kills the foreqground process
          bind-key k run-shell 'kill -s USR1 -- "-$(ps -o tpgid:1= -p #{pane_pid})"'

          # Enable mouse control (clickable windows, panes, resizable panes)
          set -g mouse on

          # don't rename windows automatically
          set-option -g allow-rename off

          # Use zsh for all shells in case it doesn't figure it out
          set-option -g default-shell /run/current-system/sw/bin/zsh

          run-shell ${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/continuum.tmux
        '';
      };

    };
}
