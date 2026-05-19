{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/server-base.nix
    ../../modules/web-server.nix
  ];

  # ── 主機識別 ──────────────────────────────────────────────────
  networking.hostName = "server";

  # ── 開機設定 ──────────────────────────────────────────────────
  # VPS 通常使用 GRUB（非 EFI），請依實際環境調整
  boot.loader.grub = {
    enable  = true;
    device  = "/dev/sda";   # 替換為實際磁碟裝置
  };

  # ── 時區 ──────────────────────────────────────────────────────
  time.timeZone = "Asia/Taipei";

  # ── 日誌管理 ──────────────────────────────────────────────────
  # 限制日誌大小，避免磁碟被日誌塞滿
  services.journald.extraConfig = ''
    SystemMaxUse=2G
    MaxRetentionSec=30day
  '';

  system.stateVersion = "25.05";
}
