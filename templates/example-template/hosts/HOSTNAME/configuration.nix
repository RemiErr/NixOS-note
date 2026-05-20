# 主機配置入口（Host Entry Point）
#
# 此檔案只負責：
#   1. 引入 hardware-configuration.nix（由 nixos-generate-config 產生）
#   2. 引入功能模組
#   3. 設定主機唯一識別（hostname、stateVersion）
#
# 功能細節請放到 ../../modules/ 內的對應模組。

{ config, pkgs, ... }:

{
  imports = [
    # ./hardware-configuration.nix   # 真實機器才需要，範例模板省略

    ../../modules/base.nix
    # ../../modules/{{模組 2}}.nix
    # ../../modules/{{模組 3}}.nix
  ];

  # 主機唯一識別
  networking.hostName = "{{主機名}}";

  # Bootloader（依硬體調整）
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # 時區與語言
  time.timeZone = "Asia/Taipei";
  i18n.defaultLocale = "en_US.UTF-8";

  # 系統版本（System State Version）：第一次安裝後不要隨意修改
  system.stateVersion = "25.05";
}
