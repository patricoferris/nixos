# H/T to Ryan: https://github.com/RyanGibb/nixos/commit/9af693c4e623ce1be96516f221a59192d67540e5
{ pkgs, config, lib, ... }:

let cfg = config.custom.calendar;
in {
  options.custom.calendar.enable = lib.mkEnableOption "calendar";

  config = lib.mkIf cfg.enable {
    programs = {
      password-store.enable = true;
      gpg.enable = true;
      vdirsyncer.enable = true;
      khal = {
        enable = true;
        locale = {
          timeformat = "%I:%M%p";
          dateformat = "%Y-%m-%d";
          longdateformat = "%Y-%m-%d";
          datetimeformat = "%Y-%m-%d %I:%M%p";
          longdatetimeformat = "%Y-%m-%d %I:%M%p";
        };
        settings = { default.default_calendar = "patrick_sirref_org"; };
      };
    };

    services = { vdirsyncer.enable = true; };

    accounts.calendar = {
      basePath = "calendar";
      accounts = {
        "patrick_sirref_org" = {
          khal = {
            enable = true;
            color = "white";
          };
          vdirsyncer = { enable = true; };
          remote = {
            type = "caldav";
            url =
              "https://cal.sirref.org/patrick/803232e5-a529-b6f4-390b-a5ace9248e76/";
            passwordCommand =
              [ "${pkgs.pass}/bin/pass" "show" "calendar/patrick@sirref.org" ];
            userName = "patrick";
          };
          local = {
            type = "filesystem";
            fileExt = ".ics";
          };
        };
      };
    };
  };
}
