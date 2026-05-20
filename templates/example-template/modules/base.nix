# 基礎模組（Base Module）
#
# 提供所有主機都需要的最小設定：
#   - 基本套件
#   - SSH 服務
#   - 防火牆
#
# 範例用途：作為新範例專案的「起手包」，複製後再依需求擴充。

{ config, pkgs, ... }:

{
  # 系統基本套件
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    htop
  ];

  # SSH 服務
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # 防火牆
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # 範例使用者（請依需求調整）
  users.users.alice = {
    isNormalUser = true;
    description = "Alice";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.bash;
    # openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA..." ];
  };
}
