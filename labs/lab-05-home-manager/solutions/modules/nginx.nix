# Lab 5 標準答案：modules/nginx.nix

{ config, pkgs, lib, ... }:

{
  services.nginx = {
    enable                   = true;
    recommendedOptimisation  = true;
    recommendedGzipSettings  = true;
    recommendedProxySettings = true;

    virtualHosts = {
      "nixos-server" = {
        listen = [
          { addr = "0.0.0.0"; port = 80; }
        ];

        locations."/" = {
          proxyPass = "http://127.0.0.1:8080";
          extraConfig = ''
            proxy_set_header Host              $host;
            proxy_set_header X-Real-IP         $remote_addr;
            proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            proxy_connect_timeout 10s;
            proxy_read_timeout    30s;
            proxy_send_timeout    30s;
          '';
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
}
