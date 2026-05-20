# Lab 7 任務一標準答案：修復 evaluation error
#
# 修正點：
#   1. hostNamme → hostName（拼字）
#   2. services.openssh.permitRootLogin（已廢棄）
#      → services.openssh.settings.PermitRootLogin

{ config, pkgs, lib, ... }:

{
  networking.hostName = "nixos";

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin        = "no";
      PasswordAuthentication = false;
    };
  };

  system.stateVersion = "25.05";
}
