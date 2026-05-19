{ config, pkgs, lib, ... }:

{
  # ── SSH 硬化配置 ──────────────────────────────────────────────
  services.openssh = {
    enable = true;
    ports  = [ 22 ];
    settings = {
      # 禁止以 root 帳號直接登入 SSH
      PermitRootLogin         = "no";
      # 禁止密碼登入，強制使用 SSH 金鑰
      PasswordAuthentication  = false;
      # 禁止空密碼
      PermitEmptyPasswords    = "no";
      # 禁止 X11 轉發（伺服器不需要圖形介面）
      X11Forwarding           = false;
      # 登入逾時時間（秒）
      LoginGraceTime          = 30;
      # 最大驗證嘗試次數
      MaxAuthTries            = 3;
    };
  };

  # ── fail2ban：自動封鎖暴力破解嘗試 ──────────────────────────
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime  = "24h";
    bantime-increment = {
      enable     = true;
      multipliers = "1 2 4 8 16 32 64";
      maxtime    = "168h";  # 最長封鎖 7 天
    };
  };

  # ── 防火牆設定 ────────────────────────────────────────────────
  networking.firewall = {
    enable = true;
    # 只開放必要的連接埠
    allowedTCPPorts = [
      22    # SSH
      80    # HTTP（ACME 驗證需要）
      443   # HTTPS
    ];
    # 記錄被拒絕的連線（有助於除錯）
    logRefusedConnections = true;
  };

  # ── 自動系統維護 ──────────────────────────────────────────────
  # 自動垃圾回收：每週清理超過 7 天的舊世代
  nix.gc = {
    automatic = true;
    dates     = "weekly";
    options   = "--delete-older-than 7d";
  };

  # 最佳化 Nix Store（合併重複檔案）
  nix.settings.auto-optimise-store = true;

  # ── 部署使用者 ────────────────────────────────────────────────
  users.users.deploy = {
    isNormalUser = true;
    description  = "Deploy User";
    extraGroups  = [ "wheel" ];
    # 請替換為你的實際 SSH 公鑰
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... deploy@management"
    ];
    shell = pkgs.bash;
  };

  # ── 基礎工具 ──────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    curl
    wget
    lsof       # 查看開啟的檔案與網路連線
    tcpdump    # 網路封包分析
    jq         # JSON 處理
  ];
}
