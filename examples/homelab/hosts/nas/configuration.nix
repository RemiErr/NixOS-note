{ config, pkgs, lib, ... }:
{
  networking.hostName = "nas";

  # ── 開機設定 ──────────────────────────────────────────────────
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── ZFS 支援 ──────────────────────────────────────────────────
  # ZFS 是高可靠性檔案系統，支援資料校驗、壓縮、快照與加密
  boot.supportedFilesystems = [ "zfs" ];

  # 開機時提示輸入 ZFS 加密金鑰（若資料集有加密）
  boot.zfs.requestEncryptionCredentials = true;

  # 定期校驗磁碟資料完整性（每月自動 Scrub）
  services.zfs.autoScrub = {
    enable   = true;
    interval = "monthly";   # 可改為 "weekly"
  };

  # 自動建立 ZFS 快照（類似時間機器，保留多個時間點）
  services.zfs.autoSnapshot = {
    enable   = true;
    frequent = 4;    # 每15分鐘，保留最近 4 個
    hourly   = 24;   # 每小時，保留最近 24 個
    daily    = 7;    # 每天，保留最近 7 天
    weekly   = 4;    # 每週，保留最近 4 週
    monthly  = 12;   # 每月，保留最近 12 個月
  };

  # ── Samba 檔案共享 ────────────────────────────────────────────
  # Samba 實作 SMB 協定，讓 Windows、macOS、Linux 都能存取 NAS
  services.samba = {
    enable       = true;
    # 使用者模式驗證（每個使用者需另外設定 Samba 密碼）
    securityType = "user";

    extraConfig = ''
      workgroup    = WORKGROUP
      server string = NAS
      netbios name = nas
      # 禁止匿名存取
      map to guest = Never
    '';

    shares = {
      # 媒體共享（影片、音樂、照片）
      media = {
        path         = "/data/media";
        browseable   = "yes";
        "read only"  = "no";
        "valid users" = "alice";
        "create mask" = "0664";
        "directory mask" = "0775";
      };

      # 文件共享（家庭文件、掃描件）
      documents = {
        path         = "/data/documents";
        browseable   = "yes";
        "read only"  = "no";
        "valid users" = "alice";
        "create mask" = "0660";
        "directory mask" = "0770";
      };
    };
  };

  # Samba 使用者需要在機器上執行以下指令設定密碼：
  # sudo smbpasswd -a alice

  # ── 使用者設定 ────────────────────────────────────────────────
  users.users.alice = {
    isNormalUser = true;
    description  = "Alice";
    extraGroups  = [ "wheel" ];
    # 替換為你的 SSH 公鑰
    # openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA..." ];
    initialPassword = "changeme";
  };

  # ── restic 備份到雲端 ─────────────────────────────────────────
  # restic 是高效的增量加密備份工具
  # 備份前需在機器上建立以下檔案（不可寫入 Git）：
  #   /etc/restic-password   ← 備份加密密碼（明文）
  #   /etc/restic-s3-env     ← AWS 金鑰（格式：AWS_ACCESS_KEY_ID=xxx）
  services.restic.backups = {
    daily = {
      # 備份這些目錄
      paths = [ "/data" "/home" "/etc/nixos" ];

      # S3 儲存桶（替換為你的實際 bucket 名稱）
      # 也可以改為 SFTP：sftp:user@backup-server:/backups
      repository = "s3:s3.amazonaws.com/my-nixos-backup";

      # 加密密碼檔（每台機器本地保存）
      passwordFile = "/etc/restic-password";

      # S3 存取金鑰環境變數檔
      environmentFile = "/etc/restic-s3-env";

      # 備份排程：每天凌晨 3 點執行
      timerConfig = {
        OnCalendar = "03:00";
        Persistent = true;   # 錯過時自動補跑
      };

      # 清理舊備份的保留策略
      pruneOpts = [
        "--keep-daily 7"     # 保留最近 7 天的每日備份
        "--keep-weekly 4"    # 保留最近 4 週的每週備份
        "--keep-monthly 6"   # 保留最近 6 個月的每月備份
      ];
    };
  };

  # ── SSH 管理 ──────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin        = "no";
    };
  };

  # ── 防火牆設定 ────────────────────────────────────────────────
  networking.firewall = {
    enable = true;
    # SMB 連接埠（445 為主要埠，139 為舊版 NetBIOS）
    allowedTCPPorts = [ 22 139 445 ];
    # NetBIOS 服務（Samba 探索）
    allowedUDPPorts = [ 137 138 ];
  };

  # ── 網路設定 ──────────────────────────────────────────────────
  networking.networkmanager.enable = true;

  # ── 時區 ──────────────────────────────────────────────────────
  time.timeZone = "Asia/Taipei";

  # ── 基礎工具 ──────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    zfs            # ZFS 管理工具（zpool、zfs 指令）
    restic         # 備份工具
    smartmontools  # 硬碟健康監測（SMART）
    hdparm         # 硬碟參數設定
    lsscsi         # 列出 SCSI 裝置
    vim
    htop
    curl
  ];

  # ── Nix 設定 ──────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store   = true;
  };

  nix.gc = {
    automatic = true;
    dates     = "weekly";
    options   = "--delete-older-than 14d";
  };

  system.stateVersion = "25.05";
}
