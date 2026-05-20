# Lab 5 標準答案：modules/postgresql.nix

{ config, pkgs, lib, ... }:

{
  services.postgresql = {
    enable  = true;
    package = pkgs.postgresql_16;

    ensureDatabases = [ "myapp" ];
    ensureUsers = [
      {
        name              = "myapp";
        ensureDBOwnership = true;
      }
    ];

    authentication = pkgs.lib.mkOverride 10 ''
      # TYPE  DATABASE  USER  ADDRESS       METHOD
      local   all       all                 trust
      host    all       all   127.0.0.1/32  md5
      host    all       all   ::1/128       md5
    '';

    settings = {
      listen_addresses    = "127.0.0.1";
      log_connections     = true;
      log_disconnections  = true;
    };
  };

  # 刻意不開放防火牆：資料庫只允許本地連線
}
