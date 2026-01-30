{ config, lib, ... }:

let cfg = config.custom.dispatch-website;
in {
  options.custom.dispatch-website.enable = lib.mkEnableOption "dispatch-website";

  config = lib.mkIf cfg.enable {
    services.nginx.virtualHosts."dispatch.${config.networking.domain}" = {
      enableACME = true;
      forceSSL = true;
      root = "/var/www-dispatch";
      extraConfig = ''
        auth_basic "Restricted";
        auth_basic_user_file /etc/nginx/dispatch.htpasswd;
      '';
    };

    eilean.services.dns.zones.${config.networking.domain}.records = [
      {
        name = "dispatch.${config.networking.domain}.";
        type = "CNAME";
        value = "vps";
      }
      {
        name = "www.dispatch.${config.networking.domain}.";
        type = "CNAME";
        value = "vps";
      }
    ];
  };
}
