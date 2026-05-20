# Lab 4 標準答案：users.nix
#
# 注意：hashedPassword 與 SSH 公鑰必須替換為你實際產生的值。
# - 用 `mkpasswd -m yescrypt` 產生 hashedPassword
# - 用 `ssh-keygen -t ed25519` 產生金鑰對

{ config, pkgs, ... }:

{
  users.users.alice = {
    isNormalUser = true;
    description  = "Alice";
    extraGroups  = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
    ];

    # 替換為你自己的雜湊
    hashedPassword = "$y$j9T$REPLACE_WITH_YOUR_MKPASSWD_HASH$REPLACE";

    openssh.authorizedKeys.keys = [
      # 替換為你自己的公鑰
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxxxxxxxxxxxxxxxx alice@nixos-lab04"
    ];

    shell = pkgs.zsh;
  };

  # Lab 環境方便操作；正式環境建議移除
  security.sudo.wheelNeedsPassword = false;
}
