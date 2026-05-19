# 注意：hostname 來自 flake.nix 的 specialArgs
{ config, pkgs, lib, hostname, ... }:

{
  # ── 主機識別（從 specialArgs 取得）──────────────────────────
  networking.hostName = hostname;

  # ── 開機設定 ──────────────────────────────────────────────────
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── 時間同步 ──────────────────────────────────────────────────
  services.timesyncd.enable = true;
  time.timeZone = "Asia/Taipei";

  # ── 基礎安全 ──────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin        = "no";
    };
  };

  networking.firewall.enable = true;

  # ── 部署帳號（所有主機共用）─────────────────────────────────
  users.users.deploy = {
    isNormalUser = true;
    extraGroups  = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # 將此公鑰替換為你的管理工作站的 SSH 公鑰
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... deploy@management"
    ];
  };

  # ── Nix 設定 ──────────────────────────────────────────────────
  nix = {
    settings = {
      # 啟用 Flakes 功能
      experimental-features = [ "nix-command" "flakes" ];
      # 自動最佳化 Store
      auto-optimise-store   = true;
    };
    gc = {
      automatic = true;
      dates     = "weekly";
      options   = "--delete-older-than 14d";
    };
  };

  # ── 基礎工具 ──────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    curl
    wget
  ];

  system.stateVersion = "25.05";
}
