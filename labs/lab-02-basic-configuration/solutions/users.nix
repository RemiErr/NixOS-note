# 使用者模組
#
# 集中管理使用者帳號與群組設定。
# 跨機器共用：工作機、家用機可 import 同一份。

{ config, pkgs, ... }:

{
  users.users.alice = {
    isNormalUser = true;
    description = "Alice";
    extraGroups = [
      "wheel"          # 允許使用 sudo
      "networkmanager" # 允許管理網路
    ];
    shell = pkgs.bash;
  };
}
