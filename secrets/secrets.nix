let
  user = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFiobEqDGuy5NpMIh3JDZ5cMO0EbgYAFtDUWGObkpO6+ patrick@sirref.org"
  ];
  sirref =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFwt/dlycqE/yL/LkS0aBP+cOD5dRzvzH5VUjg+4tPX5";
in {
  "email-patrick.age".publicKeys = user ++ [ sirref ];
  "email-system.age".publicKeys = user ++ [ sirref ];
  "cal-patrick.age".publicKeys = user ++ [ sirref ];
  "cal-deskrejection.age".publicKeys = user ++ [ sirref ];
  "cal-metrick.age".publicKeys = user ++ [ sirref ];
  "eon-capnp.age".publicKeys = user ++ [ sirref ];
  "eon-freumh-primary.age".publicKeys = user ++ [ sirref ];
}
