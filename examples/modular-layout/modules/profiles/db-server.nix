{ config, pkgs, lib, ... }:

{
  # ── PostgreSQL 資料庫 ──────────────────────────────────────────
  services.postgresql = {
    enable  = true;
    package = pkgs.postgresql_16;

    # 監聽本機與內網 IP（請依實際環境調整）
    settings = {
      listen_addresses = "localhost";
      max_connections  = 200;
      # 記憶體相關設定（依伺服器規格調整）
      shared_buffers   = "256MB";
    };

    # 建立初始資料庫與使用者
    initialScript = pkgs.writeText "postgresql-init.sql" ''
      CREATE USER appuser WITH PASSWORD 'changeme';
      CREATE DATABASE appdb OWNER appuser;
      GRANT ALL PRIVILEGES ON DATABASE appdb TO appuser;
    '';

    authentication = pkgs.lib.mkOverride 10 ''
      # TYPE   DATABASE  USER      ADDRESS         METHOD
      local    all       all                       trust
      host     all       all       127.0.0.1/32    scram-sha-256
      host     all       all       ::1/128         scram-sha-256
    '';
  };

  # ── 防火牆：只允許本機存取 PostgreSQL ──────────────────────
  networking.firewall = {
    # PostgreSQL 預設連接埠只在本機開放，不對外開放
    allowedTCPPorts = [ ];
  };

  # ── 資料庫備份（每日）────────────────────────────────────────
  services.postgresqlBackup = {
    enable    = true;
    databases = [ "appdb" ];
    location  = "/var/backup/postgresql";
    startAt   = "daily";
  };
}
