# 系統套件模組
#
# 集中管理 environment.systemPackages，
# 讓「這台機器安裝了什麼」一目瞭然。

{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    htop
    tree
    unzip
  ];
}
