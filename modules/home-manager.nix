{ config, lib, ... }@inputs:

let cfg = config.custom.homeManager;
in {
  options.custom.homeManager.enable = lib.mkEnableOption "homeManager";

  config = lib.mkIf cfg.enable {
    home-manager = {
      useGlobalPkgs = true;
      users.${config.custom.username} = import ../home/default.nix;
    };
    # zsh completion
    environment.pathsToLink = [ "/share/zsh" ];
  };
}
