# Lab 6 標準答案：hosts/laptop/default.nix

{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ../../modules/common
    ../../profiles/desktop.nix
  ];

  networking.hostName = "laptop";

  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone     = "Asia/Taipei";
  i18n.defaultLocale = "zh_TW.UTF-8";

  users.users.alice = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "networkmanager" "audio" "video" ];
  };

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.05";
}
