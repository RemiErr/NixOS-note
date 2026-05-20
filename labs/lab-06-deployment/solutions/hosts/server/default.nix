# Lab 6 標準答案：hosts/server/default.nix
#
# 沒有 hardware.nix，因此只能用 --dry-run 驗證；
# 實際部署需要 nixos-generate-config 產生硬體配置。

{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/common
    ../../profiles/server.nix
  ];

  networking.hostName = "server";
  networking.useDHCP  = true;

  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.alice = {
    isNormalUser = true;
    extraGroups  = [ "wheel" ];
    # openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA..." ];
  };

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.05";
}
