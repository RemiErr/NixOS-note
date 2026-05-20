# Lab 7 任務二標準答案：重構後的 module-a
#
# 不再決定 services.nginx.enable，
# 只在 nginx 已啟用時補上額外的 nginx 配置。

{ config, lib, pkgs, ... }:

{
  services.nginx = lib.mkIf config.services.nginx.enable {
    virtualHosts."localhost" = {
      root = "/var/www/html";
    };
  };
}
