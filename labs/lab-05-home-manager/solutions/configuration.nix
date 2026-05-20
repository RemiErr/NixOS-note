# Lab 5 標準答案：configuration.nix（伺服器入口）

{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/ssh.nix
    ./modules/postgresql.nix
    ./modules/webapp.nix
    ./modules/nginx.nix
  ];

  networking.hostName = "nixos";
  time.timeZone       = "Asia/Taipei";
  i18n.defaultLocale  = "zh_TW.UTF-8";

  users.users.alice = {
    isNormalUser = true;
    extraGroups  = [ "wheel" ];
  };

  environment.systemPackages = with pkgs; [
    vim git curl htop tree
  ];

  system.stateVersion = "25.05";
}
