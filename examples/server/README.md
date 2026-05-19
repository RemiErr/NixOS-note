# NixOS 輕量伺服器配置範本

本範本出自《NixOS 系統配置文件結構完全指南》附錄 E.3，
提供一個可直接複製使用的輕量伺服器 NixOS Flakes 配置。

---

## 適用情境

- VPS、雲端主機（如 Hetzner、Vultr、DigitalOcean）
- 家庭實驗室（Homelab）伺服器
- 需要 Nginx 與 HTTPS 的靜態網站或反向代理服務

---

## 目錄結構說明

```
server/
├── README.md                      # 本說明文件
├── flake.nix                      # Flakes 入口：定義輸入來源與主機輸出
├── hosts/
│   └── server/
│       ├── configuration.nix      # 主機專屬配置（匯入模組、設定主機名稱等）
│       └── hardware-configuration.nix  # 由 nixos-generate-config 產生，不在此提供
└── modules/
    ├── server-base.nix            # SSH 硬化、fail2ban、防火牆、自動維護、部署使用者
    └── web-server.nix             # Nginx + Let's Encrypt ACME 自動憑證
```

### 各檔案職責

| 檔案 | 職責 |
|---|---|
| `flake.nix` | 定義 nixpkgs 版本與主機清單 |
| `hosts/server/configuration.nix` | 匯入模組、設定主機名稱、開機載入器、時區、日誌 |
| `modules/server-base.nix` | 安全基礎：SSH 硬化、fail2ban、防火牆規則、Nix GC、部署帳號 |
| `modules/web-server.nix` | Web 服務：Nginx 虛擬主機、ACME 憑證自動申請與續期 |

---

## 使用方式

### 步驟一：複製範本

```bash
cp -r examples/server/ ~/my-server-config
cd ~/my-server-config
```

### 步驟二：替換識別資訊

在以下位置替換預設值為你的實際資訊：

**`hosts/server/configuration.nix`**

```nix
networking.hostName = "server";          # 改為你的主機名稱
boot.loader.grub.device = "/dev/sda";   # 改為實際磁碟裝置（lsblk 查看）
time.timeZone = "Asia/Taipei";          # 改為你的時區
```

**`modules/server-base.nix`**

```nix
openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... deploy@management"
  # 替換為你的 SSH 公鑰（cat ~/.ssh/id_ed25519.pub）
];
```

**`modules/web-server.nix`**

```nix
defaults.email = "admin@example.com";   # 替換為你的電子郵件（Let's Encrypt 通知用）

virtualHosts = {
  "example.com" = { ... };              # 替換為你的實際網域名稱
  "api.example.com" = { ... };         # 替換或移除此段
};
```

### 步驟三：部署至伺服器

在目標伺服器上執行：

```bash
# 產生硬體配置檔（在目標伺服器上執行）
nixos-generate-config --show-hardware-config > hosts/server/hardware-configuration.nix

# 初次部署（在伺服器本機）
sudo nixos-rebuild switch --flake .#server

# 或從遠端部署（需安裝 nixos-rebuild 或 deploy-rs）
nixos-rebuild switch --flake .#server --target-host deploy@your-server-ip
```

### 步驟四：驗證服務

```bash
# 確認 SSH 服務運行
systemctl status sshd

# 確認 Nginx 與 ACME 狀態
systemctl status nginx
systemctl status acme-example.com.service

# 確認防火牆規則
iptables -L -n
```

---

## 重要提醒

1. **ACME 電子郵件**：`modules/web-server.nix` 中的 `defaults.email = "admin@example.com"` 必須替換為真實可用的電子郵件，Let's Encrypt 會在憑證即將到期時發送通知。

2. **SSH 公鑰**：`modules/server-base.nix` 中的 `openssh.authorizedKeys.keys` 需替換為你的實際 SSH 公鑰，否則部署後將無法登入（密碼登入已停用）。

3. **hardware-configuration.nix**：此檔案未包含在範本中，需在目標伺服器上執行 `nixos-generate-config` 產生。

4. **防火牆**：範本預設只開放 22（SSH）、80（HTTP/ACME）、443（HTTPS）三個連接埠。如有其他服務需求，請在 `networking.firewall.allowedTCPPorts` 中新增。

5. **網域 DNS**：啟用 ACME 前，請確認你的網域 A 記錄已指向伺服器 IP，否則憑證申請會失敗。

---

## 延伸閱讀

- 第 13 章：服務配置入門
- 第 14 章：Nginx 與反向代理
- 第 15 章：安全性強化
- 第 17 章：Flakes 架構基礎
- 附錄 E：NixOS 專案範本
