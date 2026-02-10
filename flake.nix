{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    eilean.url = "github:RyanGibb/eilean-nix/main";
    eilean.inputs.nixpkgs.follows = "nixpkgs";
    eon.url = "github:RyanGibb/eon";
    eilean.inputs.eon.follows = "eon";
    msh.url = "git+https://tangled.org/patrick.sirref.org/merry?submodules=true";
    msh.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin";
    agenix.url = "github:ryantm/agenix";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    rss_to_mail.url = "github:Julow/rss_to_mail";
    sherlorocq.url = "github:patricoferris/sherlorocq";
    sherlorocq.inputs.nixpkgs.follows = "nixpkgs";
    nur.url =
      "github:nix-community/NUR/e9e77b7985ef9bdeca12a38523c63d47555cc89b";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, eilean, home-manager, darwin, agenix, rss_to_mail, sherlorocq, nur, msh, ...
    }@inputs:
    let
      getSystemOverlays = system: nixpkgsConfig: [
        (final: prev: {
          overlay-unstable = import nixpkgs-unstable {
            inherit system;
            # follow stable nixpkgs config
            config = nixpkgsConfig;
          };
          msh = msh.packages.${system}.default;
          lima = (prev.callPackage
            "${prev.path}/pkgs/applications/virtualization/lima/default.nix" {
              sigtool = prev.darwin.sigtool;
              buildGoModule = args:
                prev.buildGoModule (args // rec {
                  version = "0.23.2";
                  src = prev.fetchFromSourcehut {
                    owner = "lima-vm";
                    repo = "lima";
                    rev = "74e2fda81b8d367a3bee3dcec92f2b83f575460b";
                    sha256 =
                      "sha256-rZZAIj7hWmRj9o0FRXN1kWMGNYQEd6YbshqYe+WUNeo=";
                  };
                  vendorHash =
                    "sha256-DSv4U0Dg4zlbzN0Jsiw793z4zu0a+BmcGo9QQUrencE=";
                  buildPhase = ''
                    runHook preBuild
                    make "VERSION=v${version}" binaries
                    runHook postBuild
                  '';
                });
            });
          agenix = agenix.packages.${system}.default;
          rss_to_mail = rss_to_mail.packages.${system}.rss_to_mail;
          sherlorocq = sherlorocq.packages.${system}.sherlorocq;
          isync = prev.isync.override { withCyrusSaslXoauth2 = true; };
        })
        nur.overlays.default
      ];
    in {
      nixosConfigurations = {
        oak = nixpkgs.lib.nixosSystem {
          system = null;
          pkgs = null;
          specialArgs = inputs;
          modules = [
            ./hosts/oak/configuration.nix
            ./modules/default.nix
            eilean.nixosModules.default
            home-manager.nixosModules.default
            agenix.nixosModules.default
            ({ config, ... }: {
              networking.hostName = "oak";
              # pin nix command's nixpkgs flake to the system flake to avoid unnecessary downloads
              nix.registry.nixpkgs.flake = nixpkgs;
              # record git revision (can be queried with `nixos-version --json)
              system.configurationRevision =
                nixpkgs.lib.mkIf (self ? rev) self.rev;
              nixpkgs = {
                config.allowUnfree = true;
                config.permittedInsecurePackages = [ "olm-3.2.16" ];
                overlays = getSystemOverlays config.nixpkgs.hostPlatform.system
                  config.nixpkgs.config;
              };
            })
          ];
        };
        maple = nixpkgs.lib.nixosSystem {
          system = null;
          pkgs = null;
          specialArgs = inputs;
          modules = [
            ./hosts/maple/configuration.nix
            ./modules/default.nix
            ./modules/asdbctl.nix
            eilean.nixosModules.default
            home-manager.nixosModules.default
            agenix.nixosModules.default
            ({ config, ... }: {
              networking.hostName = "maple";
              # pin nix command's nixpkgs flake to the system flake to avoid unnecessary downloads
              nix.registry.nixpkgs.flake = nixpkgs;
              # record git revision (can be queried with `nixos-version --json)
              system.configurationRevision =
                nixpkgs.lib.mkIf (self ? rev) self.rev;
              nixpkgs = {
                config.allowUnfree = true;
                config.permittedInsecurePackages = [ "olm-3.2.16" ];
                overlays = getSystemOverlays config.nixpkgs.hostPlatform.system
                  config.nixpkgs.config;
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
              nixpkgs.overlays = getSystemOverlays "x86_64-linux" { };
              custom.nvim-lsps = true;
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
              custom.nvim-lsps = true;
              home.packages = with pkgs; [ lima ];
              programs.zsh.initExtra = ''
                # Nix
                if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
                  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
                fi
                # End Nix
              '';
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

      legacyPackages = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed
        (system: {
          nixpkgs = import nixpkgs {
            inherit system;
            overlays = getSystemOverlays system { };
          };
        });

      formatter = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed
        (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
