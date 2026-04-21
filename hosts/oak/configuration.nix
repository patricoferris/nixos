{ pkgs, config, lib, ... }:
{
  imports = [ ./hardware-configuration.nix ./networking.nix ];

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
  };
  
  # ZFS modprobe support
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  boot.zfs.extraPools = [ ];

  networking.hostId = "839040b8";

  custom = {
    enable = true;
    homeManager.enable = true;
    patrick-website.enable = true;
    graft-website.enable = true;
    shelter-website.enable = true;
    dispatch-website.enable = true;
    deskrejection-website.enable = true;
    hedgedoc.enable = true;
    sherlorocq.enable = true;
    ocaml-ci-local.enable = true;
    music.enable = true;
  };

  home-manager.users.${config.custom.username} = {
    custom = {
      machineColour = "magenta";
    };
    programs.git.settings.safe.directory = "/var/lib/git/repos/*";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [ git agenix
    #  (
    #   let
    #     # XXX specify the postgresql package you'd like to upgrade to.
    #     # Do not forget to list the extensions you need.
    #     newPostgres = pkgs.postgresql_16.withPackages (pp: [
    #       # pp.plv8
    #     ]);
    #     cfg = config.services.postgresql;
    #   in
    #   pkgs.writeScriptBin "upgrade-pg-cluster" ''
    #     set -eux
    #     # XXX it's perhaps advisable to stop all services that depend on postgresql
    #     systemctl stop matrix-synapse.service
    #     systemctl stop postgresql
    #
    #     export NEWDATA="/var/lib/postgresql/${newPostgres.psqlSchema}"
    #     export NEWBIN="${newPostgres}/bin"
    #
    #     export OLDDATA="/var/lib/postgresql/13"
    #     export OLDBIN="${cfg.finalPackage}/bin"
    #
    #     install -d -m 0700 -o postgres -g postgres "$NEWDATA"
    #     cd "$NEWDATA"
    #     sudo -u postgres "$NEWBIN/initdb" -D "$NEWDATA" ${lib.escapeShellArgs cfg.initdbArgs}
    #
    #     sudo -u postgres "$NEWBIN/pg_upgrade" \
    #       --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
    #       --old-bindir "$OLDBIN" --new-bindir "$NEWBIN" \
    #       "$@"
    #   ''
    # )
  ];

  programs.bash.promptInit = ''
    PS1='\u@\h:\w \$ '
  '';

  users.users = rec {
    patrick = {
      isNormalUser = true;
      extraGroups = [ "wheel" "git" "docker" ]; # Enable ‘sudo’ for the user.
      initialHashedPassword = root.initialHashedPassword;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFiobEqDGuy5NpMIh3JDZ5cMO0EbgYAFtDUWGObkpO6+"
      ];
    };
    # technical_support = {
    #   isNormalUser = true;
    #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    #   openssh.authorizedKeys.keys = [
    #     "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILpJ2Y1tRU37NQBy6sP+Cz/iNiJ6ZGqlIDeBR5bx+oEl ryan@freumh.org"
    #   ];
    # };
    root = {
      extraGroups = [ "git" "docker" ]; # Enable ‘sudo’ for the user.
      initialHashedPassword =
        "$y$j9T$Z8Fs2l74CgVO/t1ZSNmo./$GvOWgmfjNS.CmkzYTXYYkzgFKRMdAaqe1sXSZrJlqI.";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFiobEqDGuy5NpMIh3JDZ5cMO0EbgYAFtDUWGObkpO6+"
      ];
    };
    git = {
      isSystemUser = true;
      extraGroups = [ "git" ];
      description = "git user";
      home = "/var/lib/git/repos";
      shell = "${pkgs.git}/bin/git-shell";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFiobEqDGuy5NpMIh3JDZ5cMO0EbgYAFtDUWGObkpO6+"
      ];
    };
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  services.sshguard = {
    enable = true;
  };

  # CGit config borrowed from Ryan 
  services.cgit."git.sirref.org" = {
    enable = true;
    user = "git";
    group = "git";
    # We use the cgitrc file below for better control.
    # But we have to add a scan path...
    scanPath = "/var/lib/empty";
    gitHttpBackend = {
      enable = true;
      checkExportOkFiles = false;
    };
    settings = {
      root-title = "Sirref Git Repositories";
      root-desc = "List of Sirref development repositories";
      logo = "https://patrick.sirref.org/git-logo.JPG";
      enable-index-owner = false;
      enable-git-config = true;
      clone-url = "https://git.sirref.org/$CGIT_REPO_URL";
      branch-sort = "age";
    };
    extraConfig = ''
    section=Codecs

    repo.url=ocaml-bibtex
    repo.path=/var/lib/git/repos/ocaml-bibtex/.git
    repo.desc=A pure OCaml codec for Bibtex

    section=Shells

    repo.url=merry
    repo.path=/var/lib/git/repos/merry/.git
    repo.desc=An OCaml library for building Shells

    repo.url=bruit
    repo.path=/var/lib/git/repos/bruit/.git
    repo.desc=A pure OCaml port of linenoise (a readline alternative)

    repo.url=shelter
    repo.path=/var/lib/git/repos/shelter/.git
    repo.desc=A time-travelling shell
    '';
  };
  
  virtualisation.docker.enable = true;

  services.nginx.virtualHosts."git.sirref.org" = {
    forceSSL = true;
    enableACME = true;
    locations."= /robots.txt".extraConfig = ''
      return 200 "User-agent: *\nContent-Usage: search=y, train-ai=n\nAllow: /\n\nUser-agent: Amazonbot\nDisallow: /\n\nUser-agent: Applebot-Extended\nDisallow: /\n\nUser-agent: Bytespider\nDisallow: /\n\nUser-agent: CCBot\nDisallow: /\n\nUser-agent: ClaudeBot\nDisallow: /\n\nUser-agent: Google-Extended\nDisallow: /\n\nUser-agent: GPTBot\nDisallow: /\n\nUser-agent: meta-externalagent\nDisallow: /\n";
      default_type text/plain;
    '';
  };

  # Git mirroring cron job
  systemd.timers."git-mirror" = {
    wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5m";
        OnUnitActiveSec = "5m";
        Unit = "git-mirror.service";
      };
  };

  systemd.services."git-mirror" = {
    script = ''
      set -eu
      for repo in /var/lib/git/repos/*.git; do
        echo "Mirroring $repo"
        ${pkgs.git}/bin/git --git-dir $repo push --mirror "git@github.com:patricoferris/$(basename --suffix=".git" $repo)"
      done
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  security.acme.acceptTerms = true;
  security.acme-eon.acceptTerms = true;

  i18n.defaultLocale = "en_GB.UTF-8";
  console.keyMap = "uk";

  age.secrets.cal-patrick = {
    file = ../../secrets/cal-patrick.age;
    mode = "770";
    owner = "${config.systemd.services.radicale.serviceConfig.User}";
    group = "${config.systemd.services.radicale.serviceConfig.Group}";
  };

  age.secrets.cal-deskrejection = {
    file = ../../secrets/cal-deskrejection.age;
    mode = "770";
    owner = "${config.systemd.services.radicale.serviceConfig.User}";
    group = "${config.systemd.services.radicale.serviceConfig.Group}";
  };

  age.secrets.cal-metrick = {
    file = ../../secrets/cal-metrick.age;
    mode = "770";
    owner = "${config.systemd.services.radicale.serviceConfig.User}";
    group = "${config.systemd.services.radicale.serviceConfig.Group}";
  };

  eilean = {
    serverIpv4 = "95.216.193.242";
    serverIpv6 = "2a01:4f9:c010:8298::1";
    publicInterface = "eth0";

    username = "patrick";

    services.dns.server = "eon";

    turn.enable = false;

    mailserver.enable = true;
    matrix = {
      enable = true;
      turn = false;
      bridges.whatsapp = true;
      bridges.signal = true;
    };

    # <><><> Calendar <><><>
    radicale = {
      enable = true;
      users.${config.eilean.username}.passwordFile =
        config.age.secrets.cal-patrick.path;
      users.deskrejection.passwordFile =
        config.age.secrets.cal-deskrejection.path;
      users.metrick.passwordFile = config.age.secrets.cal-metrick.path;
    };

    # mastodon.enable = true;
    # gitea.enable = true;
    # headscale.enable = true;
  };

  # MATRIX PLEASE BE OKAY?!
  services.postgresql.package = pkgs.postgresql_16;

  age.secrets.eon-capnp = {
    file = ../../secrets/eon-capnp.age;
    mode = "770";
    owner = "eon";
    group = "eon";
  };
  age.secrets.eon-freumh-primary = {
    file = ../../secrets/eon-freumh-primary.age;
    mode = "770";
    owner = "eon";
    group = "eon";
  };
  services.eon = {
    capnpSecretKeyFile = config.age.secrets.eon-capnp.path;
    primaries = [ config.age.secrets.eon-freumh-primary.path ];
    capnpAddress = "95.216.193.242";
    logLevel = 0;
  };

  eilean.dns.nameservers = [ ];
  eilean.services.dns.zones = {
    ${config.networking.domain} = {
      records = [
        {
          name = "@";
          type = "NS";
          value = "ns1";
        }
        {
          name = "@";
          type = "NS";
          value = "ns1.freumh.org.";
        }
        {
          name = "ns1";
          type = "A";
          value = config.eilean.serverIpv4;
        }
        {
          name = "ns1";
          type = "AAAA";
          value = config.eilean.serverIpv6;
        }
        {
          name = "_atproto.patrick";
          type = "TXT";
          value = "did=did:plc:vbqt7s7rrltkvlvwavk5ypkf";
        }
        {
          name = "mail._domainkey";
          type = "TXT";
          value =
            "v=DKIM1; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDnHd/+eEPaYxfbqwV5MKWlorOPrOMojqhKaYKJQgzBri7/kj96h8RiTt00AxHUGc5LUAhJnDTEnyn9MEdeB+DYplmn29D9v9M1tWrz1b/kmAmkhacnRGnlIk/mc70Wqfu1W/2jmEYXfXT6wSTq6o/Ch/myI2X8rljYMdmHnlgZjQIDAQAB";
        }
        {
          name = "git.${config.networking.domain}.";
          type = "CNAME";
          value = "vps";
        }
        {
          name = "photos.${config.networking.domain}.";
          type = "CNAME";
          value = "vps";
        }
      ];
    };
    "deskrejection.com" = {
      soa.serial = 1706745602;
      soa.ns = "ns1.sirref.org";
      records = [
        {
          name = "@";
          type = "NS";
          value = "ns1.sirref.org.";
        }
        {
          name = "@";
          type = "NS";
          value = "ns1.freumh.org.";
        }
        {
          name = "@";
          type = "A";
          value = config.eilean.serverIpv4;
        }
        {
          name = "@";
          type = "AAAA";
          value = config.eilean.serverIpv6;
        }
      ];
    };
  };

  # <><><> Email <><><>
  age.secrets.email-patrick.file = ../../secrets/email-patrick.age;
  age.secrets.email-system.file = ../../secrets/email-system.age;
  eilean.mailserver.systemAccountPasswordFile =
    config.age.secrets.email-system.path;
  mailserver.stateVersion = lib.mkDefault 3;
  mailserver.loginAccounts = {
    "${config.eilean.username}@${config.networking.domain}" = {
      passwordFile = config.age.secrets.email-patrick.path;
      aliases = [
        "dns@${config.networking.domain}"
        "postmaster@${config.networking.domain}"
      ];
    };
    "misc@${config.networking.domain}" = {
      passwordFile = config.age.secrets.email-patrick.path;
      catchAll = [ "${config.networking.domain}" ];
    };
  };

  services.rss_to_mail = {
    enable = true;
    users = [ "patrick" ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11";
}
