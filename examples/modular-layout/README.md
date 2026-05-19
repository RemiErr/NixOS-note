# 範本四：多主機配置（Multi-Host Flake）

本範本展示如何用一個 Flakes 倉庫同時管理多台 NixOS 主機，透過共用模組與角色（Profile）減少重複配置。

對應書籍附錄 E.4。

---

## 適用情境

- 同時管理多台 NixOS 主機的進階用戶
- 基礎設施即代碼（Infrastructure as Code）實踐
- 希望在不同主機間共享配置邏輯

---

## 目錄結構

```
modular-layout/
├── flake.nix                       # Flakes 入口，定義所有主機
├── lib/
│   └── mkHost.nix                  # 產生 nixosConfiguration 的輔助函數
├── modules/
│   ├── common/
│   │   └── base.nix                # 所有主機共用的基礎配置
│   └── profiles/
│       ├── web-server.nix          # Web 伺服器角色（Nginx + ACME）
│       └── db-server.nix           # 資料庫伺服器角色（PostgreSQL）
└── hosts/
    ├── web-01/
    │   └── configuration.nix       # web-01 主機專屬配置
    └── db-01/
        └── configuration.nix       # db-01 主機專屬配置
```

---

## 架構說明

### 共用層（modules/common/）

`base.nix` 是所有主機都會自動載入的基礎模組，包含：

- SSH 安全設定（禁止密碼登入、禁止 root 登入）
- 部署帳號 `deploy`
- Nix Flakes 功能啟用
- 自動垃圾回收排程
- 基礎工具套件

### 角色層（modules/profiles/）

依主機用途定義不同角色：

| 角色 | 功能 |
|---|---|
| `web-server.nix` | Nginx 反向代理、Let's Encrypt 憑證、開放 80/443 |
| `db-server.nix` | PostgreSQL 16、自動備份、只允許本機連線 |

### 主機層（hosts/）

每台主機的 `configuration.nix` 只包含：
1. 匯入適合的角色模組
2. 此主機專屬的覆蓋設定（如不同的記憶體參數）

### 輔助函數（lib/mkHost.nix）

`mkHost` 封裝了 `nixpkgs.lib.nixosSystem`，確保每台主機都自動載入 `modules/common/base.nix`，避免重複。

---

## 使用方式

### 第一步：初始化 Git 倉庫

```bash
git init
git add .
git commit -m "初始化多主機 NixOS 配置"
```

### 第二步：修改設定

打開各檔案，將以下預留值替換為實際值：

| 預留值 | 替換為 |
|---|---|
| `ssh-ed25519 AAAAC3...` | 你的管理工作站 SSH 公鑰 |
| `ops@example.com` | 你的實際電子郵件 |
| `example.com` | 你的實際網域名稱 |

### 第三步：新增主機的硬體配置

每台主機需要各自的 `hardware-configuration.nix`，在目標機器上執行：

```bash
sudo nixos-generate-config --root /mnt
```

將產生的檔案複製到對應目錄：

```bash
cp /mnt/etc/nixos/hardware-configuration.nix hosts/web-01/
cp /mnt/etc/nixos/hardware-configuration.nix hosts/db-01/
```

### 第四步：套用配置

```bash
# 套用 web-01 的配置
sudo nixos-rebuild switch --flake .#web-01

# 套用 db-01 的配置
sudo nixos-rebuild switch --flake .#db-01

# 透過 SSH 遠端套用（在管理機器上執行）
nixos-rebuild switch --flake .#web-01 --target-host deploy@web-01.example.com
```

### 第五步：新增主機

複製任一主機目錄，修改 `configuration.nix`，並在 `flake.nix` 的 `nixosConfigurations` 中新增一筆：

```nix
app-01 = mkHost {
  hostname = "app-01";
  system   = "x86_64-linux";
  modules  = [
    ./hosts/app-01/configuration.nix
    ./hosts/app-01/hardware-configuration.nix
  ];
};
```

---

## 安全提醒

- SSH 公鑰請直接填入 `modules/common/base.nix`
- 密碼、API Token 等敏感資訊請勿寫入 Nix 配置
- 建議使用 `agenix` 或 `sops-nix` 管理秘密（詳見書籍第23章）
