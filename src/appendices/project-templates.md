# 附錄E：NixOS 專案範本

## 說明

本附錄提供五種常用的 NixOS 配置專案範本，可直接複製後修改使用。
所有範本均基於 Flakes 架構，並遵循本書推薦的目錄結構。

統一規格如下：

| 項目 | 值 |
|---|---|
| nixpkgs 版本 | nixos-25.05 |
| system.stateVersion | "25.05" |
| 工作站使用者 | alice |
| 伺服器使用者 | deploy |

使用範本前，請先確認系統已啟用 Flakes 功能（詳見第17章）。

---

## E.1 範本一：最小化單主機配置（Minimal Single Host）

### 適用情境

- NixOS 初學者、第一台測試主機
- 不需要模組化的簡單個人系統
- 學習 Flakes 基礎結構的起點

### 目錄結構

```
nixos-minimal/
├── flake.nix
├── configuration.nix
└── hardware-configuration.nix   ← 由 nixos-generate-config 產生
```

### flake.nix

`flake.nix` 是整個 Flakes 專案的入口，定義輸入來源與輸出。

```nix
{
  description = "最小化 NixOS 單主機配置";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations = {
      # 將 "myhostname" 替換為你的主機名稱
      myhostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./hardware-configuration.nix
        ];
      };
    };
  };
}
```

### configuration.nix

這是最小化但完整可運行的系統配置，包含開機、網路、使用者與常用套件。

```nix
{ config, pkgs, lib, ... }:

{
  # ── 開機設定 ──────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── 網路設定 ──────────────────────────────────────────────────
  # 將 "myhostname" 替換為你的主機名稱
  networking.hostName = "myhostname";
  networking.networkmanager.enable = true;

  # ── 時區與地區 ────────────────────────────────────────────────
  time.timeZone = "Asia/Taipei";
  i18n.defaultLocale = "zh_TW.UTF-8";

  # ── 使用者設定 ────────────────────────────────────────────────
  users.users.alice = {
    isNormalUser = true;
    description = "Alice";
    # wheel 允許使用 sudo；networkmanager 允許管理網路
    extraGroups = [ "wheel" "networkmanager" ];
    # 初次設定後請使用 passwd alice 設定密碼
    initialPassword = "changeme";
  };

  # ── 系統套件 ──────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    htop
  ];

  # ── SSH 服務 ──────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # ── 防火牆 ────────────────────────────────────────────────────
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # ── 版本標記 ──────────────────────────────────────────────────
  # 此值決定系統狀態版本，首次安裝後不要更動
  system.stateVersion = "25.05";
}
```

### hardware-configuration.nix 說明

`hardware-configuration.nix` 包含磁碟分區、核心模組等硬體相關配置，必須在目標機器上執行以下指令自動產生：

```bash
sudo nixos-generate-config --root /mnt
```

安裝完成後，此檔案位於 `/etc/nixos/hardware-configuration.nix`，將其複製到 Flakes 目錄即可。

> **注意**：不要手動編輯 `hardware-configuration.nix`，內容會因機器硬體而異。

---

## E.2 範本二：標準工作站配置（Desktop Workstation）

### 適用情境

- 個人工作站、日常開發機
- 需要桌面環境（GNOME）
- 希望開始模組化配置的進階初學者

### 目錄結構

```
nixos-workstation/
├── flake.nix
├── hosts/
│   └── workstation/
│       ├── configuration.nix
│       └── hardware-configuration.nix
└── modules/
    ├── desktop.nix       # GNOME 桌面環境
    ├── development.nix   # 開發工具
    └── user.nix          # 使用者 alice 設定
```

### flake.nix

加入 `home-manager` 作為使用者環境管理工具。

```nix
{
  description = "NixOS 工作站配置（含 Home Manager）";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      # 讓 home-manager 使用與系統相同的 nixpkgs
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    nixosConfigurations = {
      workstation = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/workstation/configuration.nix
          ./hosts/workstation/hardware-configuration.nix

          # 以 NixOS 模組形式整合 Home Manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
      };
    };
  };
}
```

### hosts/workstation/configuration.nix

主機配置負責匯入各功能模組，保持簡潔。

```nix
{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/desktop.nix
    ../../modules/development.nix
    ../../modules/user.nix
  ];

  # ── 主機識別 ──────────────────────────────────────────────────
  networking.hostName = "workstation";
  networking.networkmanager.enable = true;

  # ── 開機設定 ──────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── 時區與地區 ────────────────────────────────────────────────
  time.timeZone = "Asia/Taipei";
  i18n.defaultLocale = "zh_TW.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ALL = "zh_TW.UTF-8";
  };

  # ── 基礎套件 ──────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
  ];

  system.stateVersion = "25.05";
}
```

### modules/desktop.nix

桌面環境模組：啟用 GNOME、顯示管理器與中文字型。

```nix
{ config, pkgs, lib, ... }:

{
  # ── X11 與 GNOME ──────────────────────────────────────────────
  services.xserver = {
    enable = true;
    # GNOME 顯示管理器（登入畫面）
    displayManager.gdm.enable = true;
    # GNOME 桌面環境
    desktopManager.gnome.enable = true;
  };

  # ── 音效系統 ──────────────────────────────────────────────────
  # PipeWire 是現代 Linux 音效伺服器，取代舊有的 PulseAudio
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ── 列印服務 ──────────────────────────────────────────────────
  services.printing.enable = true;

  # ── 字型 ──────────────────────────────────────────────────────
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      # 思源黑體：Google 與 Adobe 合作的開源中文字型
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      # 程式碼字型
      fira-code
      jetbrains-mono
    ];
    fontconfig.defaultFonts = {
      serif     = [ "Noto Serif CJK TC" "Noto Serif" ];
      sansSerif = [ "Noto Sans CJK TC" "Noto Sans" ];
      monospace = [ "JetBrains Mono" "Noto Sans Mono" ];
    };
  };

  # ── GNOME 排除不必要的預設應用程式 ───────────────────────────
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-music
    epiphany    # GNOME 預設瀏覽器，通常改用 Firefox
  ];

  # ── 瀏覽器 ────────────────────────────────────────────────────
  programs.firefox.enable = true;
}
```

### modules/development.nix

開發工具模組：版本控制、容器、語言工具鏈。

```nix
{ config, pkgs, lib, ... }:

{
  # ── 版本控制 ──────────────────────────────────────────────────
  programs.git = {
    enable = true;
    # 全域設定提示（使用者需自行設定 user.name 與 user.email）
  };

  # ── 容器工具 ──────────────────────────────────────────────────
  # Docker：廣泛使用的容器執行環境
  virtualisation.docker = {
    enable = true;
    # 系統啟動時自動啟動 Docker daemon
    enableOnBoot = true;
  };

  # ── 開發套件 ──────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # 編輯器
    neovim
    vscode

    # 終端工具
    tmux
    fzf          # 模糊搜尋
    ripgrep      # 快速文字搜尋（grep 替代品）
    jq           # JSON 處理工具
    tree         # 目錄樹狀顯示

    # 語言執行環境
    nodejs_22    # Node.js
    python313    # Python 3.13
    go           # Go 語言

    # 建構工具
    gnumake
    gcc

    # 網路除錯
    nmap
    httpie       # HTTP 客戶端（curl 替代品）
  ];

  # ── 允許 alice 使用 Docker（不需要 sudo）────────────────────
  # 注意：docker 群組成員等同於 root 權限，請謹慎使用
  users.users.alice.extraGroups = [ "docker" ];
}
```

### modules/user.nix

使用者模組：定義 alice 帳號並整合 Home Manager。

```nix
{ config, pkgs, lib, ... }:

{
  # ── 系統層使用者定義 ──────────────────────────────────────────
  users.users.alice = {
    isNormalUser = true;
    description  = "Alice";
    extraGroups  = [ "wheel" "networkmanager" "audio" "video" ];
    # 使用 SSH 金鑰登入（推薦）
    # openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA..." ];
    initialPassword = "changeme";
    shell = pkgs.zsh;
  };

  # 啟用 zsh 作為系統 shell
  programs.zsh.enable = true;

  # ── Home Manager 使用者配置 ───────────────────────────────────
  # 此區塊由 Home Manager NixOS 模組處理
  home-manager.users.alice = { pkgs, ... }: {
    home.username    = "alice";
    home.homeDirectory = "/home/alice";

    # ── Shell 環境 ────────────────────────────────────────────
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        ll  = "ls -la";
        la  = "ls -A";
        ".." = "cd ..";
        # NixOS 常用別名
        rebuild = "sudo nixos-rebuild switch --flake .#workstation";
        update  = "nix flake update";
      };
    };

    programs.starship = {
      enable = true;
      settings = {
        add_newline = true;
        character = {
          success_symbol = "[❯](bold green)";
          error_symbol   = "[❯](bold red)";
        };
      };
    };

    programs.git = {
      enable    = true;
      userName  = "Alice";
      userEmail = "alice@example.com";
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase        = true;
      };
    };

    # Home Manager 版本標記，與系統版本保持一致
    home.stateVersion = "25.05";
  };
}
```

---

## E.3 範本三：輕量伺服器配置（Minimal Server）

### 適用情境

- VPS、雲端主機
- 家庭實驗室（Homelab）伺服器
- 需要 Nginx 與 HTTPS 的靜態或反向代理服務

### 目錄結構

```
nixos-server/
├── flake.nix
├── hosts/
│   └── server/
│       ├── configuration.nix
│       └── hardware-configuration.nix
└── modules/
    ├── server-base.nix    # SSH 硬化、防火牆、自動維護
    └── web-server.nix     # Nginx + Let's Encrypt ACME
```

### flake.nix

```nix
{
  description = "NixOS 輕量伺服器配置";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations = {
      server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/server/configuration.nix
          ./hosts/server/hardware-configuration.nix
        ];
      };
    };
  };
}
```

### modules/server-base.nix

伺服器基礎安全模組：SSH 硬化、fail2ban、防火牆、自動垃圾回收。

```nix
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
```

### modules/web-server.nix

Nginx 反向代理模組，整合 Let's Encrypt 自動憑證。

```nix
{ config, pkgs, lib, ... }:

{
  # ── ACME（Let's Encrypt 自動憑證）────────────────────────────
  security.acme = {
    acceptTerms = true;
    # 替換為你的實際電子郵件（憑證到期通知用）
    defaults.email = "admin@example.com";
  };

  # ── Nginx 設定 ────────────────────────────────────────────────
  services.nginx = {
    enable = true;

    # 推薦的效能與安全設定
    recommendedGzipSettings    = true;
    recommendedOptimisation    = true;
    recommendedProxySettings   = true;
    recommendedTlsSettings     = true;

    # 虛擬主機設定
    virtualHosts = {
      # 替換 "example.com" 為你的實際網域名稱
      "example.com" = {
        # 啟用 Let's Encrypt HTTPS 憑證
        enableACME  = true;
        # 自動將 HTTP 請求重新導向至 HTTPS
        forceSSL    = true;

        # 靜態網站根目錄
        root = "/var/www/example.com";

        # 也可以改為反向代理到本地應用程式
        # locations."/" = {
        #   proxyPass = "http://127.0.0.1:8080";
        # };
      };

      # 第二個虛擬主機範例（反向代理）
      "api.example.com" = {
        enableACME = true;
        forceSSL   = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:3000";
          # 傳遞真實 IP 給後端應用
          proxyWebsockets = true;
        };
      };
    };
  };
}
```

### hosts/server/configuration.nix

```nix
{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/server-base.nix
    ../../modules/web-server.nix
  ];

  # ── 主機識別 ──────────────────────────────────────────────────
  networking.hostName = "server";

  # ── 開機設定 ──────────────────────────────────────────────────
  # VPS 通常使用 GRUB（非 EFI），請依實際環境調整
  boot.loader.grub = {
    enable  = true;
    device  = "/dev/sda";   # 替換為實際磁碟裝置
  };

  # ── 時區 ──────────────────────────────────────────────────────
  time.timeZone = "Asia/Taipei";

  # ── 日誌管理 ──────────────────────────────────────────────────
  # 限制日誌大小，避免磁碟被日誌塞滿
  services.journald.extraConfig = ''
    SystemMaxUse=2G
    MaxRetentionSec=30day
  '';

  system.stateVersion = "25.05";
}
```

---

## E.4 範本四：多主機配置（Multi-Host Flake）

### 適用情境

- 同時管理多台 NixOS 主機的進階用戶
- 基礎設施即代碼（Infrastructure as Code）實踐
- 希望在不同主機間共享配置邏輯

### 目錄結構

```
nixos-infrastructure/
├── flake.nix
├── lib/
│   └── mkHost.nix          # 產生 nixosConfiguration 的輔助函數
├── hosts/
│   ├── web-01/
│   │   ├── configuration.nix
│   │   └── hardware-configuration.nix
│   └── db-01/
│       ├── configuration.nix
│       └── hardware-configuration.nix
└── modules/
    ├── common/
    │   └── base.nix         # 所有主機共用的基礎配置
    └── profiles/
        ├── web-server.nix   # Web 伺服器角色
        └── db-server.nix    # 資料庫伺服器角色
```

### flake.nix

使用輔助函數自動讀取 `hosts/` 目錄下的所有主機定義。

```nix
{
  description = "NixOS 多主機基礎設施配置";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ... }:
    let
      # 載入輔助函數模組
      lib      = nixpkgs.lib;
      mkHost   = import ./lib/mkHost.nix { inherit nixpkgs; };
    in
    {
      nixosConfigurations = {
        # 每台主機對應一個 nixosConfiguration
        # 主機名稱必須與 hosts/ 目錄名稱相同
        web-01 = mkHost {
          hostname = "web-01";
          system   = "x86_64-linux";
          modules  = [
            ./hosts/web-01/configuration.nix
            ./hosts/web-01/hardware-configuration.nix
          ];
        };

        db-01 = mkHost {
          hostname = "db-01";
          system   = "x86_64-linux";
          modules  = [
            ./hosts/db-01/configuration.nix
            ./hosts/db-01/hardware-configuration.nix
          ];
        };
      };
    };
}
```

### lib/mkHost.nix

輔助函數：封裝 `nixpkgs.lib.nixosSystem`，統一注入共用模組。

```nix
# lib/mkHost.nix
# 用法：mkHost { hostname = "web-01"; system = "x86_64-linux"; modules = [...]; }
{ nixpkgs }:

{ hostname, system, modules }:

nixpkgs.lib.nixosSystem {
  inherit system;

  # specialArgs 可以將額外參數傳入所有模組
  specialArgs = {
    inherit hostname;
  };

  modules = [
    # 所有主機都自動載入共用基礎模組
    ../modules/common/base.nix

    # 傳入此函數的主機專屬模組
  ] ++ modules;
}
```

### modules/common/base.nix

所有主機共用的基礎配置：安全設定、NTP、日誌、維護排程。

```nix
# 注意：hostname 來自 flake.nix 的 specialArgs
{ config, pkgs, lib, hostname, ... }:

{
  # ── 主機識別（從 specialArgs 取得）──────────────────────────
  networking.hostName = hostname;

  # ── 開機設定 ──────────────────────────────────────────────────
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── 時間同步 ──────────────────────────────────────────────────
  services.timesyncd.enable = true;
  time.timeZone = "Asia/Taipei";

  # ── 基礎安全 ──────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin        = "no";
    };
  };

  networking.firewall.enable = true;

  # ── 部署帳號（所有主機共用）─────────────────────────────────
  users.users.deploy = {
    isNormalUser = true;
    extraGroups  = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # 將此公鑰替換為你的管理工作站的 SSH 公鑰
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... deploy@management"
    ];
  };

  # ── Nix 設定 ──────────────────────────────────────────────────
  nix = {
    settings = {
      # 啟用 Flakes 功能
      experimental-features = [ "nix-command" "flakes" ];
      # 自動最佳化 Store
      auto-optimise-store   = true;
    };
    gc = {
      automatic = true;
      dates     = "weekly";
      options   = "--delete-older-than 14d";
    };
  };

  # ── 基礎工具 ──────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    curl
    wget
  ];

  system.stateVersion = "25.05";
}
```

### modules/profiles/web-server.nix

Web 伺服器角色：Nginx、防火牆開放 HTTP/HTTPS。

```nix
{ config, pkgs, lib, ... }:

{
  services.nginx = {
    enable                   = true;
    recommendedGzipSettings  = true;
    recommendedOptimisation  = true;
    recommendedProxySettings = true;
    recommendedTlsSettings   = true;

    virtualHosts."_" = {
      default = true;
      locations."/" = {
        return = "200 'Web server is running'";
        extraConfig = "add_header Content-Type text/plain;";
      };
    };
  };

  security.acme = {
    acceptTerms   = true;
    defaults.email = "ops@example.com";
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

### modules/profiles/db-server.nix

資料庫伺服器角色：PostgreSQL，只允許內網連線。

```nix
{ config, pkgs, lib, ... }:

{
  # ── PostgreSQL 資料庫 ──────────────────────────────────────────
  services.postgresql = {
    enable  = true;
    package = pkgs.postgresql_16;

    # 監聽本機與內網 IP（請依實際環境調整）
    settings = {
      listen_addresses = "localhost";
      max_connections  = 200;
      # 記憶體相關設定（依伺服器規格調整）
      shared_buffers   = "256MB";
    };

    # 建立初始資料庫與使用者
    initialScript = pkgs.writeText "postgresql-init.sql" ''
      CREATE USER appuser WITH PASSWORD 'changeme';
      CREATE DATABASE appdb OWNER appuser;
      GRANT ALL PRIVILEGES ON DATABASE appdb TO appuser;
    '';

    authentication = pkgs.lib.mkOverride 10 ''
      # TYPE   DATABASE  USER      ADDRESS         METHOD
      local    all       all                       trust
      host     all       all       127.0.0.1/32    scram-sha-256
      host     all       all       ::1/128         scram-sha-256
    '';
  };

  # ── 防火牆：只允許本機存取 PostgreSQL ──────────────────────
  networking.firewall = {
    # PostgreSQL 預設連接埠只在本機開放，不對外開放
    allowedTCPPorts = [ ];
  };

  # ── 資料庫備份（每日）────────────────────────────────────────
  services.postgresqlBackup = {
    enable    = true;
    databases = [ "appdb" ];
    location  = "/var/backup/postgresql";
    startAt   = "daily";
  };
}
```

### hosts/web-01/configuration.nix

```nix
{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/profiles/web-server.nix
  ];

  # 此主機專屬的額外設定（覆蓋或補充 profile 的預設值）
  networking.domain = "example.com";

  # 這台主機的 Nginx 虛擬主機配置
  services.nginx.virtualHosts."web-01.example.com" = {
    enableACME = true;
    forceSSL   = true;
    root       = "/var/www/html";
  };
}
```

### hosts/db-01/configuration.nix

```nix
{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/profiles/db-server.nix
  ];

  # 資料庫伺服器通常需要較大的記憶體設定
  services.postgresql.settings = {
    shared_buffers   = "1GB";    # 依實際 RAM 調整（建議為 RAM 的 25%）
    work_mem         = "64MB";
    max_connections  = 100;
  };
}
```

---

## E.5 範本五：Home Manager 獨立配置（Standalone Home Manager）

### 適用情境

- 在非 NixOS 系統上使用（如 Ubuntu、Debian、macOS）
- 只想用 Nix 管理使用者層級的工具與配置，不修改系統層
- 開發者在公司配發的電腦上建立個人化環境

### 目錄結構

```
home-config/
├── flake.nix
├── home.nix           # Home Manager 主配置
└── modules/
    ├── shell.nix      # zsh、starship 終端配置
    ├── development.nix # 開發工具
    └── editor.nix     # Neovim 編輯器配置
```

### flake.nix

獨立模式的 Home Manager 不需要 `nixosSystem`，只使用 `homeConfigurations` 輸出。

```nix
{
  description = "Home Manager 獨立配置（跨平台）";

  inputs = {
    # 用於提供套件（即使在非 NixOS 系統也需要）
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      # 支援多種系統架構
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"    # Apple Silicon Mac
      ];
    in
    {
      homeConfigurations = {
        # 格式："username@hostname"（可依需求建立多組）
        "alice@workstation" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages."x86_64-linux";

          modules = [
            ./home.nix
          ];
        };

        # macOS 範例
        "alice@macbook" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages."aarch64-darwin";

          modules = [
            ./home.nix
          ];
        };
      };
    };
}
```

### home.nix

Home Manager 主配置：定義使用者資訊並匯入功能模組。

```nix
{ config, pkgs, lib, ... }:

{
  imports = [
    ./modules/shell.nix
    ./modules/development.nix
    ./modules/editor.nix
  ];

  # ── 使用者基本資訊 ────────────────────────────────────────────
  # 將以下值替換為你的實際使用者名稱與家目錄路徑
  home.username    = "alice";
  home.homeDirectory = "/home/alice";   # macOS 請改為 /Users/alice

  # ── 環境變數 ──────────────────────────────────────────────────
  home.sessionVariables = {
    EDITOR  = "nvim";
    PAGER   = "less";
    LANG    = "zh_TW.UTF-8";
    # 確保 Nix 安裝的程式可以被找到
    NIX_PATH = "nixpkgs=${pkgs.path}";
  };

  # ── 基礎套件 ──────────────────────────────────────────────────
  home.packages = with pkgs; [
    # 系統工具
    htop
    tree
    fd           # find 的現代替代品
    bat          # cat 的現代替代品（有語法高亮）
    eza          # ls 的現代替代品
    # 壓縮工具
    zip
    unzip
    # 網路工具
    curl
    wget
  ];

  # ── 版本標記 ──────────────────────────────────────────────────
  home.stateVersion = "25.05";
}
```

### modules/shell.nix

終端環境模組：zsh 配置與 starship 提示符。

```nix
{ config, pkgs, lib, ... }:

{
  # ── zsh 設定 ──────────────────────────────────────────────────
  programs.zsh = {
    enable              = true;
    enableCompletion    = true;
    # 自動補全建議（灰色文字顯示歷史命令）
    autosuggestion.enable      = true;
    # 語法高亮（輸入時即時顯示命令是否有效）
    syntaxHighlighting.enable  = true;

    # 歷史記錄設定
    history = {
      size       = 50000;
      save       = 50000;
      ignoreDups = true;
      share      = true;    # 多個終端視窗共享歷史
    };

    # 常用別名
    shellAliases = {
      # 現代替代品
      ls   = "eza";
      ll   = "eza -la";
      la   = "eza -A";
      cat  = "bat";
      find = "fd";

      # 目錄導航
      ".."  = "cd ..";
      "..." = "cd ../..";

      # Home Manager 快捷操作
      hm-switch = "home-manager switch --flake .#alice@$(hostname)";
      hm-update = "nix flake update && home-manager switch --flake .#alice@$(hostname)";
    };

    # 額外的 zsh 初始化腳本
    initContent = ''
      # 按下 Ctrl+R 啟動 fzf 歷史搜尋
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      source ${pkgs.fzf}/share/fzf/completion.zsh

      # 設定 fzf 預設選項
      export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
    '';
  };

  # ── starship 提示符 ───────────────────────────────────────────
  # starship 是跨 shell 的現代終端提示符
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;

      format = lib.concatStrings [
        "$username"
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_status"
        "$nix_shell"
        "$cmd_duration"
        "$line_break"
        "$character"
      ];

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol   = "[❯](bold red)";
      };

      directory = {
        truncation_length = 4;
        style             = "bold cyan";
      };

      git_branch.style  = "bold purple";
      git_status.style  = "bold red";

      nix_shell = {
        format = "[$symbol$state]($style) ";
        symbol = "❄ ";
        style  = "bold blue";
      };
    };
  };

  # ── fzf 整合 ──────────────────────────────────────────────────
  programs.fzf = {
    enable            = true;
    enableZshIntegration = true;
  };
}
```

### modules/development.nix

開發工具模組：版本控制、語言工具。

```nix
{ config, pkgs, lib, ... }:

{
  # ── Git 配置 ──────────────────────────────────────────────────
  programs.git = {
    enable    = true;
    userName  = "Alice";
    userEmail = "alice@example.com";

    extraConfig = {
      init.defaultBranch  = "main";
      pull.rebase         = true;
      push.autoSetupRemote = true;
      # 使用 delta 作為 diff 顯示工具
      core.pager          = "delta";
      delta = {
        navigate    = true;
        line-numbers = true;
        syntax-theme = "gruvbox-dark";
      };
    };

    aliases = {
      st  = "status";
      co  = "checkout";
      br  = "branch";
      lg  = "log --oneline --graph --decorate";
      undo = "reset HEAD~1 --mixed";
    };
  };

  # ── 開發套件 ──────────────────────────────────────────────────
  home.packages = with pkgs; [
    # Git 輔助工具
    delta        # 漂亮的 git diff
    gh           # GitHub CLI
    lazygit      # Git TUI 介面

    # 搜尋與導航
    ripgrep      # 快速全文搜尋
    fzf          # 模糊搜尋
    zoxide       # 智慧目錄跳轉（取代 cd）

    # JSON / YAML 處理
    jq
    yq-go        # YAML 處理（類似 jq）

    # 容器工具（如果系統已安裝 Docker）
    docker-compose

    # 程式語言（按需選擇）
    nodejs_22
    python313
    go
  ];

  # ── zoxide 整合（在 zsh 中啟用 z 命令）───────────────────────
  programs.zoxide = {
    enable               = true;
    enableZshIntegration = true;
  };
}
```

### modules/editor.nix

Neovim 編輯器模組。

```nix
{ config, pkgs, lib, ... }:

{
  programs.neovim = {
    enable       = true;
    defaultEditor = true;
    viAlias      = true;
    vimAlias     = true;

    # 透過 Nix 管理 Neovim 插件
    plugins = with pkgs.vimPlugins; [
      # 主題
      gruvbox-nvim

      # 檔案導航
      nvim-tree-lua
      telescope-nvim

      # 語法高亮
      (nvim-treesitter.withPlugins (plugins: with plugins; [
        nix
        lua
        python
        javascript
        typescript
        go
        bash
        markdown
      ]))

      # LSP 支援
      nvim-lspconfig
      nvim-cmp             # 自動補全
      cmp-nvim-lsp

      # 狀態列
      lualine-nvim
    ];

    # Neovim 基礎設定（Lua 格式）
    extraLuaConfig = ''
      -- 基礎編輯設定
      vim.opt.number         = true
      vim.opt.relativenumber = true
      vim.opt.tabstop        = 2
      vim.opt.shiftwidth     = 2
      vim.opt.expandtab      = true
      vim.opt.smartindent    = true
      vim.opt.wrap           = false
      vim.opt.termguicolors  = true

      -- 主題
      vim.cmd('colorscheme gruvbox')

      -- 快捷鍵：space 作為 leader key
      vim.g.mapleader = ' '
      vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>')
      vim.keymap.set('n', '<leader>ff', ':Telescope find_files<CR>')
      vim.keymap.set('n', '<leader>fg', ':Telescope live_grep<CR>')
    '';
  };
}
```

---

## E.6 使用說明

### 複製並初始化範本

選好範本後，依以下步驟開始使用：

**第一步：建立專案目錄並複製範本**

```bash
# 建立目錄
mkdir ~/nixos-config
cd ~/nixos-config

# 複製範本檔案（依選擇的範本調整）
# 將上方的各檔案內容逐一建立於對應路徑
```

**第二步：初始化 Git 倉庫**

Flakes 配置必須在 Git 倉庫中才能正常運作：

```bash
git init
git add .
git commit -m "初始化 NixOS 配置"
```

**第三步：修改主機名稱與使用者名稱**

打開 `flake.nix` 與 `configuration.nix`，將以下預留值替換為實際值：

| 預留值 | 替換為 |
|---|---|
| `myhostname` / `workstation` / `server` | 你的實際主機名稱 |
| `alice` / `deploy` | 你的實際使用者名稱 |
| `alice@example.com` | 你的實際電子郵件 |
| `example.com` | 你的實際網域名稱 |
| `ssh-ed25519 AAAAC3...` | 你的實際 SSH 公鑰 |

**第四步：產生硬體配置（全新安裝時）**

如果是全新安裝，在開機進入 NixOS 安裝媒體後執行：

```bash
sudo nixos-generate-config --root /mnt
# 將產生的 hardware-configuration.nix 複製到 Flakes 目錄
cp /mnt/etc/nixos/hardware-configuration.nix ~/nixos-config/hosts/myhostname/
```

**第五步：套用配置**

```bash
# NixOS 系統配置（範本一至四）
sudo nixos-rebuild switch --flake .#myhostname

# 僅測試配置是否有語法錯誤（不實際套用）
sudo nixos-rebuild dry-run --flake .#myhostname

# Home Manager 獨立模式（範本五）
home-manager switch --flake .#alice@$(hostname)
```

### 常見修改情境

**新增系統套件**

開啟對應的 `configuration.nix` 或模組檔案，在 `environment.systemPackages` 中加入套件：

```nix
environment.systemPackages = with pkgs; [
  # 既有套件...
  neofetch    # 新增：系統資訊顯示工具
];
```

**更新 nixpkgs 版本**

```bash
# 更新所有 inputs 到最新提交
nix flake update

# 只更新 nixpkgs
nix flake update nixpkgs

# 套用更新
sudo nixos-rebuild switch --flake .#myhostname

# 提交鎖定檔案
git add flake.lock
git commit -m "更新 nixpkgs"
```

**回滾到前一個世代**

如果更新後出現問題，可以立即回滾：

```bash
# 查看所有系統世代
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# 回滾到前一個世代
sudo nixos-rebuild switch --rollback

# 或指定世代編號
sudo nix-env --switch-generation 42 --profile /nix/var/nix/profiles/system
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

**將配置備份至 GitHub**

```bash
# 首次推送
git remote add origin git@github.com:yourusername/nixos-config.git
git push -u origin main

# 之後每次修改後
git add .
git commit -m "描述你的修改"
git push
```

> **安全提醒**：請勿將密碼、私鑰或 API Token 直接寫入 Nix 配置並推送到公開倉庫。敏感資訊請使用 `agenix` 或 `sops-nix` 等秘密管理工具（詳見第23章）。
