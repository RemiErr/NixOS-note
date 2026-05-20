# Lab 4 標準答案：boot.nix

{ config, pkgs, lib, ... }:

{
  boot.loader.systemd-boot.enable             = true;
  boot.loader.efi.canTouchEfiVariables        = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams   = [ "quiet" "splash" ];
  boot.tmp.useTmpfs   = true;
}
