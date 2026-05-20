# Lab 7 任務二標準答案：用「重構模組架構」消除 option conflict
#
# 原本的 module-a / module-b 都設定 services.nginx.enable，造成衝突。
# 重構後：module-a 改為「只在 nginx 已啟用時才加額外設定」，
# 由最上層配置統一決定是否啟用 nginx，module-b 不再需要。

{ config, pkgs, lib, ... }:

{
  imports = [
    ./module-a-fixed.nix
    # ./module-b.nix  ← 不再需要
  ];

  # 由最上層統一決定
  services.nginx.enable = true;

  networking.hostName = "nixos";
  system.stateVersion = "25.05";
}
