{ config, lib, ... }:

let cfg = config.custom.shelter-website;
in {
  options.custom.shelter-website.enable = lib.mkEnableOption "shelter-website";

  config = lib.mkIf cfg.enable {
    services.nginx.virtualHosts."shelter.${config.networking.domain}" = {
      enableACME = true;
      forceSSL = true;
      root = "/var/www-shelter";
    };

    eilean.services.dns.zones.${config.networking.domain}.records = [
      {
        name = "shelter.${config.networking.domain}.";
        type = "CNAME";
        value = "vps";
      }
      {
        name = "www.shelter.${config.networking.domain}.";
        type = "CNAME";
        value = "vps";
      }
    ];
  };
}
