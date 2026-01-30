{ pkgs, config, lib, agenix, ... }:

let cfg = config.custom;
in {
  imports = [
    ./home-manager.nix
    ./patrick-website.nix
    ./graft-website.nix
    ./shelter-website.nix
    ./dispatch-website.nix
    ./desk-rejection-website.nix
    ./rss_to_mail.nix
    ./hedgedoc.nix
    ./scripts.nix
    ./sherlorocq.nix
    ./gui/default.nix
    ./gui/i3.nix
    ./gui/kde.nix
    ./gui/sway.nix
  ];

  options.custom = {
    enable = lib.mkEnableOption "custom";
    username = lib.mkOption {
      type = lib.types.str;
      default = "patrick";
    };
  };

  config = let nixPath = "/etc/nix-path";
  in lib.mkIf cfg.enable {
    console = {
      font = "Lat2-Terminus16";
      keyMap = "uk";
    };
    i18n.defaultLocale = "en_GB.UTF-8";

    networking.domain = lib.mkDefault "sirref.org";

    nix = {
      settings = lib.mkMerge [{
        experimental-features = [ "nix-command" "flakes" ];
        auto-optimise-store = true;
        trusted-users = [ cfg.username ];
      }];
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
      # https://discourse.nixos.org/t/do-flakes-also-set-the-system-channel/19798/16
      nixPath = [ "nixpkgs=${nixPath}" ];
    };
    systemd.tmpfiles.rules = [ "L+ ${nixPath} - - - - ${pkgs.path}" ];

    users = {
      users.${cfg.username} = {
        shell = pkgs.zsh;
        ignoreShellProgramCheck = true;
      };
    };

    environment.systemPackages = with pkgs; [
      nix
      git
      agenix.packages.${system}.default
    ];
  };
}

