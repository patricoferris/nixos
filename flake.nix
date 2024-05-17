{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    eilean.url = "github:RyanGibb/eilean-nix/main";
    eilean.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin";
    agenix.url = "github:ryantm/agenix";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    neovim.url =
      "github:neovim/neovim/f40df63bdca33d343cada6ceaafbc8b765ed7cc6?dir=contrib";
    ryan-nixos.url = "github:RyanGibb/nixos";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, eilean, home-manager, darwin
    , neovim, agenix, ... }@inputs:
      let
        getSystemOverlays = system: nixpkgsConfig: [
                  (final: prev: {
                    overlay-unstable = import nixpkgs-unstable {
                      inherit system;
                      # follow stable nixpkgs config
              config = nixpkgsConfig;
                    };
                    russ = prev.callPackage ./pkgs/russ.nix { };
                    agenix =
                      agenix.packages.${system}.default;
                    mautrix-signal = final.overlay-unstable.mautrix-signal;
                    neovim-unwrapped =
                      neovim.packages.${system}.default;
                  })
      ];
      in
      rec {
      nixosConfigurations = {
        sirref = nixpkgs.lib.nixosSystem {
          system = null;
          pkgs = null;
          specialArgs = inputs;
          modules = [
            ./hosts/sirref/configuration.nix
            eilean.nixosModules.default
            home-manager.nixosModule
            agenix.nixosModules.default
            ({ config, ... }: {
              networking.hostName = "sirref";
              home-manager.users.patrick = import ./home/default.nix;
              # pin nix command's nixpkgs flake to the system flake to avoid unnecessary downloads
              nix.registry.nixpkgs.flake = nixpkgs;
              # record git revision (can be queried with `nixos-version --json)
              system.configurationRevision =
                nixpkgs.lib.mkIf (self ? rev) self.rev;
              nixpkgs = {
                config.allowUnfree = true;
                overlays = getSystemOverlays config.nixpkgs.hostPlatform.system config.nixpkgs.config;
              };
            })
          ];
        };
      };

      homeConfigurations = {
        pf341 = let
          system = "x86_64-linux";
          pkgs = nixpkgs.legacyPackages.${system};
        in home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home/default.nix
            {
              nix.package = pkgs.nix;
              home.username = "pf341";
              home.homeDirectory = "/home/pf341";
            }
          ];
        };
        patrickferris = let
          system = "aarch64-darwin";
          pkgs = nixpkgs.legacyPackages.${system};
        in home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home/default.nix
            {
              nix.package = pkgs.nix;
              nixpkgs.overlays = getSystemOverlays "aarch64-darwin" { };
              home.username = "patrickferris";
              home.homeDirectory = "/Users/patrickferris";
              custom.calendar.enable = true;
            }
          ];
        };
      };

      darwinConfigurations = {
        hostname = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            # TODO
            # ./hosts/macos/default.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.patrick = import ./home/default.nix;
              nixpkgs.overlays = getSystemOverlays "aarch64-darwin" { };
            }
          ];
        };
      };

      formatter = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed
        (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
