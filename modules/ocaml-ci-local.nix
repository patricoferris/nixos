{ config, lib, pkgs, ... }:

let cfg = config.custom.ocaml-ci-local;
in {
  options.custom.ocaml-ci-local.enable = lib.mkEnableOption "ocaml-ci-local";

  config = lib.mkIf cfg.enable {
    services.nginx = {
      virtualHosts."tests.sirref.org" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:9999";
          extraConfig = ''
            add_header X-Frame-Options SAMEORIGIN always;
            add_header Content-Security-Policy "frame-ancestors 'self';" always;
          '';
        };
      };
    };

    systemd.services.ocaml-ci-local = {
      enable = true;
      path = with pkgs; [ docker git solver-service graphviz ];
      description = "Local testing infrastructure.";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        WorkingDirectory = "/infra";
        Requires = "docker.service";
        ExecStart = pkgs.writeScript "ocaml-ci-local.sh" ''
          #!${pkgs.bash}/bin/bash
          run_local () {
            for dir in $@; do
              echo "Maybe runnning $dir" >2
              echo $dir
            done | grep -v "shell-commands" | xargs -- ${pkgs.ocaml-ci-service}/bin/ocaml-ci-local --port=9999 -v
          }

          echo "Starting ocaml-ci-local"
          echo "Docker check: $(docker --version)"
          echo "Running as: $(whoami)"

          run_local /var/lib/git/repos/* 
        '';
        Restart = "on-failure";
      };
    };

    eilean.services.dns.zones.${config.networking.domain}.records = [{
      name = "tests.${config.networking.domain}.";
      type = "CNAME";
      value = "vps";
    }];
  };
}
