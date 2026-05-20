# Lab 7 任務三標準答案：用 RuntimeDirectory 修復服務啟動失敗
#
# 原本的問題：WorkingDirectory = "/root" 但 User = "nobody"，
# nobody 沒有讀取 /root 的權限，systemd 在切換工作目錄時就失敗。
#
# 解法：用 RuntimeDirectory 讓 systemd 自動建立並設定權限。

{ config, pkgs, lib, ... }:

{
  networking.hostName = "nixos";

  systemd.services.fixed-webapp-v2 = {
    description = "A webapp - fixed with RuntimeDirectory";
    wantedBy    = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 -m http.server 8080";

      # systemd 自動建立 /run/fixed-webapp-v2 並設為 nobody 擁有
      RuntimeDirectory = "fixed-webapp-v2";
      WorkingDirectory = "/run/fixed-webapp-v2";

      User           = "nobody";
      PrivateTmp     = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 8080 ];
  system.stateVersion = "25.05";
}
