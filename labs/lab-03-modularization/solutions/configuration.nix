# Lab 3 標準答案：使用 dev-tools 模組的 configuration.nix（桌面工作站場景）
#
# 三個場景中的「場景一」完整版本；伺服器與不啟用兩種場景請見 README。

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/dev-tools.nix
  ];

  # 啟用開發工具
  my.devTools = {
    enable        = true;
    editor        = "neovim";
    enableGui     = true;
    languages     = [ "python" "rust" ];
    extraPackages = with pkgs; [ jq httpie ];
    gitUserName   = "Alice Chen";
  };

  # enableGui = true 需要 xserver 才能通過 assertion
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  networking.hostName = "alice-desktop";
  time.timeZone       = "Asia/Taipei";

  users.users.alice = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "networkmanager" ];
    shell        = pkgs.bash;
  };

  system.stateVersion = "25.05";
}
