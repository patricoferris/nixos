{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    eilean.url = "github:RyanGibb/eilean-nix/main";
    eilean.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self, nixpkgs, nixpkgs-unstable, eilean, home-manager, ... }@inputs: rec {
      nixosConfigurations = {
        sirref = nixpkgs.lib.nixosSystem {
          system = null;
          pkgs = null;
          modules = [
            ./hosts/sirref/configuration.nix
            eilean.nixosModules.default
            ({ config, ... }: {
              networking.hostName = "sirref";
              # pin nix command's nixpkgs flake to the system flake to avoid unnecessary downloads
              nix.registry.nixpkgs.flake = nixpkgs;
              # record git revision (can be queried with `nixos-version --json)
              system.configurationRevision =
                nixpkgs.lib.mkIf (self ? rev) self.rev;
              nixpkgs = {
                config.allowUnfree = true;
                overlays = [
                  (final: prev: {
                    overlay-unstable = import nixpkgs-unstable {
                      system = config.nixpkgs.hostPlatform.system;
                      config = config.nixpkgs.config;
                    };
                    mautrix-signal = final.overlay-unstable.mautrix-signal;
                  })
                ];
              };
            })
          ];
        };
      };
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
    };
}
