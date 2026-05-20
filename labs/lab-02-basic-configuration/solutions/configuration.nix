# Lab 2 標準答案：模組化後的入口檔
#
# 重構後的 configuration.nix 只保留三類設定：
#   1. imports 列表（模組目錄頁）
#   2. 機器唯一識別（hostname、stateVersion）
#   3. Bootloader（與硬體密切相關）

{ config, pkgs, ... }:

{
  imports = [
    # 硬體配置：由安裝程序自動生成，請不要修改
    ./hardware-configuration.nix

    # 功能模組
    ./users.nix
    ./packages.nix
    ./services.nix
    ./desktop.nix
    ./security.nix    # Step 8 新增
  ];

  # 主機唯一識別
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # 時區與語言
  time.timeZone = "Asia/Taipei";
  i18n.defaultLocale = "en_US.UTF-8";

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # System State Version：第一次安裝後不要修改
  system.stateVersion = "25.05";
}
