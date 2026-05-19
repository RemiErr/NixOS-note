# 範本一：最小化單主機配置

## 這個範本是什麼

這是一份最小化的 NixOS 單主機 Flakes 配置，包含開機、網路、時區、使用者、常用套件、SSH 服務與防火牆的基礎設定。適合作為學習 NixOS Flakes 結構的起點。

## 適用情境

- NixOS 初學者，正在設定第一台測試主機
- 不需要模組化拆分的簡單個人系統
- 想快速了解 Flakes 基礎目錄結構與配置方式

## 使用方式

### 第一步：取得此範本

```bash
git clone <此倉庫網址>
cd examples/basic-single-host
```

### 第二步：替換主機名稱

在 `flake.nix` 與 `configuration.nix` 中，將所有 `myhostname` 替換為你的實際主機名稱：

```bash
# 範例：將主機名稱改為 mypc
sed -i 's/myhostname/mypc/g' flake.nix configuration.nix
```

### 第三步：套用配置

```bash
sudo nixos-rebuild switch --flake .#myhostname
```

## 注意事項

此範本**不包含** `hardware-configuration.nix`，因為該檔案的內容因機器硬體而異，必須在目標機器上執行以下指令自動產生：

```bash
sudo nixos-generate-config --root /mnt
```

安裝完成後，將 `/etc/nixos/hardware-configuration.nix` 複製到此目錄，再執行 `nixos-rebuild switch`。

> 不要手動編輯 `hardware-configuration.nix`，其內容由工具自動生成。
