# Lab 5 標準答案：modules/ssh.nix

{ config, pkgs, lib, ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin              = "no";
      PasswordAuthentication       = false;
      KbdInteractiveAuthentication = false;
      ClientAliveInterval          = 300;
      ClientAliveCountMax          = 2;
    };
    ports = [ 22 ];
  };

  users.users.alice = {
    openssh.authorizedKeys.keys = [
      # 替換為你自己的公鑰
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExamplePublicKeyReplaceThis alice@example.com"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 22 ];
}
