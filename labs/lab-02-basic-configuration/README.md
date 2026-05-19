# Lab 2：建立模組化桌面配置

**對應章節：** 第 4–5 章

---

## 目標

完成本 Lab 後，你將能夠：

- 把單一大型 `configuration.nix` 拆分為多個功能模組
- 理解 `imports` 的合併機制（多個模組的選項如何自動整合）
- 建立 `users.nix`、`packages.nix`、`services.nix`、`desktop.nix` 四個功能模組
- 體驗模組化帶來的可維護性提升

---

## 前置要求

- 完成 Lab 1（已有可運作的 NixOS 環境）
- 完成第 4、5 章閱讀
- 對 `imports` 機制有基本了解

---

## 建議環境

- 已安裝 NixOS 25.05 的實體機或虛擬機
- 具備 `sudo` 權限的一般使用者帳號（本 Lab 使用 `alice` 作為範例帳號）
- 終端機模擬器（Terminal Emulator）

---

## Step 1：查看目前的 configuration.nix

先備份原始設定，再觀察現有結構。

### 1-1 備份原始設定

```bash
sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.bak
```

### 1-2 查看目前內容

```bash
cat /etc/nixos/configuration.nix
```

**預期看到類似以下的「混在一起」的設定：**

```nix
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # 網路
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # 時區與語言
  time.timeZone = "Asia/Taipei";
  i18n.defaultLocale = "en_US.UTF-8";

  # 使用者
  users.users.alice = {
    isNormalUser = true;
    description = "Alice";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.bash;
  };

  # 桌面環境
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # 音效
  hardware.pulseaudio.enable = false;
  services.pipewire.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.pulse.enable = true;

  # 套件
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    htop
  ];

  # SSH
  services.openssh.enable = true;

  system.stateVersion = "25.05";
}
```

**這就是我們要拆分的對象。**

所有設定全部堆在同一個檔案裡。當系統變複雜，這個檔案會越來越長，越來越難維護。模組化（Modularization）能解決這個問題。

---

## Step 2：建立 users.nix

### 2-1 建立檔案

```bash
sudo vim /etc/nixos/users.nix
```

### 2-2 寫入以下內容

```nix
{ config, pkgs, ... }:

{
  # 使用者（User）定義
  users.users.alice = {
    isNormalUser = true;
    description = "Alice";
    extraGroups = [
      "wheel"          # 允許使用 sudo
      "networkmanager" # 允許管理網路
    ];
    shell = pkgs.bash;
  };
}
```

### 2-3 說明

為什麼 `users` 值得獨立一個模組？

- 使用者設定通常在多台機器之間**共用**。你在工作機和家用機都想要相同的使用者帳號，只需要 import 同一個 `users.nix`。
- 使用者設定與桌面環境、服務設定**無關**，獨立後更清晰。
- 未來要新增群組或調整 shell，只需要改一個地方。

---

## Step 3：建立 packages.nix

### 3-1 建立檔案

```bash
sudo vim /etc/nixos/packages.nix
```

### 3-2 寫入以下內容

```nix
{ config, pkgs, ... }:

{
  # 系統套件（System Packages）：所有使用者都能使用的工具
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    htop
    tree
    unzip
  ];
}
```

### 3-3 說明

`environment.systemPackages`（系統套件）是安裝在整個系統層級的套件，所有使用者都能使用。

把套件集中在一個檔案，讓你一眼就能看到「這台機器安裝了什麼」，不必在長達數百行的 `configuration.nix` 裡搜尋。

---

## Step 4：建立 services.nix

### 4-1 建立檔案

```bash
sudo vim /etc/nixos/services.nix
```

### 4-2 寫入以下內容

```nix
{ config, pkgs, ... }:

{
  # SSH 服務（Secure Shell）：遠端登入
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false; # 禁止密碼登入，只允許金鑰
    settings.PermitRootLogin = "no";         # 禁止 root 直接登入
  };

  # 印表機支援（可選）
  services.printing.enable = true;
}
```

### 4-3 說明

`services.nix` 集中管理**後台服務（Background Service）**。這些服務在系統啟動時自動執行，與桌面環境的設定邏輯不同，因此獨立出來。

注意 `settings.PasswordAuthentication = false`：這是一個重要的安全設定，禁止透過密碼登入 SSH，只允許使用 SSH 金鑰（Public Key）登入。如果你還沒設定 SSH 金鑰，請先略過這行，或先設定好金鑰再啟用。

---

## Step 5：建立 desktop.nix

### 5-1 建立檔案

```bash
sudo vim /etc/nixos/desktop.nix
```

### 5-2 寫入以下內容

```nix
{ config, pkgs, ... }:

{
  # 顯示系統（Display Server）：X11
  services.xserver.enable = true;

  # GNOME 桌面環境（Desktop Environment）
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # 音效系統：PipeWire（取代舊的 PulseAudio）
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;  # PulseAudio 相容介面
  };

  # 字型（Fonts）
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans  # 中日韓字型
    noto-fonts-emoji
  ];
}
```

### 5-3 說明

`desktop.nix` 把所有「桌面體驗」相關的設定集中在一起：顯示系統、桌面環境、音效、字型。

這個模組的好處是：如果你有一台沒有桌面的伺服器，只需要在 `configuration.nix` 的 `imports` 裡移除 `./desktop.nix` 這一行，就能得到一個純文字介面的系統。不需要在長長的設定檔中一行一行刪除。

---

## Step 6：重構 configuration.nix（重點步驟）

現在把原本龐雜的 `configuration.nix` 精簡為一個骨架（Skeleton）。

### 6-1 開啟 configuration.nix

```bash
sudo vim /etc/nixos/configuration.nix
```

### 6-2 將內容替換為以下骨架

```nix
{ config, pkgs, ... }:

{
  imports = [
    # 硬體配置（Hardware Configuration）：由安裝程序自動生成，請不要修改
    ./hardware-configuration.nix

    # 功能模組
    ./users.nix
    ./packages.nix
    ./services.nix
    ./desktop.nix
  ];

  # 主機名稱（Hostname）：每台機器不同，留在這裡
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # 時區與語言（每台機器可能不同，留在這裡）
  time.timeZone = "Asia/Taipei";
  i18n.defaultLocale = "en_US.UTF-8";

  # Bootloader：與硬體密切相關，留在這裡
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # 系統版本（System State Version）：不要隨意修改
  system.stateVersion = "25.05";
}
```

### 6-3 什麼應該留在 configuration.nix？

重構後的 `configuration.nix` 只保留三類設定：

| 類別 | 範例 | 原因 |
|------|------|------|
| 機器唯一識別 | `hostName`、`stateVersion` | 每台機器都不同，不適合放進共用模組 |
| Bootloader | `boot.loader.*` | 與硬體型號密切相關 |
| imports 列表 | `./users.nix` 等 | 這裡是模組的「目錄頁」，總覽所有功能 |

**核心概念：** `configuration.nix` 是**入口點（Entry Point）**，不是「什麼都放」的地方。功能細節由各模組負責。

---

## Step 7：驗證模組化配置

### 7-1 查看目前的檔案結構

```bash
ls -la /etc/nixos/
```

**預期輸出：**

```
total 48
drwxr-xr-x 2 root root 4096 May 13 10:00 .
drwxr-xr-x 3 root root 4096 May 13 09:00 ..
-rw-r--r-- 1 root root  512 May 13 09:00 configuration.nix.bak
-rw-r--r-- 1 root root  480 May 13 10:00 configuration.nix
-rw-r--r-- 1 root root  320 May 13 10:00 desktop.nix
-rw-r--r-- 1 root root  180 May 13 10:00 hardware-configuration.nix
-rw-r--r-- 1 root root  210 May 13 10:00 packages.nix
-rw-r--r-- 1 root root  250 May 13 10:00 services.nix
-rw-r--r-- 1 root root  200 May 13 10:00 users.nix
```

### 7-2 語法驗證（乾跑）

```bash
sudo nixos-rebuild dry-run
```

**乾跑（Dry Run）** 不會真正更改系統，只會計算「如果 rebuild 的話，會有哪些改變」。

**預期輸出（範例）：**

```
building the system configuration...
these derivations will be built:
  /nix/store/...-nixos-system-nixos-25.05.drv
```

如果出現語法錯誤，輸出會清楚指出是哪個檔案、哪一行出了問題。請根據錯誤訊息修正後再次執行。

### 7-3 套用新配置

確認 dry-run 沒有錯誤後，正式套用：

```bash
sudo nixos-rebuild switch
```

**`switch`** 的意思是：建構（Build）新的系統配置，並立刻切換到這個新配置，讓所有服務生效。

**預期輸出（範例）：**

```
building the system configuration...
activating the configuration...
setting up /etc...
restarting the following units: sshd.service
```

出現 `activation finished` 或命令順利返回提示符，即表示套用成功。

### 7-4 驗證各項功能

**驗證一：SSH 服務正在執行**

```bash
systemctl status sshd
```

**預期輸出：**

```
● sshd.service - OpenSSH Daemon
     Loaded: loaded (/etc/systemd/system/sshd.service; enabled; preset: enabled)
     Active: active (running) since ...
```

看到 `Active: active (running)` 即為正常。

**驗證二：安裝的套件可以使用**

```bash
git --version
```

**預期輸出：**

```
git version 2.47.0
```

```bash
htop --version
```

**預期輸出（範例）：**

```
htop 3.3.0
```

**驗證三：查看世代（Generation）已增加**

```bash
nixos-rebuild list-generations
```

**預期輸出（範例）：**

```
Generation  Build-date           NixOS version  Kernel       Configuration Revision
         1  2026-05-13 09:00:00  25.05          6.6.86
         2  2026-05-13 10:00:00  25.05          6.6.86       (current)
```

世代（Generation）是 NixOS 每次 rebuild 後保留的系統快照（Snapshot）。`(current)` 代表目前正在使用的世代。

---

## Step 8：新增一個模組並體驗模組化的優勢

### 8-1 建立 security.nix

```bash
sudo vim /etc/nixos/security.nix
```

寫入以下內容：

```nix
{ config, pkgs, ... }:

{
  # 防火牆（Firewall）設定
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];  # 只開放 SSH 埠

  # 限制 sudo：只有 wheel 群組成員可以使用
  security.sudo.execWheelOnly = true;

  # 系統日誌（Journal）大小限制，避免佔用過多磁碟空間
  services.journald.extraConfig = "SystemMaxUse=1G";
}
```

### 8-2 在 configuration.nix 的 imports 中加入 security.nix

```bash
sudo vim /etc/nixos/configuration.nix
```

在 `imports` 區塊加入一行：

```nix
  imports = [
    ./hardware-configuration.nix
    ./users.nix
    ./packages.nix
    ./services.nix
    ./desktop.nix
    ./security.nix    # <-- 新增這一行
  ];
```

### 8-3 套用新配置

```bash
sudo nixos-rebuild switch
```

### 8-4 驗證防火牆已啟用

```bash
sudo systemctl status firewall
```

或：

```bash
sudo nft list ruleset
```

**這就是模組化的核心優勢：**

只需要新增一個檔案，再在 `imports` 裡加入一行，就能把一整套安全性設定加入系統。不需要在龐雜的 `configuration.nix` 中尋找「插入點」，也不會不小心破壞其他設定。

---

## 常見問題

### 問題 1：`error: attribute 'xxx' missing`

**症狀：** rebuild 時出現類似 `error: attribute 'noto-fonts-cjk-sans' missing` 的錯誤。

**原因：** 套件名稱（Package Name）不正確，或在目前的 NixOS 版本中已改名。

**解法：**

```bash
# 搜尋正確的套件名稱
nix search nixpkgs noto-fonts-cjk
```

或前往 [search.nixos.org](https://search.nixos.org/packages) 搜尋。

---

### 問題 2：`The option 'xxx' does not exist`

**症狀：** 出現類似 `The option 'services.xserver.displayManager.gdm.enable' does not exist` 的錯誤。

**原因：** Option 路徑（Option Path）不正確，或該 option 在目前版本已搬移到不同位置。

**解法：**

```bash
# 查詢 option 是否存在及正確路徑
nixos-option services.xserver.displayManager
```

或前往 [search.nixos.org/options](https://search.nixos.org/options) 搜尋。

---

### 問題 3：模組檔案找不到

**症狀：** 出現類似 `error: getting status of '/etc/nixos/desktop.nix': No such file or directory` 的錯誤。

**原因：** `imports` 中指定的路徑與實際檔案位置不符。

**解法：**

```bash
# 確認 /etc/nixos 目錄內的檔案
ls /etc/nixos/
```

`imports` 使用的是**相對路徑（Relative Path）**，相對於 `configuration.nix` 所在的目錄。`./desktop.nix` 代表「與 `configuration.nix` 同一個目錄的 `desktop.nix`」。

---

### 問題 4：某個設定「消失」了

**症狀：** 原本可以使用的設定，在拆分模組後失效了（例如使用者 `alice` 不見了）。

**原因：** 忘記在 `imports` 裡加入對應的模組。

**解法：**

```bash
# 確認 configuration.nix 的 imports 列表完整
cat /etc/nixos/configuration.nix
```

確認每個模組檔案都有對應的 `import` 條目。

---

### 問題 5：rebuild 後系統無法開機

**解法：**

在 GRUB 開機選單中選擇**上一個世代（Previous Generation）** 即可回到正常狀態。NixOS 的每次 rebuild 都會保留上一個世代，這是 NixOS 最重要的安全網。

進入舊世代後，再用 `cat /etc/nixos/configuration.nix.bak` 確認備份，找出問題所在。

---

## 延伸練習

### 練習 1：建立 development.nix 模組

建立 `/etc/nixos/development.nix`，包含你需要的開發工具：

```nix
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    neovim
    git
    nodejs
    python3
    gcc
    gnumake
  ];
}
```

在 `configuration.nix` 的 `imports` 加入 `./development.nix`，然後 rebuild。

---

### 練習 2：建立 fonts.nix 模組

把 `desktop.nix` 中的字型設定獨立為 `/etc/nixos/fonts.nix`，集中管理所有字型安裝。

---

### 練習 3：觀察 NixOS 的列表合併行為

在 `services.nix` 和 `security.nix` 中都設定 `networking.firewall.allowedTCPPorts`：

```nix
# services.nix 中
networking.firewall.allowedTCPPorts = [ 80 443 ];

# security.nix 中
networking.firewall.allowedTCPPorts = [ 22 ];
```

執行 rebuild，然後查詢最終結果：

```bash
nixos-option networking.firewall.allowedTCPPorts
```

觀察 NixOS 如何自動將兩個模組的列表**合併（Merge）** 為 `[ 22 80 443 ]`，而不是互相覆蓋。

---

### 練習 4：移除模組並觀察結果

把 `users.nix` 從 `imports` 中移除（只移除 import 條目，不刪除檔案），然後執行 dry-run：

```bash
sudo nixos-rebuild dry-run
```

觀察輸出，理解「使用者帳號即將消失」對系統的影響。**確認後，務必把 `./users.nix` 加回 `imports`，再執行 `switch`。**

---

### 練習 5：建立 Profile 層

建立 `/etc/nixos/profiles/desktop-full.nix`：

```bash
sudo mkdir -p /etc/nixos/profiles
sudo vim /etc/nixos/profiles/desktop-full.nix
```

```nix
{ config, pkgs, ... }:

{
  imports = [
    ../users.nix
    ../packages.nix
    ../desktop.nix
  ];
}
```

將 `configuration.nix` 的 imports 改為只引入這一個 Profile 檔案：

```nix
  imports = [
    ./hardware-configuration.nix
    ./profiles/desktop-full.nix
    ./services.nix
    ./security.nix
  ];
```

體驗「Profile 層（Profile Layer）」的概念：用一個 Profile 把相關模組打包在一起，讓 `configuration.nix` 更精簡。

---

**完成本 Lab，你已經建立了第一個模組化的 NixOS 配置。**

下一步：前往 Lab 3，學習使用 Flakes 管理系統配置，進一步提升可複製性（Reproducibility）與可攜性（Portability）。
