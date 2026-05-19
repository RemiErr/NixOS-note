{ config, pkgs, lib, ... }:

{
  services.nginx = {
    enable                   = true;
    recommendedGzipSettings  = true;
    recommendedOptimisation  = true;
    recommendedProxySettings = true;
    recommendedTlsSettings   = true;

    virtualHosts."_" = {
      default = true;
      locations."/" = {
        return = "200 'Web server is running'";
        extraConfig = "add_header Content-Type text/plain;";
      };
    };
  };

  security.acme = {
    acceptTerms   = true;
    defaults.email = "ops@example.com";
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
