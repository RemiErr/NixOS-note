# Lab 6 標準答案：flake.nix（laptop + server + home-manager 整合）

{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations = {

        laptop = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/laptop/default.nix

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs    = true;
                useUserPackages  = true;
                users.alice      = import ./home/alice/default.nix;
              };
            }
          ];
        };

        server = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/server/default.nix
          ];
        };
      };
    };
}
