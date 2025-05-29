{
  inputs = {
    nixpkgs-compat.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-neovim.url =
      "github:nixos/nixpkgs/a76212122970925d09aa2021a93e00d359e631dd";
    eilean.url = "github:RyanGibb/eilean-nix/main";
    eilean.inputs.nixpkgs.follows = "nixpkgs";
    eon.url = "github:RyanGibb/eon";
    eilean.inputs.eon.follows = "eon";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin";
    agenix.url = "github:ryantm/agenix";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    neovim.url =
      "github:neovim/neovim/f40df63bdca33d343cada6ceaafbc8b765ed7cc6?dir=contrib";
    rss_to_mail.url = "github:Julow/rss_to_mail";
    rss_to_mail.inputs.nixpkgs.follows = "nixpkgs";
    sherlorocq.url = "github:patricoferris/sherlorocq";
    sherlorocq.inputs.nixpkgs.follows = "nixpkgs";
    nur.url =
      "github:nix-community/NUR/e9e77b7985ef9bdeca12a38523c63d47555cc89b";
  };

  outputs = { self, nixpkgs, nixpkgs-compat, nixpkgs-unstable, nixpkgs-neovim
    , eilean, home-manager, darwin, agenix, rss_to_mail, sherlorocq, nur, ...
    }@inputs:
    let
      getSystemOverlays = system: nixpkgsConfig: [
        (final: prev: {
          overlay-compat = import nixpkgs-compat {
            inherit system;
            # follow stable nixpkgs config
            config = nixpkgsConfig;
          };
          overlay-unstable = import nixpkgs-unstable {
            inherit system;
            # follow stable nixpkgs config
            config = nixpkgsConfig;
          };
          russ = prev.callPackage ./pkgs/russ.nix { };
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
          mautrix-whatsapp = final.overlay-compat.mautrix-whatsapp;
          agenix = agenix.packages.${system}.default;
          rss_to_mail = rss_to_mail.packages.${system}.rss_to_mail;
          sherlorocq = sherlorocq.packages.${system}.sherlorocq;
          neovim-unwrapped =
            (import nixpkgs-neovim { inherit system; }).neovim-unwrapped;
          opam = final.overlay-unstable.opam.overrideAttrs (_: rec {
            version = "2.4.0-alpha1";
            src = final.fetchurl {
              url = "https://github.com/ocaml/opam/releases/download/${version}/opam-full-${version}.tar.gz";
              sha256 = "sha256-kRGh8K5sMvmbJtSAEEPIOsim8uUUhrw11I+vVd/nnx4=";
            };
            patches = [ ./pkgs/opam-shebangs.patch ];
          });
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
            home-manager.nixosModule
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
            eilean.nixosModules.default
            home-manager.nixosModule
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
