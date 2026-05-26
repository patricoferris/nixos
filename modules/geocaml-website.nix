{ config, lib, ... }:

let
  cfg = config.custom.geocaml-website;
in
{
  options.custom.geocaml-website.enable = lib.mkEnableOption "geocaml-website";

  config = lib.mkIf cfg.enable {
    services.nginx.virtualHosts."geocaml.org" = {
      enableACME = true;
      forceSSL = true;
      root = "/var/www-geocaml";
    };
  };
}
