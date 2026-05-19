{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/profiles/db-server.nix
  ];

  # 資料庫伺服器通常需要較大的記憶體設定
  services.postgresql.settings = {
    shared_buffers   = "1GB";    # 依實際 RAM 調整（建議為 RAM 的 25%）
    work_mem         = "64MB";
    max_connections  = 100;
  };
}
