{
  description = "NixOS 多主機基礎設施配置";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ... }:
    let
      # 載入輔助函數模組
      lib      = nixpkgs.lib;
      mkHost   = import ./lib/mkHost.nix { inherit nixpkgs; };
    in
    {
      nixosConfigurations = {
        # 每台主機對應一個 nixosConfiguration
        # 主機名稱必須與 hosts/ 目錄名稱相同
        web-01 = mkHost {
          hostname = "web-01";
          system   = "x86_64-linux";
          modules  = [
            ./hosts/web-01/configuration.nix
            ./hosts/web-01/hardware-configuration.nix
          ];
        };

        db-01 = mkHost {
          hostname = "db-01";
          system   = "x86_64-linux";
          modules  = [
            ./hosts/db-01/configuration.nix
            ./hosts/db-01/hardware-configuration.nix
          ];
        };
      };
    };
}
