# Homelab 範本：家庭實驗室配置

本範本展示如何用 NixOS 建立一套實用的家庭實驗室（Homelab）環境，包含軟路由和 NAS 兩台主機。

---

## 適用情境

- 家庭網路管理：需要 VPN 遠端存取、DNS 過濾
- 家庭媒體儲存：影片、音樂、照片集中管理
- 學習 NixOS 基礎設施配置的進階練習

---

## 目錄結構

```
homelab/
├── flake.nix                   # Flakes 入口，定義 router 與 nas 兩台主機
└── hosts/
    ├── router/
    │   └── configuration.nix   # 軟路由：WireGuard VPN + dnsmasq + NAT
    └── nas/
        └── configuration.nix   # NAS：ZFS + Samba + restic 備份
```

---

## 主機說明

### router（軟路由）

| 功能 | 技術 |
|---|---|
| NAT 路由 | Linux iptables（NixOS `networking.nat`） |
| VPN | WireGuard（UDP 51820） |
| DNS | dnsmasq（內網域名解析） |

**網路介面假設：**

| 介面 | 用途 |
|---|---|
| `eth0` | 上行（WAN，連接到光纖數據機） |
| `eth1` | 下行（LAN，連接到家庭交換器） |

**WireGuard 設計：**

- 路由器作為 WireGuard Server，監聽 UDP 51820
- VPN 子網路：`10.100.0.0/24`
- 路由器 VPN IP：`10.100.0.1`
- 手機、筆電等 Peer 分配 `10.100.0.x` 地址

### nas（網路附接儲存）

| 功能 | 技術 |
|---|---|
| 檔案系統 | ZFS（支援壓縮、快照、校驗） |
| 檔案共享 | Samba（SMB 協定，Windows/macOS/Linux 相容） |
| 異地備份 | restic（增量備份到 S3 或其他雲端儲存） |

**ZFS 設計：**

- 開機時請求加密金鑰（`requestEncryptionCredentials = true`）
- 自動定期 Scrub（校驗資料完整性）
- 自動快照（ZFS Auto Snapshot）

---

## 使用前準備

### 硬體需求

| 主機 | 建議規格 |
|---|---|
| router | 雙網卡迷你主機（如 N100 小主機），4GB RAM，32GB SSD |
| nas | 多硬碟主機，8GB+ RAM，建議搭配 ECC 記憶體（ZFS 最佳實踐） |

### 軟體準備

1. 確認 NixOS 已安裝並啟用 Flakes（詳見書籍第17章）
2. 在兩台機器上執行 `nixos-generate-config` 產生硬體配置

---

## 使用方式

### 第一步：產生硬體配置

在每台機器上執行：

```bash
sudo nixos-generate-config --root /mnt
```

將產生的 `hardware-configuration.nix` 複製到對應目錄（需手動建立，未納入此範本）：

```bash
# router 機器上
cp /etc/nixos/hardware-configuration.nix hosts/router/

# nas 機器上
cp /etc/nixos/hardware-configuration.nix hosts/nas/
```

並在 `flake.nix` 的各 `modules` 清單中加入路徑：

```nix
./hosts/router/hardware-configuration.nix
```

### 第二步：設定 WireGuard 私鑰

在 router 上產生 WireGuard 金鑰：

```bash
# 在 router 主機上執行
sudo mkdir -p /etc/wireguard
wg genkey | sudo tee /etc/wireguard/private.key
sudo chmod 600 /etc/wireguard/private.key

# 顯示對應的公鑰（給 Peer 使用）
sudo cat /etc/wireguard/private.key | wg pubkey
```

### 第三步：新增 WireGuard Peer

編輯 `hosts/router/configuration.nix`，在 `peers` 清單中加入裝置：

```nix
peers = [
  {
    # 手機
    publicKey  = "手機的 WireGuard 公鑰";
    allowedIPs = [ "10.100.0.2/32" ];
  }
  {
    # 筆電
    publicKey  = "筆電的 WireGuard 公鑰";
    allowedIPs = [ "10.100.0.3/32" ];
  }
];
```

### 第四步：設定 restic 備份

在 nas 上建立密碼和認證檔案：

```bash
# 備份加密密碼
echo "你的備份加密密碼" | sudo tee /etc/restic-password
sudo chmod 600 /etc/restic-password

# S3 存取金鑰（AWS 格式）
sudo tee /etc/restic-s3-env << 'EOF'
AWS_ACCESS_KEY_ID=你的ACCESS_KEY
AWS_SECRET_ACCESS_KEY=你的SECRET_KEY
EOF
sudo chmod 600 /etc/restic-s3-env
```

### 第五步：設定 Samba 使用者密碼

Samba 使用獨立的密碼資料庫，需在 nas 上設定：

```bash
# 新增 Samba 使用者（alice 必須已是系統使用者）
sudo smbpasswd -a alice
```

### 第六步：套用配置

```bash
# 初始化 Git 倉庫（Flakes 需要）
git init && git add . && git commit -m "初始化 homelab 配置"

# 套用 router 配置
sudo nixos-rebuild switch --flake .#router

# 套用 nas 配置
sudo nixos-rebuild switch --flake .#nas

# 或透過 SSH 遠端套用
nixos-rebuild switch --flake .#router --target-host root@192.168.1.1
nixos-rebuild switch --flake .#nas --target-host root@192.168.1.2
```

---

## 常見調整

**更改 WireGuard 監聽埠**

```nix
networking.wireguard.interfaces.wg0.listenPort = 51820;  # 改為其他埠
```

**新增 Samba 共享目錄**

```nix
shares.photos = {
  path = "/data/photos";
  browseable = "yes";
  "read only" = "no";
  "valid users" = "alice bob";
};
```

**調整 restic 備份排程**

```nix
timerConfig = { OnCalendar = "03:00";  # 每天凌晨 3 點備份 };
```

---

## 安全提醒

- WireGuard 私鑰（`/etc/wireguard/private.key`）不可寫入 Nix 配置或 Git 倉庫
- restic 密碼和 S3 金鑰應儲存於機器本地，不可推送到遠端倉庫
- 建議使用 `agenix` 或 `sops-nix` 統一管理機密（詳見書籍第23章）
- Samba 應只在內網開放，避免直接暴露在公網
