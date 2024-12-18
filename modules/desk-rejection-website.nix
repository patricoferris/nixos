{ config, lib, ... }:

let cfg = config.custom.deskrejection-website;
in {
  options.custom.deskrejection-website.enable =
    lib.mkEnableOption "deskrejection-website";

  config = lib.mkIf cfg.enable {
    services.nginx.virtualHosts."deskrejection.com" = {
      enableACME = true;
      forceSSL = true;
      root = "/var/deskrejection";
      locations."/fonts/".extraConfig = ''
        alias /var/deskrejection/fonts/;
      '';
    };
  };
}
