# 安全性模組（Step 8 新增）
#
# 防火牆、sudo 限制、journal 大小控制。
# 展示「新增一個檔 + imports 加一行」即可加入整套安全設定的模組化優勢。

{ config, pkgs, ... }:

{
  # 防火牆：只開放 SSH
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # sudo：只有 wheel 群組可使用
  security.sudo.execWheelOnly = true;

  # systemd journal 大小限制
  services.journald.extraConfig = "SystemMaxUse=1G";
}
