{ config, pkgs, lib, ... }:

{
  # ── 開機設定 ──────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── 網路設定 ──────────────────────────────────────────────────
  # 將 "myhostname" 替換為你的主機名稱
  networking.hostName = "myhostname";
  networking.networkmanager.enable = true;

  # ── 時區與地區 ────────────────────────────────────────────────
  time.timeZone = "Asia/Taipei";
  i18n.defaultLocale = "zh_TW.UTF-8";

  # ── 使用者設定 ────────────────────────────────────────────────
  users.users.alice = {
    isNormalUser = true;
    description = "Alice";
    # wheel 允許使用 sudo；networkmanager 允許管理網路
    extraGroups = [ "wheel" "networkmanager" ];
    # 初次設定後請使用 passwd alice 設定密碼
    initialPassword = "changeme";
  };

  # ── 系統套件 ──────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    htop
  ];

  # ── SSH 服務 ──────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # ── 防火牆 ────────────────────────────────────────────────────
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # ── 版本標記 ──────────────────────────────────────────────────
  # 此值決定系統狀態版本，首次安裝後不要更動
  system.stateVersion = "25.05";
}
