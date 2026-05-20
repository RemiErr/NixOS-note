# Lab 4 標準答案：configuration.nix（純入口檔）

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix  # 由 nixos-generate-config 產生
    ./hardware.nix
    ./boot.nix
    ./networking.nix
    ./users.nix
    ./packages.nix
  ];

  system.stateVersion = "25.05";
}
