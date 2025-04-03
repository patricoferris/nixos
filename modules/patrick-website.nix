{ config, lib, ... }:

let cfg = config.custom.patrick-website;
in {
  options.custom.patrick-website.enable = lib.mkEnableOption "patrick-website";

  config = lib.mkIf cfg.enable {
    services.nginx.virtualHosts."patrick.${config.networking.domain}" = {
      enableACME = true;
      forceSSL = true;
      root = "/var/www";
    };

    eilean.services.dns.zones.${config.networking.domain}.records = [
      {
        name = "patrick.${config.networking.domain}.";
        type = "CNAME";
        value = "vps";
      }
      {
        name = "www.patrick.${config.networking.domain}.";
        type = "CNAME";
        value = "vps";
      }
    ];
  };
}
