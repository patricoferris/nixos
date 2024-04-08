{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    eilean.url = "github:RyanGibb/eilean-nix/main";
    eilean.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    neovim.url =
      "github:neovim/neovim/f40df63bdca33d343cada6ceaafbc8b765ed7cc6?dir=contrib";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, eilean, home-manager, darwin
    , neovim, ... }@inputs: rec {
      nixosConfigurations = {
        sirref = nixpkgs.lib.nixosSystem {
          system = null;
          pkgs = null;
          modules = [
            ./hosts/sirref/configuration.nix
            eilean.nixosModules.default
            home-manager.nixosModule
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
                overlays = [
                  (final: prev: {
                    overlay-unstable = import nixpkgs-unstable {
                      system = config.nixpkgs.hostPlatform.system;
                      config = config.nixpkgs.config;
                    };
                    mautrix-signal = final.overlay-unstable.mautrix-signal;
                    neovim-unwrapped =
                      neovim.packages.${config.nixpkgs.hostPlatform.system}.default;
                  })
                ];
              };
            })
          ];
        };
      };
      homeConfigurations.pf341 = let
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
      in home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
		  ./home/default.nix
		  {
			  home.stateVersion = "23.11";
			 home.username = "pf341";
			 home.homeDirectory = "/home/pf341";
		  }
		];
      };
      homeConfigurations.patrickferris = let
        system = "aarch64-darwin";
        pkgs = nixpkgs.legacyPackages.${system};
      in home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
		  ./home/default.nix
		  {
             home.stateVersion = "23.11";
			 home.username = "patrickferris";
			 home.homeDirectory = "/Users/patrickferris";
		  }
		];
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
            }
          ];
        };
      };
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
    };
}
