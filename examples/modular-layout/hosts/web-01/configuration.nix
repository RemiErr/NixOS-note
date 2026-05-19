{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/profiles/web-server.nix
  ];

  # 此主機專屬的額外設定（覆蓋或補充 profile 的預設值）
  networking.domain = "example.com";

  # 這台主機的 Nginx 虛擬主機配置
  services.nginx.virtualHosts."web-01.example.com" = {
    enableACME = true;
    forceSSL   = true;
    root       = "/var/www/html";
  };
}
