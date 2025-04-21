{ config, lib, pkgs, ... }:

let cfg = config.custom.sherlorocq;
in {
  options.custom.sherlorocq.enable = lib.mkEnableOption "sherlorocq";

  config = lib.mkIf cfg.enable {
    services.nginx = {
      virtualHosts."sherlorocq.sirref.org" = {
        forceSSL = true;
        enableACME = true;
        locations."/".proxyPass = "http://localhost:8888";
      };
    };

    systemd.services.sherlorocq = {
      enable = true;
      description = "sherlorocq";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart =
          "${pkgs.sherlorocq}/bin/sherlorocq --static=/var/rocq/static /var/rocq/db";
        Restart = "on-failure";
      };
    };

    eilean.services.dns.zones.${config.networking.domain}.records = [{
      name = "sherlorocq.${config.networking.domain}.";
      type = "CNAME";
      value = "vps";
    }];
  };
}
