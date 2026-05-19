{
  description = "NixOS Homelab 配置（軟路由 + NAS）";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations = {

      # 軟路由：WireGuard VPN + dnsmasq + NAT
      router = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/router/configuration.nix
          # 將 hardware-configuration.nix 產生後加入此處：
          # ./hosts/router/hardware-configuration.nix
        ];
      };

      # NAS：ZFS + Samba + restic 備份
      nas = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nas/configuration.nix
          # 將 hardware-configuration.nix 產生後加入此處：
          # ./hosts/nas/hardware-configuration.nix
        ];
      };

    };
  };
}
