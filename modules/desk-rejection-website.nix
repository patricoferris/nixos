{ config, ... }:

{
  services.nginx.virtualHosts."deskrejection.com" = {
    enableACME = true;
    forceSSL = true;
    root = "/var/deskrejection";
    locations."/fonts/".extraConfig = ''
      alias /var/deskrejection/fonts/;
    '';
  };
}
