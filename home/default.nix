{ pkgs, config, ... }:

{
  programs.home-manager.enable = true;

  home.packages = with pkgs; [ fzf graphviz sqlite gmp ];
  
  nix = {
    package = pkgs.nix;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

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

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    extraPackages = with pkgs; [
      ripgrep
      nixd
      nixfmt
      # stop complaining when launching but a devshell is better
      #ocamlPackages.ocaml-lsp
      #ocamlPackages.ocamlformat
      marksman
      lua-language-server
      ltex-ls
    ];
    extraLuaConfig = builtins.readFile ./nvim.lua;
    # undo transparent background
    # + "colorscheme gruvbox";
    plugins = let
      ltex-ls-nvim = (pkgs.vimUtils.buildVimPlugin {
        pname = "ltex-ls.nvim";
        version = "2.6.0";
        src = pkgs.fetchFromGitHub {
          owner = "vigoux";
          repo = "ltex-ls.nvim";
          rev = "c8139ea6b7f3d71adcff121e16ee8726037ffebd";
          sha256 = "sha256-jY3ALr6h88xnWN2QdKe3R0vvRcSNhFWDW56b2NvnTCs=";
        };
      });
    in with pkgs.vimPlugins; [
      gruvbox-nvim

      telescope-nvim
      telescope-fzf-native-nvim
      trouble-nvim

      pkgs.ripgrep

      {
        plugin = nvim-lspconfig;
        runtime = let
          ml-style = ''
            setlocal expandtab
            setlocal shiftwidth=2
            setlocal tabstop=2
            setlocal softtabstop=2
          '';
        in {
          "ftplugin/mail.vim".text = ''
            let b:did_ftplugin = 1
          '';
          "ftplugin/nix.vim".text = ml-style;
          "ftplugin/ocaml.vim".text = ml-style;
          "after/ftplugin/markdown.vim".text = ''
            set com-=fb:-
            set com+=b:-
            set formatoptions+=ro
          '';
        };
      }

      cmp-nvim-lsp
      cmp-nvim-lsp-signature-help
      cmp-path
      cmp-buffer
      cmp-cmdline
      cmp-spell
      luasnip
      nvim-cmp

      vimtex
      nvim-surround
      comment-nvim

      ltex-ls-nvim
    ];
  };

  home.stateVersion = "23.11";
}
