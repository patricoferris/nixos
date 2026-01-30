{ pkgs, config, ... }:

{
  age.identityPaths = [ "/home/patrick/.ssh/id_ed25519" ];
  age.secrets = {
    restic-maple.file = ../../secrets/restic-maple.age;
    "restic.env".file = ../../secrets/restic-env.age;
    restic-name.file = ../../secrets/restic-name.age;
  };

  services.restic.backups.${config.networking.hostName} = {
    initialize = true;

    environmentFile = config.age.secrets."restic.env".path;
    repositoryFile = config.age.secrets.restic-name.path;
    passwordFile = config.age.secrets.restic-maple.path;

    paths = [
      "/home"
    ];

    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 12"
    ];
  };
}
