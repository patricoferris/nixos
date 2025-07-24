{ config, lib, ... }:

let cfg = config.custom.graft-website;
in {
  options.custom.graft-website.enable = lib.mkEnableOption "graft-website";

  config = lib.mkIf cfg.enable {
    services.nginx.virtualHosts."graft.${config.networking.domain}" = {
      enableACME = true;
      forceSSL = true;
      root = "/var/www-graft";
    };

    eilean.services.dns.zones.${config.networking.domain}.records = [
      {
        name = "graft.${config.networking.domain}.";
        type = "CNAME";
        value = "vps";
      }
      {
        name = "www.graft.${config.networking.domain}.";
        type = "CNAME";
        value = "vps";
      }
    ];
  };
}
