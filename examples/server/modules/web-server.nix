{ config, pkgs, lib, ... }:

{
  # ── ACME（Let's Encrypt 自動憑證）────────────────────────────
  security.acme = {
    acceptTerms = true;
    # 替換為你的實際電子郵件（憑證到期通知用）
    defaults.email = "admin@example.com";
  };

  # ── Nginx 設定 ────────────────────────────────────────────────
  services.nginx = {
    enable = true;

    # 推薦的效能與安全設定
    recommendedGzipSettings    = true;
    recommendedOptimisation    = true;
    recommendedProxySettings   = true;
    recommendedTlsSettings     = true;

    # 虛擬主機設定
    virtualHosts = {
      # 替換 "example.com" 為你的實際網域名稱
      "example.com" = {
        # 啟用 Let's Encrypt HTTPS 憑證
        enableACME  = true;
        # 自動將 HTTP 請求重新導向至 HTTPS
        forceSSL    = true;

        # 靜態網站根目錄
        root = "/var/www/example.com";

        # 也可以改為反向代理到本地應用程式
        # locations."/" = {
        #   proxyPass = "http://127.0.0.1:8080";
        # };
      };

      # 第二個虛擬主機範例（反向代理）
      "api.example.com" = {
        enableACME = true;
        forceSSL   = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:3000";
          # 傳遞真實 IP 給後端應用
          proxyWebsockets = true;
        };
      };
    };
  };
}
