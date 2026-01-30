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
  boot.zfs.extraPools = [ "spruce" ];

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
  };

  home-manager.users.${config.custom.username} = {
    custom = {
      machineColour = "magenta";
    };
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [ git agenix ];

  programs.bash.promptInit = ''
    PS1='\u@\h:\w \$ '
  '';

  users.users = rec {
    patrick = {
      isNormalUser = true;
      extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      initialHashedPassword = root.initialHashedPassword;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFiobEqDGuy5NpMIh3JDZ5cMO0EbgYAFtDUWGObkpO6+"
      ];
    };
    technical_support = {
      isNormalUser = true;
      extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILpJ2Y1tRU37NQBy6sP+Cz/iNiJ6ZGqlIDeBR5bx+oEl ryan@freumh.org"
      ];
    };
    root = {
      initialHashedPassword =
        "$y$j9T$Z8Fs2l74CgVO/t1ZSNmo./$GvOWgmfjNS.CmkzYTXYYkzgFKRMdAaqe1sXSZrJlqI.";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFiobEqDGuy5NpMIh3JDZ5cMO0EbgYAFtDUWGObkpO6+"
      ];
    };
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # services.immich = {
  #   enable = true;
  #   mediaLocation = "/spruce/immich";
  # };

  # services.nginx = {
  #   virtualHosts = {
  #     "photos.sirref.org" = {
  #       onlySSL = true;
  #       enableACME = true;
  #       locations."/" = {
  #         proxyPass = with config.services.immich; ''
  #           http://${host}:${builtins.toString port}
  #         '';
  #         proxyWebsockets = true;
  #       };
  #     };
  #   };
  # };

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
  services.postgresql.package = pkgs.postgresql_13;

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
