# lib/mkHost.nix
# 用法：mkHost { hostname = "web-01"; system = "x86_64-linux"; modules = [...]; }
{ nixpkgs }:

{ hostname, system, modules }:

nixpkgs.lib.nixosSystem {
  inherit system;

  # specialArgs 可以將額外參數傳入所有模組
  specialArgs = {
    inherit hostname;
  };

  modules = [
    # 所有主機都自動載入共用基礎模組
    ../modules/common/base.nix

    # 傳入此函數的主機專屬模組
  ] ++ modules;
}
