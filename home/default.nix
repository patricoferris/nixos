{ pkgs, config, ... }:

{
  imports = [ ./calendar.nix ./nvim/default.nix ];
  programs.home-manager.enable = true;

  home.packages = with pkgs; [ fzf graphviz sqlite gmp russ lima ];

  nix = { settings.experimental-features = [ "nix-command" "flakes" ]; };

  programs.tmux = {
    enable = true;
    mouse = true;
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
    initExtraFirst = ''
      export ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion history)
      export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=5"
      PROMPT='%(?..%F{red}%3?%f )%F{cyan}%n@%m%f:%~'$'\n%# '
    '';
    initExtra = builtins.readFile ./zsh.cfg;
  };

  home.stateVersion = "23.11";
}
