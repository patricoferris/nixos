{ config, lib, ... }:

let cfg = config.custom.hedgedoc;
in {
  options.custom.hedgedoc.enable = lib.mkEnableOption "hedgedoc";

  config = lib.mkIf cfg.enable {
    services.nginx = {
      virtualHosts."notes.sirref.org" = {
        forceSSL = true;
        enableACME = true;
        locations."/".proxyPass = "http://localhost:3333";
        locations."/socket.io/" = {
          proxyPass = "http://localhost:3333";
          proxyWebsockets = true;
          extraConfig = "proxy_ssl_server_name on;";
        };
      };
    };

    services.hedgedoc = {
      enable = true;
      settings = {
        db = {
          dialect = "sqlite";
          storage = "/var/lib/hedgedoc/db.hedgedoc.sqlite";
        };
        domain = "notes.sirref.org";
        port = 3333;
        useSSL = false;
        protocolUseSSL = true;
      };
    };

    eilean.services.dns.zones.${config.networking.domain}.records = [{
      name = "notes.${config.networking.domain}.";
      type = "CNAME";
      value = "vps";
    }];
  };
}
