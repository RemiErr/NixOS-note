# Lab 2 起始檔案：尚未模組化的「單一大檔」
#
# 此檔案模擬 Lab 1 完成後的狀態，所有設定都堆在 configuration.nix。
# Lab 2 的任務就是把這個檔案拆成多個功能模組。
#
# 使用方式：
#   sudo cp starter/configuration.nix /etc/nixos/configuration.nix
#   sudo nixos-rebuild dry-run    # 確認可建構
# 然後按 Lab 2 README 一步步拆模組。

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # 網路
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # 時區與語言
  time.timeZone = "Asia/Taipei";
  i18n.defaultLocale = "en_US.UTF-8";

  # 使用者
  users.users.alice = {
    isNormalUser = true;
    description = "Alice";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.bash;
  };

  # 桌面環境
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # 音效
  hardware.pulseaudio.enable = false;
  services.pipewire.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.pulse.enable = true;

  # 套件
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    htop
  ];

  # SSH
  services.openssh.enable = true;

  system.stateVersion = "25.05";
}
