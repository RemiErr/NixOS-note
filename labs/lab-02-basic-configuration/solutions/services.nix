# 系統服務模組
#
# 集中管理後台服務（Background Service），與桌面設定分離。

{ config, pkgs, ... }:

{
  # SSH：禁止密碼登入，只允許金鑰
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  # 印表機支援
  services.printing.enable = true;
}
