# NixOS 工作站配置範本

## 這個範本是什麼

這是一個標準個人工作站的 NixOS Flake 配置範本，內含：

- **GNOME 桌面環境**：搭配 PipeWire 音效、中文字型、Firefox 瀏覽器
- **開發工具集**：Git、Docker、Neovim、VS Code、Node.js、Python、Go 等
- **Home Manager 整合**：以 NixOS 模組形式管理使用者 `alice` 的 Shell（zsh + Starship）、Git 設定

## 適用情境

- 個人工作站、日常開發機
- 需要桌面環境（GNOME）的 NixOS 系統
- 想開始學習模組化配置的 NixOS 進階初學者

## 目錄結構

```
workstation/
├── README.md                        # 本說明文件
├── flake.nix                        # Flake 入口，宣告輸入來源與輸出
├── hosts/
│   └── workstation/
│       ├── configuration.nix        # 主機配置（匯入模組）
│       └── hardware-configuration.nix  # 硬體配置（需自行產生）
└── modules/
    ├── desktop.nix                  # GNOME 桌面環境、音效、字型
    ├── development.nix              # 開發工具、Docker、語言工具鏈
    └── user.nix                     # 使用者 alice + Home Manager 設定
```

## 使用方式

### 步驟一：替換主機名稱與使用者名稱

將配置中的預設值替換為你自己的設定：

1. 將 `flake.nix` 與 `hosts/workstation/configuration.nix` 中的 `workstation` 改為你的主機名稱
2. 將 `modules/user.nix` 與 `modules/development.nix` 中所有的 `alice` 改為你的使用者名稱
3. 更新 `modules/user.nix` 中 `programs.git` 的 `userName` 與 `userEmail`

### 步驟二：產生硬體配置

在目標機器上執行以下指令，產生 `hardware-configuration.nix`：

```bash
sudo nixos-generate-config --show-hardware-config > hosts/workstation/hardware-configuration.nix
```

### 步驟三：套用配置

```bash
# 首次部署（在目標機器的配置目錄中執行）
sudo nixos-rebuild switch --flake .#workstation

# 更新 Flake 輸入（升級 nixpkgs 與 home-manager）
nix flake update

# 再次套用
sudo nixos-rebuild switch --flake .#workstation
```

## 注意事項

- `modules/user.nix` 中的 `initialPassword = "changeme"` 僅供首次登入使用，部署後請立即以 `passwd` 指令更改密碼
- `modules/development.nix` 中的 `docker` 群組成員具有等同 root 的權限，請謹慎管理成員
- `hosts/workstation/hardware-configuration.nix` 為機器專屬檔案，不應納入版本控制（建議加入 `.gitignore`）
