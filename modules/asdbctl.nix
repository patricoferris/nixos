{ config, lib, pkgs, ... }:

let
  asdbctl = pkgs.rustPlatform.buildRustPackage {
    pname = "asdbctl";
    version = "0.1.0";

    src = pkgs.fetchFromGitHub {
      owner = "juliuszint";
      repo = "asdbctl";
      rev = "main"; # or a commit hash
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    cargoSha256 = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";
  };
in {
  options.asdbctl.enable = lib.mkEnableOption "Install asdbctl";

  config = lib.mkIf config.asdbctl.enable {
    environment.systemPackages = [ asdbctl ];
  };
}

