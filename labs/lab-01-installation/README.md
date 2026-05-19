# Lab 1：安裝你的第一個 NixOS VM

**對應章節：** 第 1–3 章

---

## 目標

完成本 Lab 後，你將能夠：

- 安裝 NixOS 25.05 到虛擬機（VM，Virtual Machine）
- 讀懂安裝程序自動生成的 `configuration.nix` 基本結構
- 對 `configuration.nix` 進行第一次有意義的修改
- 執行 `nixos-rebuild switch` 並理解每個階段發生了什麼
- 使用 rollback（回滾）切換回上一個 generation（世代）

---

## 前置要求

- 已完成第 1 章閱讀
- 主機上已安裝 VirtualBox 7.x、VMware Workstation 或 KVM 其中之一
- 主機磁碟有 50 GB 以上可用空間
- 穩定的網路連線（安裝過程需要下載套件）

---

## 建議環境

| 項目 | 規格 |
|---|---|
| Hypervisor | VirtualBox 7.x / VMware Workstation / KVM |
| RAM | 4 GB（最低）/ 8 GB（建議） |
| CPU | 2 核心（最低）/ 4 核心（建議） |
| 磁碟 | 30 GB（最低）/ 50 GB（建議） |
| 網路 | NAT 或 Bridged |
| 韌體 | EFI（建議） |

---

## Step 1：下載 NixOS ISO

### 步驟說明

前往 NixOS 官方網站，下載 GNOME Graphical Installer（圖形安裝程序）版本。

GNOME Installer 包含完整的桌面環境，方便新手操作。Minimal ISO（最小化映像檔）不含圖形介面，需要手動輸入所有配置指令，**不建議初學者使用**。

### 操作步驟

1. 開啟瀏覽器，前往：`https://nixos.org/download/`
2. 在「NixOS: the Linux distribution」區段，選擇 **GNOME**（ISO 檔名形如 `nixos-gnome-25.05.*.iso`）
3. 點選下載連結，等待下載完成
4. 記錄 ISO 檔案的存放路徑（例如：`~/Downloads/nixos-gnome-25.05.iso`）

### 預期結果

下載完成後，你應該看到一個約 2–3 GB 的 `.iso` 檔案。

---

## Step 2：建立虛擬機

### 步驟說明

以下以 **VirtualBox 7.x** 為範例，建立一台新虛擬機並掛載 ISO。

其他 hypervisor（VMware、KVM）的設定方式類似，核心概念相同。

### 操作步驟

**1. 新增虛擬機**

開啟 VirtualBox，點選上方工具列的「New」（新增）。

依序填入或選擇：

| 欄位 | 值 |
|---|---|
| Name | nixos-lab-01 |
| Machine Folder | （使用預設路徑即可） |
| Type | Linux |
| Version | Ubuntu（64-bit） |

> NixOS 目前沒有專屬的版本選項，選擇「Ubuntu（64-bit）」在功能上完全相容。

**2. 設定記憶體與 CPU**

- Base Memory（記憶體）：設定為 **4096 MB**（4 GB）
- Processors（CPU）：設定為 **2**

**3. 建立虛擬磁碟**

- 選擇「Create a Virtual Hard Disk Now」
- 硬碟格式：**VDI（VirtualBox Disk Image）**
- 分配方式：**Dynamically allocated（動態分配）**
- 大小：**50 GB**

**4. 啟用 EFI**

完成建立後，進入虛擬機的「Settings」→「System」→「Motherboard」：

- 勾選「Enable EFI（special OSes only）」

EFI（Extensible Firmware Interface，可延伸韌體介面）是現代電腦的啟動介面，NixOS 對 EFI 的支援更完整，建議啟用。

**5. 掛載 ISO**

進入「Settings」→「Storage」：

- 點選「Controller: IDE」下的光碟機圖示（Empty）
- 點選右側光碟機圖示，選擇「Choose a disk file...」
- 找到剛才下載的 ISO 檔案，點選確認

### 預期結果

虛擬機清單中出現「nixos-lab-01」，狀態為「Powered Off」。進入「Settings」→「Storage」可以看到 ISO 已掛載到光碟機。

---

## Step 3：啟動安裝程序

### 步驟說明

啟動虛擬機，進入 NixOS 圖形安裝程序，完成基本系統設定。

### 操作步驟

**1. 啟動虛擬機**

在 VirtualBox 主畫面選取「nixos-lab-01」，點選「Start」（啟動）。

等待 GNOME 桌面載入完成，約需 30–60 秒。

**2. 開啟安裝程序**

桌面上有一個「Install NixOS」圖示，雙擊開啟安裝程序。

**3. 語言選擇**

- Language：選擇 **English**（建議使用英文，避免介面翻譯不完整的問題）
- Keyboard Layout：選擇適合你的鍵盤配置，台灣用戶一般選 **US**

**4. 時區設定**

- Timezone：在地圖上點選台灣，或直接搜尋 **Asia/Taipei**

**5. 磁碟分割**

- 選擇「Erase disk」（清除磁碟，自動分割）
- 確認目標磁碟是剛才建立的 50 GB 虛擬磁碟（通常顯示為 `/dev/sda` 或 `/dev/vda`）

> 這台是虛擬機，磁碟清除不影響主機，放心選擇自動分割。

**6. 建立使用者帳號**

| 欄位 | 值 |
|---|---|
| Your name（全名） | Alice |
| Username（帳號） | alice |
| Password（密碼） | 設定一個你記得住的密碼 |
| Hostname（主機名稱） | nixos-lab |

- 勾選「Use the same password for the administrator account」

**7. 開始安裝**

確認摘要頁面的所有資訊無誤，點選「Install」（安裝）。

### 預期結果

進度條開始推進，安裝過程大約需要 5–15 分鐘（視網路速度而定）。畫面上會顯示目前正在進行的步驟，例如「Downloading packages」或「Installing packages」。

---

## Step 4：完成安裝

### 步驟說明

安裝完成後，移除 ISO 映像檔並重新開機，確保系統從硬碟啟動。

### 操作步驟

**1. 安裝完成提示**

安裝程序顯示「Installation Finished」時，點選「Done」（完成），但**先不要重新開機**。

**2. 移除 ISO（VirtualBox）**

在 VirtualBox 選單列中，前往「Devices」→「Optical Drives」→「Remove disk from virtual drive」。

或者，先關閉虛擬機，前往「Settings」→「Storage」，移除光碟機中掛載的 ISO 後再啟動。

**3. 重新開機**

在安裝完成的畫面點選「Restart Now」，或在終端機輸入：

```bash
sudo reboot
```

### 預期結果

虛擬機重新開機後，出現 systemd-boot（啟動選單），顯示「NixOS (Generation 1, 25.05...)」，選擇此項目後進入 GNOME 桌面。

以 `alice` 帳號登入，確認桌面正常顯示。

---

## Step 5：探索 configuration.nix

### 步驟說明

`/etc/nixos/configuration.nix` 是 NixOS 的核心配置檔案。安裝程序在安裝過程中自動生成這份檔案，記錄了整台機器的系統宣告。

打開終端機（Terminal），查看這份檔案的內容。

### 操作步驟

```bash
# 查看安裝程序生成的配置檔案
cat /etc/nixos/configuration.nix
```

### 預期結果

你會看到類似以下的內容（每台機器的細節略有不同）：

```nix
# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-lab"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Taipei";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Define a user account.
  users.users.alice = {
    isNormalUser = true;
    description = "Alice";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      firefox
    ];
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    vim
    wget
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and databases, are
  # compatible. Read the release notes before changing it.
  system.stateVersion = "25.05"; # Did you read the comment?
}
```

### 逐行解析

| 區塊 | 說明 |
|---|---|
| `{ config, pkgs, ... }:` | 函式簽名（function signature）。NixOS 配置本質上是一個 Nix 函式，接收 `config`（當前系統配置）和 `pkgs`（套件集合）作為輸入。 |
| `imports = [ ./hardware-configuration.nix ]` | 引入硬體掃描結果。這份檔案由安裝程序自動生成，描述磁碟、CPU、韌體等硬體細節。 |
| `boot.loader.systemd-boot.enable = true` | 啟用 systemd-boot（啟動管理程式）。這就是重新開機時出現的選單。 |
| `networking.hostName = "nixos-lab"` | 宣告主機名稱。修改後重新 rebuild，`hostname` 指令會立即反映新名稱。 |
| `time.timeZone = "Asia/Taipei"` | 宣告系統時區。 |
| `users.users.alice = { ... }` | 宣告使用者帳號。`extraGroups` 列表中的 `"wheel"` 代表允許使用 `sudo`（超級使用者權限）。 |
| `environment.systemPackages = with pkgs; [ ... ]` | 宣告系統層級可用的套件。所有使用者都能使用這份列表中的工具。 |
| `system.stateVersion = "25.05"` | 記錄系統初始安裝時的 NixOS 版本。**不要隨意更改這個值**，它用於相容性判斷，不代表實際使用的版本。 |

---

## Step 6：第一次修改配置

### 步驟說明

在 `environment.systemPackages` 中加入兩個實用工具：`htop`（互動式行程監控）和 `tree`（目錄樹狀顯示）。

這是你與 NixOS 宣告式配置（declarative configuration）的第一次真實互動。

### 操作步驟

使用 `vim` 或 `nano` 開啟配置檔案：

```bash
sudo vim /etc/nixos/configuration.nix
```

找到 `environment.systemPackages` 區塊，修改成以下內容：

```nix
{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-lab";
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Taipei";
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  users.users.alice = {
    isNormalUser = true;
    description = "Alice";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      firefox
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    htop    # 新增：互動式行程監控工具
    tree    # 新增：目錄樹狀顯示工具
  ];

  system.stateVersion = "25.05";
}
```

儲存並離開編輯器（vim 請按 `Esc` 後輸入 `:wq`，nano 請按 `Ctrl+O` 後 `Ctrl+X`）。

### 預期結果

檔案儲存後，在終端機中可以用以下指令確認修改已寫入：

```bash
grep -n "htop\|tree" /etc/nixos/configuration.nix
```

你應該看到輸出中含有 `htop` 和 `tree` 的行號與內容。

---

## Step 7：執行 nixos-rebuild switch

### 步驟說明

`nixos-rebuild switch` 是 NixOS 的核心指令。它讀取 `/etc/nixos/configuration.nix`，計算系統應有的狀態，下載並建置所有必要的套件，然後**即時切換**到新的系統配置，不需要重新開機。

### 操作步驟

```bash
sudo nixos-rebuild switch
```

### 預期輸出解析

指令執行後，你會看到類似以下的輸出：

```
building Nix...
building the system configuration...
these 3 paths will be fetched (12.34 MiB download, 45.67 MiB unpacked):
  /nix/store/abc123...-htop-3.3.0
  /nix/store/def456...-tree-2.1.1
  /nix/store/ghi789...-system-path
copying path '/nix/store/abc123...-htop-3.3.0' from 'https://cache.nixos.org'...
copying path '/nix/store/def456...-tree-2.1.1' from 'https://cache.nixos.org'...
building '/nix/store/ghi789...-system-path.drv'...
activating the configuration...
```

| 訊息 | 意義 |
|---|---|
| `these N paths will be fetched` | Nix 計算出需要下載哪些套件（binary cache，二進位快取） |
| `copying path ... from 'https://cache.nixos.org'` | 從 NixOS 官方快取伺服器下載預編譯好的套件 |
| `building '...'` | 建置（組合）新的系統路徑 |
| `activating the configuration...` | 切換系統符號連結（symlink），讓新配置生效 |

**關於執行時間：**

- 第一次執行通常需要 2–10 分鐘（視網路速度和套件大小）。
- 後續修改只需下載差異部分，速度會快很多。
- `cache.nixos.org` 是 NixOS 的官方 binary cache（二進位快取），提供預編譯好的套件，大多數情況下不需要在本機編譯原始碼。

### 預期結果

指令結束後不出現任何錯誤訊息，終端機回到命令提示符號（`$`）。

---

## Step 8：驗證變更生效

### 步驟說明

rebuild 完成後，執行以下指令確認新套件已安裝，並查看 generation 列表。

### 操作步驟

**確認 htop 可以執行：**

```bash
htop
```

按 `q` 離開 htop。

**確認 tree 可以執行：**

```bash
tree /etc/nixos
```

### 預期結果（tree 輸出）

```
/etc/nixos
├── configuration.nix
└── hardware-configuration.nix

1 directory, 2 files
```

**查看目前的 generation 列表：**

```bash
nixos-rebuild list-generations
```

### 預期結果（generation 列表）

```
Generation  Build-date           NixOS version        Kernel  Configuration Revision  Specialisation
1           2026-05-18 10:00:00  25.05 (Emerald Eye)  6.12    n/a
2           2026-05-18 10:30:00  25.05 (Emerald Eye)  6.12    n/a                     (current)
```

Generation 1 是安裝程序建立的初始系統。Generation 2 是你剛才執行 `nixos-rebuild switch` 後建立的新世代。`(current)` 表示目前正在使用的世代。

**測試 rollback（回滾）：**

```bash
sudo nixos-rebuild switch --rollback
```

再次查看 generation 列表：

```bash
nixos-rebuild list-generations
```

你會看到 `(current)` 回到 Generation 1，且 `htop` 和 `tree` 不再可用（因為 Generation 1 的配置不包含這些套件）。

**切換回 Generation 2：**

```bash
sudo nixos-rebuild switch
```

或者直接指定 generation 編號：

```bash
sudo /nix/var/nix/profiles/system-2-link/bin/switch-to-configuration switch
```

---

## 常見問題

### Q1：虛擬機啟動後顯示黑畫面

**原因：** VirtualBox 的 3D 加速與某些顯示驅動程式衝突。

**解法：** 關閉虛擬機，進入「Settings」→「Display」→「Screen」，將「Graphics Controller」改為 **VBoxVGA**，並取消勾選「Enable 3D Acceleration」。

---

### Q2：安裝過程非常慢，進度條幾乎不動

**原因：** 這是正常現象。NixOS 安裝程序需要從 `cache.nixos.org` 下載大量套件，實際速度取決於你的網路頻寬。

**說明：** 第一次安裝通常需要 5–20 分鐘。等待過程中不要強制關閉虛擬機，耐心等候即可。

---

### Q3：`nixos-rebuild switch` 出現錯誤，看不懂訊息

**解法：** 加上 `--show-trace` 參數，可以看到更詳細的錯誤追蹤資訊：

```bash
sudo nixos-rebuild switch --show-trace
```

常見的錯誤包括：

- 套件名稱拼錯（例如：`htoop` 而不是 `htop`）→ 錯誤訊息會顯示「attribute 'htoop' missing」
- 配置語法錯誤（缺少分號或括號）→ 錯誤訊息會顯示行號和「syntax error」

---

### Q4：修改配置後執行 `sudo` 出現「alice is not in the sudoers file」

**原因：** `users.users.alice.extraGroups` 中漏掉了 `"wheel"` 群組，或修改時不小心刪除了這個設定。

**解法：** 重新開機進入 GRUB/systemd-boot 選單，選擇上一個 generation，以有 `sudo` 權限的狀態進入系統，修復 `configuration.nix`，再執行 `nixos-rebuild switch`。

---

### Q5：重新開機後系統無法啟動

**解法：** 在 systemd-boot 選單中，選擇「NixOS (Generation 1, 25.05...)」回到上一個可用的世代。進入系統後，修正 `configuration.nix` 的問題，再執行 `nixos-rebuild switch`。

這正是 NixOS 世代機制（generation system）的核心價值：每次 rebuild 都會保留上一個可開機的系統，讓你隨時有退路。

---

## 延伸練習

完成基本 Lab 後，嘗試以下練習來加深理解。

**練習 1：擴充系統套件清單**

在 `environment.systemPackages` 中再加入 3–5 個你常用的工具，例如：

```nix
environment.systemPackages = with pkgs; [
  vim
  wget
  htop
  tree
  curl       # 網路請求工具
  ripgrep    # 高效文字搜尋工具（grep 的現代替代品）
  fd         # 高效檔案搜尋工具（find 的現代替代品）
];
```

執行 `nixos-rebuild switch` 後，用 `which ripgrep` 和 `which fd` 驗證安裝成功。

---

**練習 2：修改主機名稱**

將 `networking.hostName` 改為你想要的名稱：

```nix
networking.hostName = "my-nixos-machine";
```

執行 `nixos-rebuild switch` 後，用以下指令驗證：

```bash
hostname
```

確認輸出為 `my-nixos-machine`。

---

**練習 3：觀察拼字錯誤的錯誤訊息**

故意在 `environment.systemPackages` 中加入一個不存在的套件名稱：

```nix
environment.systemPackages = with pkgs; [
  vim
  wget
  htop
  tree
  nonexistentpackage123    # 這個套件不存在
];
```

執行 `nixos-rebuild switch`，觀察錯誤訊息的格式與內容。

確認理解錯誤訊息後，移除這一行，重新執行 `nixos-rebuild switch` 恢復正常。

---

**練習 4：測試 rollback 機制**

執行以下指令回滾到上一個 generation：

```bash
sudo nixos-rebuild switch --rollback
```

用 `nixos-rebuild list-generations` 確認 `(current)` 已切換到前一個世代。

試著執行 `htop`，觀察如果該 generation 的配置不含 `htop`，系統會回應什麼。

---

**練習 5：從開機選單切換 generation**

執行 `sudo reboot` 重新開機。

在 systemd-boot 選單出現時，按下鍵盤方向鍵，瀏覽可選的 generation 清單。

選擇一個非當前的 generation 開機，進入系統後用 `nixos-rebuild list-generations` 確認目前所在的世代。
