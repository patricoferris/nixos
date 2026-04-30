{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.music;
in
{
  options.custom.music.enable = lib.mkEnableOption "music";

  config = lib.mkIf cfg.enable {

    services.navidrome = {
      enable = true;
      settings = {
        MusicFolder = "/var/music";
        DefaultShareExpiration = "168h"; # 1 week
        EnableSharing = true;
      };
    };

    services.nginx = {
      virtualHosts."music.sirref.org" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:4533";
        };
      };
    };

    eilean.services.dns.zones.${config.networking.domain}.records = [
      {
        name = "music.${config.networking.domain}.";
        type = "CNAME";
        value = "vps";
      }
    ];
  };
}
