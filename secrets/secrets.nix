let
  user = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFiobEqDGuy5NpMIh3JDZ5cMO0EbgYAFtDUWGObkpO6+ patrick@sirref.org"
  ];
  sirref =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFwt/dlycqE/yL/LkS0aBP+cOD5dRzvzH5VUjg+4tPX5";
  maple =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINOSSxTeL83eqW7kvZVrj1kuiDgG9VJhTRmwC1eAK+Cf patrick@framework";
in {
  "email-patrick.age".publicKeys = user ++ [ sirref ];
  "email-system.age".publicKeys = user ++ [ sirref ];
  "cal-patrick.age".publicKeys = user ++ [ sirref ];
  "cal-deskrejection.age".publicKeys = user ++ [ sirref ];
  "cal-metrick.age".publicKeys = user ++ [ sirref ];
  "eon-capnp.age".publicKeys = user ++ [ sirref ];
  "eon-freumh-primary.age".publicKeys = user ++ [ sirref ];
  "restic-maple.age".publicKeys = user ++ [ maple ];
  "restic-env.age".publicKeys = user ++ [ maple ];
  "restic-name.age".publicKeys = user ++ [ maple ];
}
