{ config, ... }:

{
  services.nginx.virtualHosts."deskrejection.com" = {
    enableACME = true;
    forceSSL = true;
    root = "/var/deskrejection";
  };

  eilean.services.dns.zones."deskrejection.com".records = [
      {
        name = "deskrejection.com.";
        type = "CNAME";
        value = "vps";
      }
      {
        name = "www.deskrejection.com.";
        type = "CNAME";
        value = "vps";
      }
  ];
}
