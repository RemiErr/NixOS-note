# Lab 1 標準答案：完成 Step 6 後的 configuration.nix
#
# 與安裝程序生成的原始檔案相比，差異在於 environment.systemPackages
# 新增了 htop 與 tree 兩個套件。
#
# 若你執行 nixos-rebuild switch 後出現問題，可用：
#   diff /etc/nixos/configuration.nix solutions/configuration.nix
# 對照差異。

{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-lab";
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Taipei";
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  users.users.alice = {
    isNormalUser = true;
    description = "Alice";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      firefox
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    htop    # Step 6 新增：互動式行程監控工具
    tree    # Step 6 新增：目錄樹狀顯示工具
  ];

  system.stateVersion = "25.05";
}
