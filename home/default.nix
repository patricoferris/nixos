{ pkgs, config, lib, ... }:

let
  tmux-sessionizer = pkgs.writeScriptBin "tmux-sessionizer" ''
    #!/usr/bin/env bash

    hist_file=~/.cache/sessionizer.hist

    if [[ $# -eq 1 ]]; then
        selected=$1
    else
        selected=$((tac "$hist_file"
            find ~ -mindepth 1 -maxdepth 3 -type d -not -path '*/[.]*';
            find ~/documents/ -mindepth 1 -maxdepth 2 -type d -not -path '*/[.]*';
            find ~/documents/phd/ -mindepth 1 -maxdepth 2 -type d -not -path '*/[.]*';
            awk '{print "ssh " $1}' ~/.ssh/known_hosts 2>/dev/null | sort -u
            echo /etc/nixos) | awk '!seen[$0]++' | fzf --print-query | tail -n 1)
    fi

    if [[ -z $selected ]]; then
        exit 0
    fi

    echo "$selected" >> $hist_file

    selected_name=$(basename "$selected" | tr . _)
    tmux_running=$(pgrep tmux)

    if [[ $selected == ssh\ * ]]; then
        if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
            tmux new-session -s "$selected_name" "$selected"
            exit 0
        fi

        if ! tmux has-session -t="$selected_name" 2> /dev/null; then
            tmux new-session -ds "$selected_name" "$selected"
        fi
    else
        if [[ -z $TMUX ]] && [[ -z "$tmux_running" ]]; then
            tmux new-session -s "$selected_name" -c "$selected"
            exit 0
        fi

        if ! tmux has-session -t="$selected_name" 2> /dev/null; then
            tmux new-session -ds "$selected_name" -c "$selected"
        fi
    fi


    tmux switch-client -t "$selected_name"
  '';
in {
  imports = [ ./gui/default.nix ./calendar.nix ./nvim/default.nix ./mail.nix ];

  options.custom.machineColour = lib.mkOption {
    type = lib.types.str;
    default = "cyan";
  };

  config = {
    programs.home-manager.enable = true;

    home.packages = with pkgs; [
      fzf
      opam
      graphviz
      sqlite
      gmp
      jq
      htop
      tmux-sessionizer
      man-pages
      man-pages-posix
      dig
      # Geospatial
      qgis
      # Libreoffice and dictionaries
      # libreoffice-qt
      # hunspell
      # hunspellDicts.en_US
      # hunspellDicts.en_GB-ise
      # hunspellDicts.fr-moderne
    ];

    home.sessionVariables = {
      EDITOR = "nvim";
      NIX_AUTO_RUN = "y";
      NIX_AUTO_RUN_INTERACTIVE = "y";
      GOPATH = "$HOME/.go";
    };

    nix = { settings.experimental-features = [ "nix-command" "flakes" ]; };

    programs.tmux = {
      enable = true;
      extraConfig = let
        toggle-status-bar = pkgs.writeScript "toggle-status-bar.sh" ''
          #!/usr/bin/env bash
          window_count=$(tmux list-windows | wc -l)
          if [ "$window_count" -ge "2" ]; then
              tmux set-option status on
          else
              tmux set-option status off
          fi
        '';
        # https://github.com/ThePrimeagen/.dotfiles/blob/master/bin/.local/scripts/tmux-sessionizer
      in ''
        # alternative modifier
        unbind C-b
        set-option -g prefix C-a
        bind-key C-a send-prefix
        set-window-option -g mode-keys vi
        set-option -g mouse on
        set-option -g set-titles on
        set-option -g set-titles-string "#T"
        bind-key t capture-pane -S -\; new-window '(tmux show-buffer; tmux delete-buffer) | nvim -c $'
        bind-key u capture-pane\; new-window '(tmux show-buffer; tmux delete-buffer) | ${pkgs.urlscan}/bin/urlscan'
        set-hook -g session-window-changed 'run-shell ${toggle-status-bar}'
        set-hook -g session-created 'run-shell ${toggle-status-bar}'
        # Fixes C-Up/Down in TUIs
        set-option default-terminal tmux
        # https://stackoverflow.com/questions/62182401/neovim-screen-lagging-when-switching-mode-from-insert-to-normal
        # locking
        set -s escape-time 0
        # for .zprofile display environment starting https://github.com/tmux/tmux/issues/3483
        set-option -g update-environment XDG_VTNR
        # Allow clipboard with OSC-52 work
        set -s set-clipboard on
        # toggle
        bind -r ^ last-window
        # vim copy
        bind -T copy-mode-vi v send-keys -X begin-selection
        bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel
        # find
        bind-key -r f run-shell "tmux neww tmux-sessionizer"
        # reload
        bind-key r source-file ~/.config/tmux/tmux.conf
      '';
    };

    home.shellAliases = {
      ls = "ls -p --color=auto";
      nix-shell = "nix-shell --command zsh";
    };

    programs.gpg = {
      enable = true;
      publicKeys = [{
        text = ''
          -----BEGIN PGP PUBLIC KEY BLOCK-----

          mDMEZ8B0dRYJKwYBBAHaRw8BAQdAYqBYT3Z9J9ekAjaR+7iAMr/0kkvd/pCx58m3
          vZ6bLZy0I1BhdHJpY2sgRmVycmlzIDxwYXRyaWNrQHNpcnJlZi5vcmc+iJQEExYK
          ADwWIQSGsLB/m+O06y3evIjk0qK5+Ce7TQUCZ8B0dQIbAwUJBaOagAQLCQgHBBUK
          CQgFFgIDAQACHgUCF4AACgkQ5NKiufgnu01JFwD9HErFBAvaLciGpl4LIU5iblwv
          /U/WWo6hHsDB6VTsyMQA+wTcpJQVU5X42aCtKI0uKwBVyDu+qa7z1KJc2jjOut8D
          uDgEZ8B0dRIKKwYBBAGXVQEFAQEHQN0kCic5ZfXaDfyLEqtWXHkZVdp/xg4kA5qQ
          6cK1jhBXAwEIB4h+BBgWCgAmFiEEhrCwf5vjtOst3ryI5NKiufgnu00FAmfAdHUC
          GwwFCQWjmoAACgkQ5NKiufgnu02r4gEAsZvbKKJbQ8CxPSMdVJFf9A1r3TgD2MS1
          T1mWwTIwxPUA/2dVS9K9Lz0ysqJUIEi/5RaUg1QOdGaa5oOR4NBvJssD
          =UdAa
          -----END PGP PUBLIC KEY BLOCK-----
        '';
        trust = "ultimate";
      }];
    };

    programs.zsh = {
      enable = true;
      history = {
        size = 1000000;
        path = "$HOME/.histfile";
        share = false;
      };
      enableAutosuggestions = true;
      syntaxHighlighting.enable = true;
      enableCompletion = true;
      initContent = let
        zshConfigEarlyInit = lib.mkOrder 500 ''
          export ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion history)
          export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=5"
          PROMPT='%(?..%F{red}%3?%f )%F{${config.custom.machineColour}}%n@%m%f:%~ %#'$'\n'
        '';
        zshConfig = lib.mkOrder 1000 (builtins.readFile ./zsh.cfg);
      in lib.mkMerge [ zshConfigEarlyInit zshConfig ];
    };

    home.stateVersion = "23.11";
  };
}
