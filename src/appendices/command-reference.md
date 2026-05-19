# 附錄C：NixOS 指令速查表

本附錄彙整 NixOS 日常管理、套件操作、系統診斷與多主機部署等常用指令，適合開發者隨時查閱。所有指令均以 NixOS 25.05 環境為基準。

---

## C.1 nixos-rebuild（最常用）

`nixos-rebuild` 是 NixOS 最核心的管理工具，用來根據 `/etc/nixos/configuration.nix`（或 Flake）重建系統配置。

### 基本語法

```bash
sudo nixos-rebuild <子指令> [選項]
```

### 指令總覽

| 指令 | 說明 |
|------|------|
| `nixos-rebuild switch` | 重建並立即切換到新配置（最常用） |
| `nixos-rebuild boot` | 重建，下次開機才生效，不影響目前系統 |
| `nixos-rebuild test` | 重建並測試，不設為預設世代，重開機後恢復 |
| `nixos-rebuild dry-activate` | 模擬執行，顯示會變更的項目，不實際套用 |
| `nixos-rebuild build` | 只建置不啟用，結果放在 `./result` 符號連結 |
| `nixos-rebuild build-vm` | 建置可直接執行的 QEMU 虛擬機 |
| `nixos-rebuild switch --flake .#hostname` | 使用 Flake 指定主機名稱重建 |
| `nixos-rebuild switch --target-host user@host` | 遠端部署到其他主機 |
| `nixos-rebuild switch --use-remote-sudo` | 遠端部署時使用 sudo 提權 |
| `nixos-rebuild switch --rollback` | 回滾到上一個世代（generation） |
| `nixos-rebuild switch --show-trace` | 顯示完整錯誤追蹤，除錯用 |
| `nixos-rebuild switch --impure` | 允許不純計算（搭配 Flake 使用） |

### 重要指令範例

**基本切換（傳統配置）**

```bash
# 修改 /etc/nixos/configuration.nix 後套用
sudo nixos-rebuild switch

# 驗證配置不壞系統，只測試不設為預設
sudo nixos-rebuild test

# 確認測試無誤後正式套用
sudo nixos-rebuild switch
```

**Flake 配置建置**

```bash
# 在 flake.nix 所在目錄執行，hostname 為 nixosConfigurations 的 key
sudo nixos-rebuild switch --flake .#my-desktop

# 從任意路徑指定 flake
sudo nixos-rebuild switch --flake /etc/nixos#my-desktop

# 從 GitHub 遠端 flake 部署
sudo nixos-rebuild switch --flake github:user/nixos-config#my-desktop
```

**遠端部署**

```bash
# 從本機建置並部署到遠端主機（SSH 連線）
sudo nixos-rebuild switch \
  --flake .#web-server \
  --target-host admin@192.168.1.100 \
  --use-remote-sudo

# 只建置在本機，傳送到遠端後再啟用
sudo nixos-rebuild switch \
  --flake .#web-server \
  --target-host admin@server.example.com \
  --build-host localhost \
  --use-remote-sudo
```

**除錯與診斷**

```bash
# 乾跑：只顯示變更摘要，不實際執行
sudo nixos-rebuild dry-activate --flake .#my-desktop

# 顯示完整 Nix 求值錯誤追蹤
sudo nixos-rebuild switch --show-trace 2>&1 | less

# 建置 VM 後直接執行（無需安裝）
nixos-rebuild build-vm --flake .#my-desktop
./result/bin/run-my-desktop-vm
```

**世代（generation）管理**

```bash
# 回滾到上一個世代
sudo nixos-rebuild switch --rollback

# 列出所有世代
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# 切換到指定世代編號
sudo nix-env --switch-generation 42 --profile /nix/var/nix/profiles/system
sudo nixos-rebuild switch
```

---

## C.2 nix（現代指令）

現代 `nix` 指令需要在 `configuration.nix` 中先啟用實驗性功能：

```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

### Flake 操作

| 指令 | 說明 |
|------|------|
| `nix flake init` | 在目前目錄初始化新 flake（產生 `flake.nix`） |
| `nix flake init -t templates#python` | 使用模板初始化 flake |
| `nix flake update` | 更新 `flake.lock` 中所有 inputs |
| `nix flake update nixpkgs` | 只更新 `nixpkgs` 這個 input |
| `nix flake check` | 驗證 flake 語法與結構 |
| `nix flake show` | 顯示 flake 所有輸出（packages、apps、devShells 等） |
| `nix flake metadata` | 顯示 flake 元資料（來源、revision、last-modified） |
| `nix flake lock` | 只鎖定（更新 `flake.lock`）不建置 |
| `nix flake clone github:user/repo ./local` | 將 flake 複製到本地 |

### 建置與執行

| 指令 | 說明 |
|------|------|
| `nix build .#package` | 建置目前 flake 的 package，結果在 `./result` |
| `nix build nixpkgs#git` | 建置 nixpkgs 中的 git 套件 |
| `nix run .#app` | 執行 flake 中的 app，無需安裝 |
| `nix run nixpkgs#hello` | 直接執行 nixpkgs 套件 |
| `nix shell nixpkgs#git nixpkgs#vim` | 進入含有指定套件的臨時 shell |
| `nix develop` | 進入目前 flake 的 devShell 開發環境 |
| `nix develop .#dev` | 進入指定名稱的 devShell |

### 搜尋與查詢

| 指令 | 說明 |
|------|------|
| `nix search nixpkgs git` | 在 nixpkgs 中搜尋含有 `git` 的套件 |
| `nix search nixpkgs#` | 列出 nixpkgs 所有套件（輸出很長） |
| `nix eval .#attr` | 對 flake 屬性求值並輸出 |
| `nix eval nixpkgs#git.version` | 查詢套件版本號 |
| `nix repl` | 開啟互動式 Nix REPL |
| `nix repl '<nixpkgs>'` | 開啟 REPL 並載入 nixpkgs |

### 診斷與分析

| 指令 | 說明 |
|------|------|
| `nix log /nix/store/...-drv` | 查看 derivation 的建置日誌 |
| `nix why-depends .#a .#b` | 分析 a 為什麼依賴 b |
| `nix path-info /nix/store/...-pkg` | 查詢 store 路徑資訊 |
| `nix path-info -rsSh .#pkg` | 遞迴列出閉包大小（`-r` 遞迴，`-s` 大小，`-S` 閉包大小，`-h` 人類可讀） |
| `nix store diff-closures old new` | 比較兩個閉包的差異（升級前後很有用） |

### Store 操作

| 指令 | 說明 |
|------|------|
| `nix store gc` | 手動執行垃圾回收 |
| `nix store optimise` | 以硬連結（hard link）去重，釋放空間 |
| `nix store verify` | 驗證 store 完整性 |
| `nix copy --to ssh://host .#pkg` | 將套件的閉包複製到遠端主機 |
| `nix copy --from ssh://host /nix/store/...` | 從遠端主機拉取 store 路徑 |
| `nix copy --to file:///mnt/backup .#pkg` | 備份到本地 binary cache |

### 完整範例

**臨時試用套件不污染系統**

```bash
# 進入有 ripgrep、fd、bat 的一次性 shell
nix shell nixpkgs#ripgrep nixpkgs#fd nixpkgs#bat

# 執行完後 exit，這些工具就消失
exit
```

**分析套件佔用空間**

```bash
# 查看目前系統閉包大小（從大到小排序）
nix path-info -rsSh /run/current-system | sort -k2 -rn | head -20

# 比較兩次 nixos-rebuild 前後的變化
nix store diff-closures \
  /nix/var/nix/profiles/system-10-link \
  /nix/var/nix/profiles/system-11-link
```

**REPL 除錯**

```bash
# 開啟 REPL 並載入 nixpkgs
nix repl

# 在 REPL 內輸入：
:l <nixpkgs>         # 載入 nixpkgs
pkgs.git.version     # 查看 git 版本
builtins.attrNames pkgs.python3Packages | length  # 計算套件數量
```

---

## C.3 nix-env（傳統指令，Legacy）

> **不推薦在 NixOS 上使用。**
>
> `nix-env` 是 Nix 早期的套件管理指令，會在使用者個人的 profile（`~/.nix-profile/`）中安裝套件，與系統配置脫鉤，破壞 NixOS 的聲明式（declarative）原則。使用 `nix-env` 安裝的套件不會出現在 `configuration.nix` 或 `flake.nix` 中，難以重現、難以追蹤。

**正確做法：**
- 需要系統級套件 → 加入 `environment.systemPackages`
- 需要使用者級套件 → 使用 Home Manager 的 `home.packages`
- 臨時測試套件 → 使用 `nix shell` 或 `nix run`

**僅作參考：**

| 指令 | 說明 |
|------|------|
| `nix-env -iA nixpkgs.git` | 安裝 git 到個人 profile |
| `nix-env -e git` | 移除 git |
| `nix-env -q` | 列出已安裝套件 |
| `nix-env --rollback` | 回滾個人 profile |
| `nix-env --list-generations` | 列出個人世代 |

---

## C.4 nixos-option（查詢 NixOS 選項）

`nixos-option` 用來查詢 NixOS 模組選項的當前值與說明文件，在除錯時非常有用。

| 指令 | 說明 |
|------|------|
| `nixos-option services.nginx.enable` | 查詢選項當前值與說明 |
| `nixos-option boot.kernelPackages` | 查詢核心套件選項 |
| `nixos-option networking.firewall` | 查詢防火牆設定 |

**指定配置檔查詢**

```bash
# 不依賴 /etc/nixos，改用指定的配置檔
nixos-option -I nixos-config=./configuration.nix services.sshd.enable

# 搭配 Flake 使用時，先 eval 再查詢
nix eval .#nixosConfigurations.my-desktop.config.services.nginx.enable
```

**範例輸出解讀**

```bash
$ nixos-option services.nginx.enable
# 輸出範例：
Value:
false

Default:
false

Description:
Whether to enable the nginx Web Server.

Declared by:
  <nixpkgs/nixos/modules/services/web-servers/nginx/default.nix>
```

---

## C.5 nix-store（Store 管理）

`nix-store` 是 Nix Store 的底層管理工具，提供依賴查詢、驗證與修復功能。

| 指令 | 說明 |
|------|------|
| `nix-store --gc` | 執行垃圾回收，清理無 root 引用的路徑 |
| `nix-store -q --references /nix/store/...` | 查詢該路徑依賴哪些路徑（直接依賴） |
| `nix-store -q --referrers /nix/store/...` | 查詢哪些路徑依賴此路徑 |
| `nix-store -q --roots /nix/store/...` | 查詢保護此路徑的 GC roots |
| `nix-store -q --tree /nix/store/...` | 以樹狀顯示完整依賴樹 |
| `nix-store -q --requisites /nix/store/...` | 遞迴列出所有依賴（完整閉包） |
| `nix-store --verify --check-contents` | 驗證 store 完整性，含檔案雜湊校驗 |
| `nix-store --repair-path /nix/store/...` | 修復損壞的 store 路徑（重新下載） |
| `nix-store --print-env /nix/store/...-drv` | 印出 derivation 的建置環境變數 |
| `nix-store --realise /nix/store/...-drv` | 強制重建指定 derivation |

**實用查詢範例**

```bash
# 找出是什麼保持著某個 store 路徑不被 GC
nix-store -q --roots /nix/store/abc123-openssl-3.0

# 查看 git 的完整依賴樹
nix-store -q --tree $(which git)

# 找出所有 GC roots（包含 profiles 和 result 符號連結）
find /nix/var/nix/gcroots/ -type l -exec readlink -f {} \;
```

---

## C.6 nix-collect-garbage（清理 Store）

`nix-collect-garbage` 是 `nix-store --gc` 的包裝器，提供更方便的世代清理選項。

| 指令 | 說明 |
|------|------|
| `nix-collect-garbage` | 清理未被任何 root 引用的 store 路徑 |
| `nix-collect-garbage -d` | 先刪除所有舊世代，再執行 GC（釋放最多空間） |
| `nix-collect-garbage --delete-older-than 30d` | 刪除 30 天前的世代後執行 GC |
| `nix-collect-garbage --dry-run` | 模擬清理，只顯示會刪除的路徑 |

**清理流程建議**

```bash
# 步驟 1：確認目前所有世代
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# 步驟 2：模擬清理，確認影響範圍
nix-collect-garbage --dry-run

# 步驟 3：刪除 14 天前的舊世代並 GC
sudo nix-collect-garbage --delete-older-than 14d

# 步驟 4：去重 store 內容，進一步節省空間
nix store optimise

# 查看清理後磁碟使用量
df -h /nix
```

> **注意：** 在生產環境執行 `nix-collect-garbage -d` 前，請確認最新世代的系統是可開機的，因為此指令會刪除所有可回滾的舊世代。

---

## C.7 nixos-generate-config（產生初始配置）

`nixos-generate-config` 用於全新安裝時自動偵測硬體並產生初始 `configuration.nix`。

| 指令 | 說明 |
|------|------|
| `nixos-generate-config` | 在 `/etc/nixos/` 產生 `configuration.nix` 和 `hardware-configuration.nix` |
| `nixos-generate-config --root /mnt` | 為掛載在 `/mnt` 的目標系統產生配置 |
| `nixos-generate-config --dir ./output` | 將配置輸出到指定目錄 |
| `nixos-generate-config --show-hardware-config` | 只輸出硬體配置，不寫入檔案 |
| `nixos-generate-config --force` | 強制覆蓋現有配置（謹慎使用） |

**安裝流程中的標準用法**

```bash
# 完成磁碟分割與掛載後，在 /mnt 產生配置
nixos-generate-config --root /mnt

# 產生的兩個檔案：
# /mnt/etc/nixos/configuration.nix       <- 主配置（需手動編輯）
# /mnt/etc/nixos/hardware-configuration.nix  <- 硬體配置（自動維護）

# 編輯主配置
nano /mnt/etc/nixos/configuration.nix

# 安裝系統
nixos-install

# 重開機進入新系統
reboot
```

---

## C.8 deploy-rs / colmena（多主機部署）

這兩個工具用於管理多台 NixOS 主機的部署，適合伺服器叢集環境。

### deploy-rs

`deploy-rs` 是 Flake 原生的部署工具，使用 `flake.nix` 中的 `deploy` 輸出定義部署目標。

| 指令 | 說明 |
|------|------|
| `deploy .#host` | 部署 flake 中定義的指定主機 |
| `deploy` | 部署 flake 中所有定義的主機 |
| `deploy --dry-activate .#host` | 模擬部署，不實際套用 |
| `deploy --rollback .#host` | 回滾指定主機到上一個世代 |
| `deploy --skip-checks .#host` | 跳過部署前檢查（謹慎使用） |
| `deploy --ssh-user admin .#host` | 指定 SSH 使用者 |
| `deploy --hostname 192.168.1.10 .#host` | 覆蓋主機位址 |

**deploy-rs flake.nix 配置範例**

```nix
{
  outputs = { self, nixpkgs, deploy-rs, ... }: {
    nixosConfigurations.web-server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./hosts/web-server/configuration.nix ];
    };

    deploy.nodes.web-server = {
      hostname = "192.168.1.10";
      profiles.system = {
        sshUser = "admin";
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos
          self.nixosConfigurations.web-server;
      };
    };
  };
}
```

### colmena

`colmena` 是另一個多主機部署工具，配置格式與 `nixosConfigurations` 相近，上手門檻較低。

| 指令 | 說明 |
|------|------|
| `colmena apply` | 部署所有主機 |
| `colmena apply --on web-server` | 只部署 `web-server` 這台 |
| `colmena apply --on 'tag:production'` | 部署所有有 `production` tag 的主機 |
| `colmena build` | 只建置，不部署（本機快取） |
| `colmena upload-keys` | 只上傳 secrets，不重建配置 |
| `colmena exec --on web-server -- systemctl restart nginx` | 在指定主機執行指令 |
| `colmena nix-info` | 顯示各主機的 Nix 版本資訊 |

**colmena hive.nix 配置範例**

```nix
{
  meta = {
    nixpkgs = import <nixpkgs> { system = "x86_64-linux"; };
  };

  defaults = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.vim ];
  };

  web-server = { name, nodes, ... }: {
    deployment.targetHost = "192.168.1.10";
    deployment.targetUser = "admin";
    services.nginx.enable = true;
  };

  db-server = {
    deployment.targetHost = "192.168.1.20";
    services.postgresql.enable = true;
  };
}
```

---

## C.9 home-manager（Home Manager 指令）

Home Manager 管理使用者層級的 dotfiles 和套件，與系統配置互相補充。

### 獨立安裝模式（Standalone）

| 指令 | 說明 |
|------|------|
| `home-manager switch` | 套用 `~/.config/home-manager/home.nix` 配置 |
| `home-manager switch --flake .#user@host` | 使用 Flake 指定使用者配置 |
| `home-manager switch --flake .#user@host -b backup` | 切換前備份原有 dotfiles |
| `home-manager build` | 只建置，不套用，結果在 `./result` |
| `home-manager build --flake .#user@host` | 使用 Flake 只建置 |
| `home-manager generations` | 列出所有 Home Manager 世代 |
| `home-manager expire-generations -30d` | 清理 30 天前的舊世代 |
| `home-manager rollback` | 回滾到上一個世代 |
| `home-manager news` | 查看 Home Manager 的更新提示 |
| `home-manager uninstall` | 移除 Home Manager（危險，謹慎使用） |

**常用操作範例**

```bash
# 修改 home.nix 後套用，並顯示差異
home-manager switch --flake .#shiichi@my-desktop

# 列出世代並清理舊的
home-manager generations
home-manager expire-generations -14d

# 查看 Home Manager 管理的檔案
home-manager packages      # 列出管理的套件
ls -la ~/.local/share/home-manager/  # 查看世代連結
```

### NixOS 模組整合模式

當 Home Manager 以 NixOS module 方式整合時，使用 `nixos-rebuild switch` 同時更新系統和使用者配置，不需要獨立的 `home-manager` 指令。

---

## C.10 實用的系統診斷指令

### 系統版本資訊

| 指令 | 說明 |
|------|------|
| `nixos-version` | 顯示 NixOS 版本（如 `25.05.20240101.abcdef`） |
| `nix --version` | 顯示 Nix 版本 |
| `nix-info -m` | 顯示完整 Nix 環境資訊（版本、架構、features） |
| `uname -r` | 顯示目前執行中的 Linux 核心版本 |
| `cat /etc/os-release` | 顯示 NixOS 發行版資訊 |

### systemd 服務診斷

| 指令 | 說明 |
|------|------|
| `systemctl list-units --failed` | 列出所有啟動失敗的服務 |
| `systemctl status nginx.service` | 查看 nginx 服務狀態與最近日誌 |
| `systemctl restart nginx.service` | 重啟服務 |
| `systemctl enable --now nginx.service` | 啟用並立即啟動服務 |
| `systemctl cat nginx.service` | 查看服務的 unit 檔案內容 |
| `systemctl list-dependencies nginx.service` | 查看服務依賴樹 |

### journald 日誌查詢

| 指令 | 說明 |
|------|------|
| `journalctl -xe` | 查看最新系統日誌，含說明連結 |
| `journalctl -u nginx.service` | 查看 nginx 服務的所有日誌 |
| `journalctl -u nginx.service -f` | 即時追蹤 nginx 日誌（`-f` follow） |
| `journalctl -u nginx.service -n 50` | 只看最後 50 行日誌 |
| `journalctl --since "1 hour ago"` | 查看最近一小時的日誌 |
| `journalctl --since "2025-01-01" --until "2025-01-02"` | 查看指定時間範圍日誌 |
| `journalctl -p err` | 只顯示 error 等級以上的日誌 |
| `journalctl --disk-usage` | 查看日誌佔用磁碟空間 |
| `journalctl --vacuum-size=500M` | 清理日誌，保留最近 500MB |

### Nix Store 路徑查詢

| 指令 | 說明 |
|------|------|
| `readlink -f /run/current-system` | 查看目前系統的 store 路徑 |
| `ls /run/current-system/sw/bin/` | 瀏覽目前系統可用的工具 |
| `which git` | 確認 git 來自哪個 store 路徑 |
| `nix-store -q --references $(which git)` | 查看 git 的直接依賴 |

### 網路診斷

```bash
# 查看 NixOS 管理的防火牆規則
sudo iptables -L -n -v

# 查看 systemd-networkd 管理的網路介面
networkctl status

# 查看 NetworkManager 連線狀態
nmcli general status
nmcli connection show
```

### 完整診斷流程範例

```bash
# 1. 確認系統版本
nixos-version

# 2. 查看失敗的服務
systemctl list-units --failed

# 3. 查看特定服務的詳細錯誤
journalctl -u 失敗服務名稱 -n 100

# 4. 重建系統並顯示完整追蹤
sudo nixos-rebuild switch --show-trace 2>&1 | tee /tmp/rebuild.log

# 5. 查看建置日誌
nix log /nix/store/...-失敗套件.drv
```

---

## C.11 Nix REPL 常用操作

進入 REPL 後的常用指令（在 REPL 提示符 `nix-repl>` 輸入）：

```
# 載入 nixpkgs（傳統方式）
:l <nixpkgs>

# 載入本地 flake
:lf .

# 查看屬性
pkgs.git

# 查看所有屬性名稱
builtins.attrNames pkgs | length

# 求值並顯示型別
:t pkgs.git

# 查看 derivation 詳情
pkgs.git.meta

# 追蹤求值過程（除錯用）
:e pkgs.git

# 結束 REPL
:q
```

---

## C.12 常用路徑速查

| 路徑 | 用途 |
|------|------|
| `/etc/nixos/configuration.nix` | 傳統系統主配置檔 |
| `/etc/nixos/hardware-configuration.nix` | 硬體配置（自動生成） |
| `/nix/store/` | Nix Store 根目錄（不可手動修改） |
| `/nix/var/nix/profiles/system` | 目前系統 profile 符號連結 |
| `/nix/var/nix/profiles/system-*-link` | 各個世代的符號連結 |
| `/run/current-system` | 目前執行中系統的 store 路徑 |
| `/run/booted-system` | 本次開機時使用的系統路徑 |
| `/nix/var/nix/gcroots/` | GC roots 目錄 |
| `~/.nix-profile` | 使用者個人 profile（`nix-env` 使用） |
| `~/.config/home-manager/home.nix` | Home Manager 主配置 |

---

## C.13 快速備忘卡

### 日常操作

```bash
# 修改配置後套用
sudo nixos-rebuild switch --flake .#$(hostname)

# 測試不確定的改動
sudo nixos-rebuild test --flake .#$(hostname)

# 出問題了，回到上一版
sudo nixos-rebuild switch --rollback

# 更新 nixpkgs 並套用
nix flake update && sudo nixos-rebuild switch --flake .#$(hostname)
```

### 清理磁碟空間

```bash
# 安全清理：刪除兩週前世代
sudo nix-collect-garbage --delete-older-than 14d

# 徹底清理（刪除所有舊世代）
sudo nix-collect-garbage -d

# 去重節省空間
nix store optimise

# 查看清理結果
df -h /nix
```

### 除錯

```bash
# 查看完整錯誤
sudo nixos-rebuild switch --show-trace 2>&1 | less

# 查看系統日誌
journalctl -xe | less

# 確認服務狀態
systemctl list-units --failed
```
