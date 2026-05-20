# Lab 4 標準答案：networking.nix

{ config, pkgs, ... }:

{
  networking.hostName            = "nixos";
  networking.networkmanager.enable = true;

  networking.firewall = {
    enable          = true;
    allowedTCPPorts = [ 22 ];
    allowedUDPPorts = [ ];
  };

  time.timeZone     = "Asia/Taipei";
  i18n.defaultLocale = "zh_TW.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS   = "zh_TW.UTF-8";
    LC_MONETARY  = "zh_TW.UTF-8";
    LC_PAPER     = "zh_TW.UTF-8";
    LC_TELEPHONE = "zh_TW.UTF-8";
    LC_TIME      = "zh_TW.UTF-8";
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      # PasswordAuthentication = false;  # 確認 SSH 金鑰登入可用後啟用
    };
  };
}
