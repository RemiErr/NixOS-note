# Lab 7 任務三 / 任務四標準答案：載入修復後的服務配置
#
# 切換 modules 中引用的檔案，即可切換到不同任務的修復版本。

{
  description = "Lab 7 debugging sandbox (fixed)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # 任務一：./fixed-config-1.nix
        # 任務二：./conflict-resolved.nix
        # 任務三：./fixed-service-v2.nix
        ./fixed-service-v2.nix
      ];
    };
  };
}
