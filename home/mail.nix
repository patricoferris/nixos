{ pkgs, config, lib, ... }:

let
  address-book = pkgs.writeScriptBin "address-book" ''
    #!/usr/bin/env bash
    ${pkgs.mu}/bin/mu cfind "$1" | sed -E 's/(.*) (.*@.*)/\2\t\1/'
    ${pkgs.ugrep}/bin/ugrep -jPh -m 100 --color=never "$1" cat ${config.accounts.email.maildirBasePath}/addressbook/cam-ldap)
  '';
  sync-mail = pkgs.writeScriptBin "sync-mail" ''
    ${pkgs.isync}/bin/mbsync "$1" || exit 1
    ${pkgs.mu}/bin/mu index
  '';
  cfg = config.custom.mail;
  mutt-oauth2 = pkgs.stdenv.mkDerivation {
    pname = "mutt-oauth2";
    version = "1.0";

    src = ../scripts;

    buildInputs = [ pkgs.python3 ];

    installPhase = ''
      mkdir -p $out/bin
      cp $src/mutt_oauth2.py $out/bin/mutt_oauth2
      chmod +x $out/bin/mutt_oauth2
      sed -i '1i#!/usr/bin/env python3' $out/bin/mutt_oauth2
    '';
  };
in {
  options.custom.mail.enable = lib.mkEnableOption "mail";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      (pkgs.writeScriptBin "cam-ldap-addr" ''
        ${pkgs.openldap}/bin/ldapsearch -xZ -H ldaps://ldap.lookup.cam.ac.uk -b "ou=people,o=University of Cambridge,dc=cam,dc=ac,dc=uk" displayName mail\
        | ${pkgs.gawk}/bin/awk '/^dn:/{displayName=""; mail=""; next} /^displayName:/{displayName=$2; for(i=3;i<=NF;i++) displayName=displayName " " $i; next} /^mail:/{mail=$2; next} /^$/{if(displayName!="" && mail!="") print mail "\t" displayName}'\
        > ${config.accounts.email.maildirBasePath}/addressbook/cam-ldap
      '')
      address-book
      sync-mail
      pinentry-qt
    ];

    programs = {
      password-store.enable = true;
      gpg.enable = true;
      mbsync.enable = true;
      mu.enable = true;
      msmtp.enable = true;
      aerc = {
        enable = true;
        extraConfig = {
          general.unsafe-accounts-conf = true;
          general.default-save-path = "~/downloads";
          general.pgp-provider = "gpg";
          ui.mouse-enabled = true;
          compose.address-book-cmd = "${address-book}/bin/address-book '%s'";
          compose.file-picker-cmd =
            "${pkgs.ranger}/bin/ranger --choosefiles=%f";
          compose.format-flowed = true;
          ui.index-columns = "date<=,name<50,flags>=,subject<*";
          ui.column-name = "{{index (.From | persons) 0}}";
          "ui:folder=Sent".index-columns = "date<=,to<50,flags>=,subject<*";
          "ui:folder=Sent".column-to = "{{index (.To | persons) 0}}";
          openers."text/html" = "firefox --new-window";
          hooks.mail-recieved = ''
            notify-send "[$AERC_ACCOUNT/$AERC_FOLDER] mail from $AERC_FROM_NAME" "$AERC_SUBJECT"'';
          filters = {
            "text/plain" = "wrap -w 90 | colorize";
            "text/calendar" = "calendar";
            "application/ics" = "calendar";
            "message/delivery-status" = "colorize";
            "message/rfc822" = "colorize";
            "text/html" = "html | colorize";
          };
        };
        extraBinds = import ./aerc-binds.nix { inherit pkgs; };
      };
    };

    services = {
      imapnotify.enable = true;
      gpg-agent = {
        enable = true;
        pinentry.package = pkgs.pinentry-qt;
      };
    };

    accounts.email = {
      maildirBasePath = "mail";
      accounts = {
        "patrick@sirref.org" = rec {
          primary = true;
          realName = "Patrick Ferris";
          userName = "patrick@sirref.org";
          address = "patrick@sirref.org";
          passwordCommand =
            "${pkgs.pass}/bin/pass show email/patrick@sirref.org";
          imap.host = "mail.sirref.org";
          smtp = {
            host = "mail.sirref.org";
            port = 465;
          };
          folders = {
            drafts = "Drafts";
            inbox = "Inbox";
            sent = "Sent";
            trash = "Trash";
          };
          imapnotify = {
            enable = true;
            boxes = [ "Inbox" ];
            onNotify = "${sync-mail}/bin/sync-mail patrick@sirref.org:INBOX";
          };
          mbsync = {
            enable = true;
            create = "both";
            expunge = "both";
            remove = "both";
          };
          msmtp = { enable = true; };
          aerc = {
            enable = true;
            extraAccounts = {
              check-mail-cmd = "${sync-mail}/bin/sync-mail patrick@sirref.org";
              check-mail-timeout = "1m";
              check-mail = "1h";
              folders-sort =
                [ "Inbox" "Sent" "Drafts" "Archive" "Spam" "Trash" ];
              folder-map = "${pkgs.writeText "folder-map" ''
                Spam = Junk
                Bin = Trash
              ''}";
            };
          };
        };
        "pf341@cam.ac.uk" = {
          userName = "pf341@cam.ac.uk";
          address = "pf341@cam.ac.uk";
          realName = "Patrick Ferris";
          passwordCommand = "${mutt-oauth2}/bin/mutt_oauth2 -t /home/patrick/.password-store/email/cam.gpg";
          flavor = "outlook.office365.com";
          folders = {
            drafts = "Drafts";
            inbox = "Inbox";
            sent = "Sent";
            trash = "Trash";
          };
          imapnotify = {
            enable = true;
            boxes = [ "Inbox" ];
            onNotify = "${sync-mail}/bin/sync-mail pf341@cam.ac.uk:INBOX";
          };
          mbsync = {
            enable = true;
            create = "both";
            expunge = "both";
            remove = "both";
            extraConfig = {
              account = {
                AuthMechs = "XOAUTH2";
              };
            };
          };
          msmtp = { 
            enable = true;
            extraConfig = {
              auth = "xoauth2";
            };
          };
          aerc = {
            enable = true;
            extraAccounts = {
              check-mail-cmd = "${sync-mail}/bin/sync-mail pf341@cam.ac.uk";
              check-mail-timeout = "1m";
              check-mail = "1h";
              aliases = "pf341@cam.ac.uk";
              folders-sort =
                [ "Inbox" "Sidebox" "Sent" "Drafts" "Archive" "Spam" "Trash" ];
              folder-map = "${pkgs.writeText "folder-map" ''
                Bin = Trash
              ''}";
            };
          };
        };
        "patrickferris17@gmail.com" = rec {
          userName = "patrickferris17@gmail.com";
          address = "patrickferris17@gmail.com";
          realName = "Patrick Ferris";
          passwordCommand =
            "${pkgs.pass}/bin/pass show email/patrickferris17@gmail.com";
          flavor = "gmail.com";
          folders = {
            drafts = "Drafts";
            inbox = "Inbox";
            sent = "Sent Mail";
            trash = "Bin";
          };
          imapnotify = {
            enable = true;
            boxes = [ "Inbox" ];
            onNotify =
              "${sync-mail}/bin/sync-mail patrickferris17@gmail.com:INBOX";
          };
          mbsync = {
            enable = true;
            create = "both";
            expunge = "both";
            remove = "both";
            extraConfig = {
              account = {
                AuthMechs = "LOGIN";
              };
            };
          };
          msmtp = { enable = true; };
          aerc = {
            enable = true;
            extraAccounts = {
              check-mail-cmd =
                "${sync-mail}/bin/sync-mail patrickferris17@gmail.com";
              check-mail-timeout = "1m";
              check-mail = "1h";
              folders-sort = [
                "Inbox"
                "Sidebox"
                "[Gmail]/Sent Mail"
                "[Gmail]/Drafts"
                "[Gmail]/All Mail"
                "[Gmail]/Spam"
                "[Gmail]/Trash"
              ];
              copy-to = "'[Gmail]/Sent Mail'";
              archive = "'[Gmail]/All Mail'";
              postpone = "[Gmail]/Drafts";
            };
          };
        };
        search = {
          maildir.path = "search";
          realName = "Search Index";
          address = "search@local";
          aerc.enable = true;
          aerc.extraAccounts = { source = "maildir://~/mail/search"; };
          aerc.extraConfig = {
            ui = {
              index-columns = "flags>4,date<*,to<30,name<30,subject<*";
              column-to = "{{(index .To 0).Address}}";
            };
          };
        };
      };
    };
  };
}
