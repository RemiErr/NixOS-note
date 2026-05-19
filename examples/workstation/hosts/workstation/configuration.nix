{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/desktop.nix
    ../../modules/development.nix
    ../../modules/user.nix
  ];

  # ── 主機識別 ──────────────────────────────────────────────────
  networking.hostName = "workstation";
  networking.networkmanager.enable = true;

  # ── 開機設定 ──────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── 時區與地區 ────────────────────────────────────────────────
  time.timeZone = "Asia/Taipei";
  i18n.defaultLocale = "zh_TW.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ALL = "zh_TW.UTF-8";
  };

  # ── 基礎套件 ──────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
  ];

  system.stateVersion = "25.05";
}
