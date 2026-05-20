# Lab 6 標準答案：profiles/server.nix

{ config, pkgs, ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin        = "no";
      PasswordAuthentication = false;
    };
  };

  networking.firewall = {
    enable          = true;
    allowedTCPPorts = [ 22 ];
  };

  environment.systemPackages = with pkgs; [
    vim git htop curl wget
  ];
}
