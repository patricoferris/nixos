{ config, ... }:

{
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
}
