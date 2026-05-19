# Lab 4：完整單機工作站配置

**對應章節：** 第 8–12 章

---

## 目標

完成本 Lab 後，你將能夠：

1. 從零建立完整的工作站 NixOS 配置，涵蓋硬體到使用者環境
2. 正確解讀並延伸 `hardware-configuration.nix`（硬體配置檔）的自動生成內容
3. 分別配置開機載入器（boot loader）、網路（networking）、使用者（users）、套件（packages）
4. 將配置組織為多個獨立模組：`hardware.nix`、`boot.nix`、`networking.nix`、`users.nix`、`packages.nix`
5. 驗證每個子系統的運作是否正常
6. 練習使用 rollback（回滾）能力，確認系統具備安全退路

---

## 前置要求

- 已完成 Lab 1（NixOS 安裝，VM 可正常啟動並登入）
- 已完成 Lab 2（基本模組化配置，了解 `imports` 機制）
- 已完成 Lab 3（撰寫過帶有 `options` 的自訂模組）
- 已閱讀第 8–12 章內容（硬體配置、Boot、網路、使用者與權限、套件管理）

---

## 建議環境

| 項目 | 規格 |
|---|---|
| Hypervisor | VirtualBox 7.x / VMware Workstation / QEMU-KVM |
| CPU | 2 核心（最低）/ 4 核心（建議） |
| RAM | 4 GB（最低）/ 8 GB（建議） |
| 磁碟 | 30 GB（最低）/ 50 GB（建議，避免 Nix Store 滿溢） |
| 韌體 | EFI（建議，與實機行為一致） |
| 網路 | NAT 或 Bridged（需要能夠連接網際網路） |
| NixOS 版本 | 25.05 |

---

## 目錄結構預覽

完成本 Lab 後，`/etc/nixos/` 目錄結構將如下所示：

```text
/etc/nixos/
├── configuration.nix        ← 主入口，只做 imports
├── hardware-configuration.nix  ← 安裝器自動生成，不手動修改
├── hardware.nix             ← 額外硬體設定（GPU、音效等）
├── boot.nix                 ← 開機載入器與核心配置
├── networking.nix           ← 網路、防火牆、主機名稱
├── users.nix                ← 使用者帳號與 SSH 金鑰
└── packages.nix             ← 套件、Shell、開發工具
```

這個結構是「關注點分離」（Separation of Concerns）的實踐：每個檔案只負責一個明確的子系統。

---

## Step 1：檢視現有 hardware-configuration.nix

### 目的

了解 NixOS 安裝器替你自動生成的硬體描述，是建立正確配置的第一步。這份檔案是由 `nixos-generate-config` 工具產生，描述了你的磁碟分割、掛載點、核心模組等資訊。

### 操作步驟

首先，用 root 或 sudo 查看目前的硬體配置：

```bash
cat /etc/nixos/hardware-configuration.nix
```

你應該會看到類似下方的內容（根據你的 VM 磁碟配置可能略有不同）：

```nix
# 此檔案由 nixos-generate-config 自動產生，通常不需要手動修改
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # boot.initrd.availableKernelModules 列出開機時需要的核心模組（kernel modules）
  # 這些模組讓系統在進入 root filesystem 前就能識別磁碟控制器
  boot.initrd.availableKernelModules = [
    "ahci"      # SATA 控制器
    "xhci_pci"  # USB 3.0 控制器
    "virtio_pci" # 虛擬機 PCI 匯流排（QEMU/KVM 環境）
    "sr_mod"    # CD/DVD 驅動
    "virtio_blk" # 虛擬機磁碟（QEMU/KVM 環境）
  ];

  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # fileSystems 定義檔案系統掛載點（mount point）
  # 每個掛載點需要指定 device（裝置路徑）和 fsType（檔案系統類型）
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/yyyy-YYYY";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # swapDevices 定義交換空間（swap space）
  swapDevices = [
    { device = "/dev/disk/by-uuid/zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz"; }
  ];

  # 允許跨架構的不自由韌體
  hardware.enableRedistributableFirmware = true;

  # 自動偵測到的 CPU 類型
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
}
```

### 重要欄位說明

| 欄位 | 說明 |
|---|---|
| `boot.initrd.availableKernelModules` | initrd（Initial RAM Disk）階段載入的核心模組 |
| `fileSystems."/"` | 根檔案系統掛載設定，`by-uuid` 確保不受裝置排序影響 |
| `fileSystems."/boot"` | EFI 系統分割（ESP）的掛載點 |
| `swapDevices` | 交換分割區，提供虛擬記憶體 |
| `hardware.enableRedistributableFirmware` | 允許載入廠商提供的可重新發佈韌體（Wi-Fi 晶片等） |

### 建立 hardware.nix

`hardware-configuration.nix` 由工具自動維護，**不應該手動修改**。需要額外的硬體設定（如 GPU、音效、藍牙），請建立一個獨立的 `hardware.nix`：

```bash
sudo nano /etc/nixos/hardware.nix
```

輸入以下內容。這個檔案目前只加入 OpenGL（開放圖形函式庫）支援，以後可以按需要擴充：

```nix
{ config, pkgs, ... }:

{
  # hardware.graphics（舊版為 hardware.opengl）啟用 OpenGL 硬體加速
  # 在虛擬機中，這讓 Guest 能使用 3D 加速（若 Hypervisor 支援）
  hardware.graphics = {
    enable = true;
    # enable32Bit 提供 32 位元 OpenGL 函式庫，多媒體應用常需要
    enable32Bit = true;
  };

  # 啟用音效支援，使用現代的 PipeWire（管線電線）音效伺服器
  # PipeWire 同時相容 ALSA、PulseAudio 和 JACK 應用程式
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # 若你使用 NVIDIA 顯示卡，取消以下註解：
  # hardware.nvidia = {
  #   modesetting.enable = true;
  #   open = false;
  #   nvidiaSettings = true;
  # };
  # services.xserver.videoDrivers = [ "nvidia" ];
}
```

### 預期結果

建立 `hardware.nix` 後，目前還不會套用，因為尚未在 `configuration.nix` 的 `imports` 中引入它。我們將在 Step 6 統一整合。

---

## Step 2：設定開機載入器

### 目的

開機載入器（boot loader）是系統啟動的起點。正確設定讓系統能夠引導，也讓 NixOS 的 generation（世代）選單正常顯示，從而支援 rollback。

### 建立 boot.nix

```bash
sudo nano /etc/nixos/boot.nix
```

輸入以下內容。以下以 **systemd-boot**（適用 EFI 系統）為主要範例，並附上 GRUB 備選方案：

```nix
{ config, pkgs, lib, ... }:

{
  # systemd-boot 是 NixOS 的推薦開機載入器，僅支援 EFI 系統
  # 它簡單可靠，並且能自動列出所有 NixOS generation 供選擇
  boot.loader.systemd-boot.enable = true;

  # efi.canTouchEfiVariables 允許 NixOS 寫入 EFI 變數
  # 在真實硬體上通常設為 true，讓系統能更新 EFI 啟動條目
  boot.loader.efi.canTouchEfiVariables = true;

  # 開機選單最多顯示幾個 generation（世代）
  # 超過此數量的舊 generation 不會出現在選單中（但不會被刪除）
  boot.loader.systemd-boot.configurationLimit = 10;

  # 使用最新穩定的 Linux 核心（kernel）
  # pkgs.linuxPackages_latest 會跟隨 nixpkgs 提供的最新版本
  # 若需要固定版本，可改用例如 pkgs.linuxPackages_6_6
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # kernelParams 是傳遞給核心的啟動參數（boot parameters）
  # quiet 減少啟動時的終端輸出，splash 顯示開機畫面
  boot.kernelParams = [ "quiet" "splash" ];

  # tmpOnTmpfs 將 /tmp 掛載於記憶體中（tmpfs），加快暫存檔操作速度
  # 缺點是重開機後 /tmp 內容消失，以及佔用 RAM
  boot.tmp.useTmpfs = true;
}

# ── 若你的 VM 使用 BIOS（非 EFI），改用以下配置 ──────────────────────────
# {
#   boot.loader.grub = {
#     enable = true;
#     device = "/dev/sda";   # 替換為你的磁碟裝置路徑
#     useOSProber = false;   # 單一 OS 不需要偵測其他系統
#   };
#   boot.kernelPackages = pkgs.linuxPackages_latest;
# }
```

### 預先驗證（dry-run）

在實際套用前，用 `dry-run` 模式確認配置是否有語法錯誤。此步驟不會真正修改系統，只會評估（evaluate）Nix 表達式並回報問題：

```bash
# 注意：此時 boot.nix 尚未加入 configuration.nix，
# 所以 dry-run 要直接引用 boot.nix 檔案確認語法正確
nix-instantiate --eval --strict /etc/nixos/boot.nix 2>&1 | head -5
```

若沒有錯誤訊息，代表語法正確。語法錯誤時會看到類似以下的輸出：

```text
error: syntax error, unexpected '}', at /etc/nixos/boot.nix:12:1
```

### 預期結果

`boot.nix` 建立完成，語法無誤。目前尚未套用，將在 Step 6 一起整合。

---

## Step 3：配置網路模組

### 目的

網路配置涵蓋主機名稱（hostname）、連線管理、DNS、防火牆規則。正確的網路設定是後續遠端管理（SSH）和套件下載的基礎。

### 建立 networking.nix

```bash
sudo nano /etc/nixos/networking.nix
```

輸入以下內容：

```nix
{ config, pkgs, ... }:

{
  # 設定主機名稱（hostname）
  # 這個名稱會出現在 shell 提示符（如 alice@nixos）和網路廣播中
  networking.hostName = "nixos";

  # NetworkManager 是桌面系統常用的網路管理工具
  # 它會自動處理 DHCP、Wi-Fi 連線和 VPN
  # 加入 networkmanager 群組的使用者可以管理網路連線
  networking.networkmanager.enable = true;

  # 啟用 NixOS 內建防火牆（基於 nftables / iptables）
  # enable = true 時，預設只允許主機發出的連線回應，封鎖所有入站流量
  networking.firewall = {
    enable = true;

    # allowedTCPPorts 列出允許外部連入的 TCP 連接埠（port）
    # 22 是 SSH（Secure Shell）遠端登入的標準連接埠
    allowedTCPPorts = [ 22 ];

    # allowedUDPPorts 列出允許外部連入的 UDP 連接埠
    # 目前保持空陣列，只開放 TCP 22
    allowedUDPPorts = [ ];
  };

  # 設定時區（time zone）為台北時間（UTC+8）
  time.timeZone = "Asia/Taipei";

  # 本地化設定（locale）
  # C.UTF-8 是最通用的選擇，避免中文 locale 在終端機的顯示問題
  i18n.defaultLocale = "zh_TW.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_TW.UTF-8";
    LC_MONETARY = "zh_TW.UTF-8";
    LC_PAPER = "zh_TW.UTF-8";
    LC_TELEPHONE = "zh_TW.UTF-8";
    LC_TIME = "zh_TW.UTF-8";
  };

  # 啟用 OpenSSH（安全殼層）服務
  # 這讓你能從其他電腦遠端登入這台 NixOS 主機
  services.openssh = {
    enable = true;
    settings = {
      # 禁止 root 直接透過 SSH 登入，提高安全性
      PermitRootLogin = "no";
      # 只允許金鑰登入，禁止密碼登入（設定金鑰後開啟）
      # PasswordAuthentication = false;
    };
  };
}
```

### 驗證網路

如果你想在套用前確認現有網路設定，執行以下指令：

```bash
# 確認目前能連接網際網路
ping -c 3 8.8.8.8

# 確認 DNS 解析正常
ping -c 3 nixos.org

# 查詢本機的對外 IP 位址
curl -s ifconfig.me
```

**預期輸出（ping）：**

```text
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=114 time=12.3 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=114 time=11.8 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=114 time=12.1 ms
```

### 預期結果

`networking.nix` 建立完成，包含防火牆設定和 SSH 服務宣告。

---

## Step 4：完善使用者配置

### 目的

正確的使用者配置包括群組歸屬、sudo 權限、SSH 授權金鑰（authorized keys）和安全的密碼雜湊（hashed password）。這些設定控制「誰可以做什麼」。

### 4-1：產生密碼雜湊

在 NixOS 中，使用者密碼以雜湊（hash）形式儲存在配置中，而不是明文。使用 `mkpasswd` 工具產生：

```bash
# 安裝 mkpasswd 工具（若尚未安裝）
nix-shell -p mkpasswd

# 產生 alice 的密碼雜湊（輸入密碼後會輸出雜湊值）
mkpasswd -m yescrypt
```

輸入你的密碼，會得到類似以下格式的雜湊值：

```text
$y$j9T$xxxxxxxxxxxxxxxxxxxxxxxxxxxx$yyyyyyyyyyyyyyyyyyyyyyyyyyyy
```

**複製這個雜湊值**，接下來會用到。

### 4-2：產生 SSH 測試金鑰

建立一對 SSH 金鑰（key pair）用於測試免密登入：

```bash
# 在家目錄建立 SSH 金鑰
# -t ed25519 使用現代的 Ed25519 演算法（比 RSA 更短且安全）
# -C 是金鑰的備註說明
# -f 指定金鑰檔案路徑
ssh-keygen -t ed25519 -C "alice@nixos-lab04" -f ~/.ssh/id_ed25519_lab04 -N ""

# 查看公鑰（public key）內容，這是要放入配置的部分
cat ~/.ssh/id_ed25519_lab04.pub
```

**預期輸出（公鑰格式）：**

```text
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx alice@nixos-lab04
```

複製完整的公鑰字串（從 `ssh-ed25519` 到最後的備註）。

### 4-3：建立 users.nix

```bash
sudo nano /etc/nixos/users.nix
```

輸入以下內容，**將兩個佔位符替換為你實際產生的值**：

```nix
{ config, pkgs, ... }:

{
  # users.users 是一個 attribute set，每個鍵是使用者名稱
  users.users.alice = {
    # isNormalUser = true 表示這是一般登入帳號
    # 會自動建立家目錄（/home/alice）並設定 login shell
    isNormalUser = true;

    # description 是帳號的顯示名稱，出現在登入畫面
    description = "Alice";

    # extraGroups 定義使用者額外歸屬的群組（group）
    # wheel：允許使用 sudo 提升至 root 權限
    # networkmanager：允許管理網路連線
    # audio：允許存取音效裝置
    # video：允許存取影像裝置（網路攝影機等）
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
    ];

    # hashedPassword 是用 mkpasswd 產生的密碼雜湊
    # 請替換為你在 4-1 步驟產生的雜湊值
    hashedPassword = "$y$j9T$請替換為你的雜湊值$...";

    # openssh.authorizedKeys.keys 是 SSH 授權公鑰列表
    # 持有對應私鑰的使用者可以免密登入
    openssh.authorizedKeys.keys = [
      # 請替換為你在 4-2 步驟產生的公鑰內容
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxxxxxxxxxxxxxxxx alice@nixos-lab04"
    ];

    # 設定預設 shell（在 Step 5 啟用 zsh 後生效）
    shell = pkgs.zsh;
  };

  # 允許 wheel 群組的成員使用 sudo 而不需要輸入密碼
  # 這在 Lab 環境方便操作，正式環境建議移除此設定
  security.sudo.wheelNeedsPassword = false;
}
```

### 驗證使用者設定

在套用配置後（Step 7），可用以下指令驗證使用者設定：

```bash
# 確認 alice 的 UID、GID 和群組
id alice

# 預期輸出格式：
# uid=1000(alice) gid=1000(alice) groups=1000(alice),4(adm),27(sudo),...

# 確認 alice 的群組列表
groups alice

# 預期輸出：
# alice : alice wheel networkmanager audio video

# 確認 sudo 權限（-l 列出 alice 被允許的指令）
sudo -u alice sudo -l
```

### 預期結果

`users.nix` 建立完成，包含正確的群組設定、密碼雜湊和 SSH 公鑰。

---

## Step 5：套件環境客製化

### 目的

`packages.nix` 定義系統層級安裝的套件、Shell 環境和開發工具。這裡安裝的套件對所有使用者都可用。

### 建立 packages.nix

```bash
sudo nano /etc/nixos/packages.nix
```

輸入以下內容：

```nix
{ config, pkgs, ... }:

{
  # nixpkgs.config 控制 nixpkgs 的全域行為
  nixpkgs.config = {
    # allowUnfree = true 允許安裝非自由（proprietary）授權的套件
    # 例如：vscode、nvidia 驅動、某些字型
    # 預設為 false，因為 NixOS 遵循自由軟體原則
    allowUnfree = true;
  };

  # environment.systemPackages 列出系統層級安裝的套件
  # 這些套件對所有使用者都可在 PATH 中找到
  environment.systemPackages = with pkgs; [
    # ── 基本工具 ───────────────────────────────
    git          # 版本控制系統
    vim          # 文字編輯器
    neovim       # 現代化文字編輯器
    htop         # 互動式行程監視器（process monitor）
    btop         # 更現代的資源監視器
    curl         # 傳送 URL 請求的命令列工具
    wget         # 檔案下載工具
    tree         # 以樹狀結構顯示目錄
    unzip        # 解壓縮 ZIP 檔案
    ripgrep      # 快速文字搜尋工具（grep 的現代替代）
    fd           # 快速檔案搜尋工具（find 的現代替代）
    jq           # 命令列 JSON 處理工具

    # ── 開發工具 ───────────────────────────────
    gnumake      # Make 建置工具
    gcc          # GNU C 編譯器
    python3      # Python 3 直譯器

    # ── 系統工具 ───────────────────────────────
    pciutils     # 提供 lspci 等 PCI 裝置查詢工具
    usbutils     # 提供 lsusb 等 USB 裝置查詢工具
    lsof         # 查看開啟的檔案和網路連線

    # ── 網路工具 ───────────────────────────────
    nmap         # 網路掃描工具
    tcpdump      # 封包擷取工具
    inetutils    # 提供 telnet、ping 等基本網路工具

    # ── Unfree 套件（需要 allowUnfree = true）──
    vscode       # Visual Studio Code 程式碼編輯器
  ];

  # programs.zsh 啟用 Zsh（Z Shell）並進行系統層級配置
  # 僅啟用 enable 還不足，需要使用者的 shell 設定為 zsh（已在 users.nix 完成）
  programs.zsh = {
    enable = true;

    # 啟用 autosuggestions（自動建議），根據歷史紀錄提示完整指令
    autosuggestions.enable = true;

    # 啟用 syntaxHighlighting（語法高亮），在輸入時就區分合法/錯誤指令
    syntaxHighlighting.enable = true;

    # 為所有使用者的 .zshrc 加入初始化內容
    interactiveShellInit = ''
      # 設定 Starship prompt（在下方啟用）
      eval "$(starship init zsh)"
    '';
  };

  # 安裝 Starship，一個跨 Shell 的現代化提示符（prompt）工具
  # 它以彩色圖示顯示 git 狀態、語言版本、執行時間等資訊
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[✗](bold red)";
      };
    };
  };

  # direnv 是一個目錄環境管理工具
  # 進入某個目錄時，它能自動載入 .envrc 中定義的環境變數和工具
  # nix-direnv 是 direnv 針對 Nix 的整合，讓 nix develop shell 能被快取
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # 安裝 Nerd Fonts，這些字型包含額外的圖示符號
  # 許多終端機主題（如 Starship、Oh-My-Zsh 主題）需要 Nerd Fonts 才能正確顯示
  fonts.packages = with pkgs.nerd-fonts; [
    fira-code    # FiraCode Nerd Font，含連字符號
    jetbrains-mono  # JetBrains Mono Nerd Font
  ];
}
```

### 預期結果

`packages.nix` 建立完成，包含基本工具、開發套件、VSCode、Zsh 和 Starship 的配置。

---

## Step 6：整合所有模組

### 目的

現在將所有模組整合到 `configuration.nix` 中。這個檔案將成為純粹的「進入點」，只負責引入其他模組，不直接包含配置細節。

### 重寫 configuration.nix

先備份現有的配置：

```bash
sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.bak
```

然後重新撰寫：

```bash
sudo nano /etc/nixos/configuration.nix
```

輸入以下內容：

```nix
# /etc/nixos/configuration.nix
# 這是 NixOS 系統配置的主入口（entry point）
# 本檔案的職責只有一個：引入（import）所有子模組
# 實際的配置細節分散在各個子模組中

{ config, pkgs, ... }:

{
  imports = [
    # 安裝器自動生成的硬體描述，包含磁碟和核心模組
    ./hardware-configuration.nix

    # 額外硬體設定：GPU、音效、藍牙（Step 1 建立）
    ./hardware.nix

    # 開機載入器與核心配置（Step 2 建立）
    ./boot.nix

    # 網路、防火牆、SSH、時區（Step 3 建立）
    ./networking.nix

    # 使用者帳號、群組、SSH 金鑰（Step 4 建立）
    ./users.nix

    # 套件、Shell、字型、開發工具（Step 5 建立）
    ./packages.nix
  ];

  # system.stateVersion 記錄這個系統最初安裝時的 NixOS 版本
  # 重要：此值在系統初始化後不應該修改
  # 它不是「目前使用的 NixOS 版本」，而是「有狀態資料的相容性版本基準」
  # 錯誤修改可能導致資料格式不相容的問題
  system.stateVersion = "25.05";
}
```

### 確認所有檔案存在

在套用前，確認所有被引入的檔案都存在：

```bash
ls -la /etc/nixos/
```

**預期輸出：**

```text
total 48
drwxr-xr-x  2 root root 4096 May 18 10:30 .
drwxr-xr-x 17 root root 4096 May 18 10:00 ..
-rw-r--r--  1 root root  xxx May 18 10:30 boot.nix
-rw-r--r--  1 root root  xxx May 18 10:30 configuration.nix
-rw-r--r--  1 root root  xxx May 18 10:25 configuration.nix.bak
-rw-r--r--  1 root root  xxx May 18 09:00 hardware-configuration.nix
-rw-r--r--  1 root root  xxx May 18 10:30 hardware.nix
-rw-r--r--  1 root root  xxx May 18 10:30 networking.nix
-rw-r--r--  1 root root  xxx May 18 10:30 packages.nix
-rw-r--r--  1 root root  xxx May 18 10:30 users.nix
```

### 預演變更（dry-run）

在正式套用前，使用 `dry-run` 模式確認整體配置沒有錯誤：

```bash
sudo nixos-rebuild dry-run 2>&1 | head -30
```

若配置正確，你會看到類似以下的輸出（列出將要建立的 derivation）：

```text
building the system configuration...
these 23 derivations will be built:
  /nix/store/xxx-nixos-system-nixos-25.05.drv
  /nix/store/xxx-zsh-5.9.drv
  /nix/store/xxx-starship-1.21.0.drv
  ...
```

若有錯誤，會顯示錯誤訊息和行號，例如：

```text
error: The option `networking.networkmanager.enable' is used but not defined.
```

遇到錯誤時，根據錯誤訊息找到對應的模組檔案修正。

### 預期結果

`configuration.nix` 改寫為模組匯入點，`dry-run` 無誤，準備套用。

---

## Step 7：套用並全面驗證

### 套用配置

確認 `dry-run` 無誤後，執行正式套用：

```bash
# nixos-rebuild switch 會：
# 1. 評估（evaluate）整個 Nix 配置
# 2. 建構（build）所有需要的 derivation
# 3. 啟動（activate）新的系統世代
# 4. 切換到新的 generation（不需要重開機）
sudo nixos-rebuild switch
```

這個過程需要幾分鐘，因為要下載和編譯新套件。你會看到進度輸出：

```text
building the system configuration...
downloading 'https://cache.nixos.org/...'
...
activating the configuration...
setting up /etc...
reloading user units for alice...
the following new units were started: pipewire.service, ...
```

### 全面驗證清單

套用完成後，逐一驗證每個子系統是否正常運作：

```bash
# 1. 確認整體系統狀態
systemctl is-system-running
# 預期：active 或 degraded（若有非關鍵服務未啟動）

# 2. 確認網路介面
ip addr show
# 預期：看到 lo（回環介面）和 ens3/eth0（網路介面）及其 IP 位址

# 3. 確認網路連線
ping -c 2 1.1.1.1
# 預期：收到回應封包，無 100% 丟包

# 4. 確認防火牆規則
sudo nft list ruleset | head -30
# 預期：看到 NixOS 自動生成的防火牆規則，包含允許 TCP 22 的規則

# 5. 確認使用者和群組
id alice
# 預期：uid=1000(alice) gid=1000(alice) groups=1000(alice),54(lock),995(audio),...,wheel,networkmanager,video

groups alice
# 預期：alice wheel networkmanager audio video

# 6. 確認 sudo 權限
sudo -u alice sudo -l
# 預期：列出允許 alice 執行的指令，包含 (ALL : ALL) ALL 或 NOPASSWD

# 7. 確認套件安裝
which git && git --version
# 預期：/run/current-system/sw/bin/git 和 git version 2.x.x

which code
# 預期：/run/current-system/sw/bin/code

# 8. 確認 Zsh 安裝
zsh --version
# 預期：zsh 5.x.x (x86_64-pc-linux-gnu)

# 9. 確認 Nix 版本
nix --version
# 預期：nix (Nix) 2.x.x

# 10. 測試 SSH 金鑰登入（在同一台機器測試）
ssh -i ~/.ssh/id_ed25519_lab04 alice@localhost "echo 'SSH 登入成功'"
# 預期：SSH 登入成功
```

### 驗證摘要表

| 項目 | 驗證指令 | 預期結果 |
|---|---|---|
| 系統狀態 | `systemctl is-system-running` | `active` |
| 網路介面 | `ip addr show` | 顯示 IP 位址 |
| 網際網路連線 | `ping -c 2 1.1.1.1` | 封包正常回應 |
| 防火牆 | `sudo nft list ruleset` | 看到 TCP 22 允許規則 |
| 使用者群組 | `id alice` | 包含 wheel, networkmanager |
| Sudo 權限 | `sudo -u alice sudo whoami` | 輸出 `root` |
| Git | `git --version` | 顯示版本號 |
| VSCode | `which code` | 顯示路徑 |
| Zsh | `zsh --version` | 顯示版本號 |
| SSH 金鑰登入 | `ssh -i ~/.ssh/id_ed25519_lab04 alice@localhost` | 登入成功 |

### 預期結果

所有驗證項目通過，系統完整運作。

---

## Step 8：測試回滾能力

### 目的

NixOS 最重要的安全網就是 rollback（回滾）能力。在學習環境中主動測試這個機制，能讓你對未來實際操作更有信心。

### 8-1：查看目前的世代列表

每次 `nixos-rebuild switch` 都會建立一個新的 generation（世代）。查看目前所有世代：

```bash
sudo nix-env --list-generations -p /nix/var/nix/profiles/system
```

**預期輸出：**

```text
   1   2026-05-10 09:00:00
   2   2026-05-15 14:30:00
   3   2026-05-18 10:45:00   (current)
```

目前活躍的世代標示為 `(current)`。

### 8-2：使用 nixos-rebuild test 試驗變更

`nixos-rebuild test` 不同於 `switch`：它會套用新配置並啟動，但**不更新開機載入器**。重開機後，系統會自動回到上一個 `switch` 建立的世代。這是安全試驗配置的好方法：

```bash
# 暫時修改 networking.nix，故意引入一個無害但可觀察的變更
# 例如：把主機名稱改為 nixos-test
sudo sed -i 's/hostName = "nixos"/hostName = "nixos-test"/' /etc/nixos/networking.nix

# 用 test 模式套用
sudo nixos-rebuild test

# 確認主機名稱已改變
hostname
# 預期：nixos-test

# 還原剛才的修改
sudo sed -i 's/hostName = "nixos-test"/hostName = "nixos"/' /etc/nixos/networking.nix
```

### 8-3：模擬錯誤配置並回滾

現在故意製造一個 Nix 語法錯誤，觀察 `nixos-rebuild` 的保護機制：

```bash
# 在 packages.nix 加入一個不存在的套件名稱
echo '  environment.systemPackages = with pkgs; [ this-package-does-not-exist-xyz ];' | sudo tee -a /etc/nixos/packages.nix

# 嘗試套用（這會失敗）
sudo nixos-rebuild switch
```

**預期輸出（失敗訊息）：**

```text
error: attribute 'this-package-does-not-exist-xyz' missing

       at /nix/store/.../pkgs/top-level/all-packages.nix:...
```

因為配置評估失敗，**系統沒有改變**，仍然正常運作。

還原錯誤：

```bash
# 移除剛才加入的錯誤行
sudo nano /etc/nixos/packages.nix
# 刪除最後一行 environment.systemPackages... 那行

# 確認恢復正常
sudo nixos-rebuild dry-run
```

### 8-4：從世代回滾

如果已經套用了一個有問題的配置（`switch` 成功但系統行為異常），可以用以下方式回滾：

```bash
# 方法一：切換到上一個世代
sudo nixos-rebuild switch --rollback

# 方法二：切換到指定世代編號（例如世代 2）
sudo nix-env --switch-generation 2 -p /nix/var/nix/profiles/system
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch

# 方法三：重開機後從開機載入器選單選擇舊世代
# 在 systemd-boot 選單中，按方向鍵選擇舊世代，Enter 確認
```

### 確認世代切換成功

```bash
# 確認目前活躍的世代
sudo nix-env --list-generations -p /nix/var/nix/profiles/system

# 確認系統連結指向正確的世代
readlink /nix/var/nix/profiles/system
```

### 預期結果

能夠成功查看世代列表、用 `test` 模式安全試驗配置、理解錯誤配置的保護機制，並能手動回滾到指定世代。

---

## 驗證清單

完成本 Lab 後，請逐項確認以下項目：

| 項次 | 驗證項目 | 驗證指令 | 完成 |
|---|---|---|---|
| 1 | `hardware.nix` 建立且語法正確 | `nix-instantiate --parse /etc/nixos/hardware.nix` | ☐ |
| 2 | `boot.nix` 建立，systemd-boot 已啟用 | `bootctl status` | ☐ |
| 3 | `networking.nix` 建立，主機名稱正確 | `hostname` 輸出 `nixos` | ☐ |
| 4 | `users.nix` 建立，alice 在 wheel 群組 | `groups alice \| grep wheel` | ☐ |
| 5 | `packages.nix` 建立，git 可用 | `git --version` | ☐ |
| 6 | `configuration.nix` 只含 imports | `grep -v '^#' /etc/nixos/configuration.nix \| grep -v '^$'` | ☐ |
| 7 | `nixos-rebuild switch` 成功完成 | `echo $?` 輸出 `0` | ☐ |
| 8 | SSH 金鑰登入成功 | `ssh -i ~/.ssh/id_ed25519_lab04 alice@localhost whoami` | ☐ |
| 9 | VSCode 可啟動 | `code --version` | ☐ |
| 10 | 能正確列出世代並回滾 | `sudo nix-env --list-generations -p /nix/var/nix/profiles/system` | ☐ |

---

## 常見問題

### Q1：`nixos-rebuild switch` 卡在某個服務上怎麼辦？

**症狀：**

```text
activating the configuration...
systemd: Starting pipewire.service...
（停住不動超過 60 秒）
```

**診斷步驟：**

1. 開啟另一個終端機，查看服務狀態：

   ```bash
   # 查看是哪個服務卡住
   systemctl list-jobs
   
   # 查看特定服務的詳細狀態和日誌
   systemctl status pipewire.service
   journalctl -u pipewire.service -n 50
   ```

2. 若服務持續失敗，先強制停止：

   ```bash
   sudo systemctl stop pipewire.service
   ```

3. 找出問題原因後，修正配置並重新執行 `nixos-rebuild switch`。

4. 若無法修正，回滾到上一個可工作的世代：

   ```bash
   sudo nixos-rebuild switch --rollback
   ```

**常見原因：** 音效系統衝突（同時啟用 PulseAudio 和 PipeWire）、服務依賴順序問題、設備不存在（如指定了不存在的音效裝置）。

---

### Q2：安裝完 unfree 套件但執行時提示 "unfree not allowed"？

**症狀：**

```text
error: Package 'vscode-1.x.x' in /nix/store/...
       has an unfree license ('unfree') which is not allowed.
```

**診斷步驟：**

1. 確認 `packages.nix` 中有設定 `allowUnfree`：

   ```bash
   grep -n "allowUnfree" /etc/nixos/packages.nix
   ```

   應該看到：

   ```text
   5:    allowUnfree = true;
   ```

2. 若 `allowUnfree` 有設定但仍然失敗，確認它的位置正確（在 `nixpkgs.config` 區塊內）：

   ```nix
   nixpkgs.config = {
     allowUnfree = true;  # ← 必須在這個 attribute set 內
   };
   ```

3. 確認 `packages.nix` 已被 `configuration.nix` 的 `imports` 引入：

   ```bash
   grep "packages.nix" /etc/nixos/configuration.nix
   ```

4. 重新套用配置：

   ```bash
   sudo nixos-rebuild switch
   ```

---

### Q3：加入 wheel 群組後 sudo 仍要求密碼？

**症狀：**

執行 `sudo` 時出現 `[sudo] password for alice:` 提示，但設定了 `wheelNeedsPassword = false`。

**診斷步驟：**

1. 確認 `users.nix` 中的設定語法正確：

   ```bash
   grep -n "wheelNeedsPassword" /etc/nixos/users.nix
   ```

   應該看到：

   ```text
   security.sudo.wheelNeedsPassword = false;
   ```

2. 確認 alice 確實在 wheel 群組（需要重新登入後才會生效）：

   ```bash
   id alice | grep wheel
   ```

3. **重新登入** alice 帳號（群組變更需要重新登入才會對目前 session 生效）：

   ```bash
   # 登出再重新登入，或切換使用者
   exit
   # 重新以 alice 登入後測試
   sudo whoami
   ```

4. 若仍有問題，查看 sudo 的設定檔是否正確生成：

   ```bash
   sudo cat /etc/sudoers | grep wheel
   # 預期看到：%wheel ALL=(ALL:ALL) NOPASSWD: ALL
   ```

---

### Q4：SSH 金鑰配置後仍無法免密登入？

**症狀：**

```bash
ssh -i ~/.ssh/id_ed25519_lab04 alice@localhost
# 仍然提示輸入密碼
```

**診斷步驟：**

1. 確認公鑰格式正確（必須是完整的一行）：

   ```bash
   grep "openssh.authorizedKeys" /etc/nixos/users.nix -A 3
   ```

   公鑰必須是完整格式：`ssh-ed25519 AAAA... alice@nixos-lab04`，中間不能有換行。

2. 確認 SSH 服務正在運行：

   ```bash
   systemctl status sshd
   # 預期：active (running)
   ```

3. 確認 alice 家目錄下的 authorized_keys 已由 NixOS 生成：

   ```bash
   sudo cat /home/alice/.ssh/authorized_keys
   # 應看到你的公鑰內容
   ```

4. 確認私鑰檔案權限正確（SSH 要求私鑰權限為 600）：

   ```bash
   ls -la ~/.ssh/id_ed25519_lab04
   # 預期：-rw------- 1 alice alice ... id_ed25519_lab04
   
   # 若權限不對，修正：
   chmod 600 ~/.ssh/id_ed25519_lab04
   ```

5. 開啟 SSH 的 verbose 輸出協助診斷：

   ```bash
   ssh -vvv -i ~/.ssh/id_ed25519_lab04 alice@localhost 2>&1 | grep -E "(Offering|Authentications)"
   ```

---

### Q5：`programs.zsh.enable` 設了，但 `zsh` 指令找不到？

**症狀：**

```bash
zsh
# zsh: command not found
```

**診斷步驟：**

1. 確認 `programs.zsh.enable = true` 有正確設定且已套用：

   ```bash
   grep -rn "programs.zsh" /etc/nixos/
   # 預期：packages.nix:X:  programs.zsh = {
   ```

2. `programs.zsh.enable = true` 會安裝 zsh，但不會自動加入 PATH。確認 `zsh` 的實際位置：

   ```bash
   which zsh || ls /run/current-system/sw/bin/zsh
   # 預期：/run/current-system/sw/bin/zsh
   ```

   若存在但 `which zsh` 找不到，代表 PATH 有問題：

   ```bash
   echo $PATH | tr ':' '\n' | grep -c "current-system"
   # 若輸出 0，表示 NixOS 系統路徑不在 PATH 中，需要重新登入
   ```

3. 最常見的原因是**尚未重新登入**。套用配置後，開啟一個全新的終端機 session（或重新登入），再測試：

   ```bash
   # 重新登入後
   zsh --version
   # 預期：zsh 5.x.x (x86_64-pc-linux-gnu)
   ```

4. 若 alice 的預設 shell 設為 zsh（在 `users.nix` 中 `shell = pkgs.zsh`），確認 `/etc/shells` 包含 zsh：

   ```bash
   grep zsh /etc/shells
   # 預期看到 /run/current-system/sw/bin/zsh
   ```

---

## 延伸練習

### 練習一：新增第二個使用者 bob

在 `users.nix` 中加入第二個使用者 `bob`，需求如下：

- 只加入 `audio` 和 `video` 群組
- **不**加入 `wheel` 群組（無 sudo 權限）
- 設定 `shell = pkgs.bash`（使用 Bash 而非 Zsh）
- 使用 `mkpasswd` 為 bob 設定獨立的密碼

完成後驗證：

```bash
id bob
# 預期：不含 wheel 群組

sudo -u bob sudo whoami
# 預期：bob is not allowed to run sudo on nixos.
```

思考：在 NixOS 的宣告式配置中，如果你想「刪除」bob 這個使用者，應該怎麼做？與傳統 Linux（`userdel`）的方式有何不同？

---

### 練習二：新增 WireGuard 模組

建立 `wireguard.nix` 模組，設定 WireGuard（一種現代 VPN 協定）客戶端：

1. 產生測試用的 WireGuard 金鑰對：

   ```bash
   # 安裝 wireguard-tools
   nix-shell -p wireguard-tools
   
   # 產生私鑰和公鑰
   wg genkey | tee /tmp/wg-private.key | wg pubkey > /tmp/wg-public.key
   cat /tmp/wg-public.key
   ```

2. 建立 `wireguard.nix` 並設定一個虛構的（不實際連線的）介面：

   ```nix
   { config, pkgs, ... }:
   
   {
     networking.wireguard.interfaces.wg0 = {
       ips = [ "10.100.0.1/24" ];
       privateKeyFile = "/etc/wireguard/private.key";
       peers = [];  # 暫時不設定對等節點
     };
   }
   ```

3. 將 `wireguard.nix` 加入 `configuration.nix` 的 `imports`，套用並驗證：

   ```bash
   ip link show wg0
   # 預期：看到 wg0 介面
   ```

---

### 練習三：為 alice 配置自訂字型

擴充 `packages.nix` 的字型設定，加入更多 Nerd Fonts 並在終端機中驗證：

1. 在 `packages.nix` 的 `fonts.packages` 中加入更多字型（例如 `nerd-fonts.hack`）
2. 套用配置後，確認字型已安裝：

   ```bash
   fc-list | grep -i "Hack Nerd"
   # 預期：列出 Hack Nerd Font 的字型檔案路徑
   ```

3. 在支援 Nerd Fonts 的終端機模擬器中，設定字型為 `Hack Nerd Font Mono`，確認 Starship prompt 的圖示能正確顯示。

思考：`fonts.packages` 設定的字型安裝在哪個路徑？（提示：`fc-list | head -5`）這與傳統 Linux 手動複製字型到 `~/.fonts/` 的方式有什麼本質差異？

---

### 練習四：建立 security.nix 模組

建立一個 `security.nix` 安全模組，強化系統安全設定：

```bash
sudo nano /etc/nixos/security.nix
```

目標設定內容：

```nix
{ config, pkgs, ... }:

{
  # fail2ban 是一個入侵防護系統（Intrusion Prevention System）
  # 它監控日誌檔案，自動封鎖多次失敗登入的 IP 位址
  services.fail2ban = {
    enable = true;
    maxretry = 3;       # 3 次失敗後封鎖
    bantime = "1h";     # 封鎖持續 1 小時
    jails = {
      sshd.settings = {
        enabled = true;
        port = "2222";  # 與下方修改的 SSH 連接埠一致
      };
    };
  };

  # 將 SSH 預設連接埠從 22 改為 2222
  # 可以減少自動化掃描器的騷擾（安全透過遮蔽）
  services.openssh.ports = [ 2222 ];

  # 同時更新防火牆規則：開放新連接埠，關閉舊連接埠
  networking.firewall.allowedTCPPorts = [ 2222 ];
}
```

完成後驗證（注意：SSH 連接埠已改變）：

```bash
# 確認 fail2ban 運行中
systemctl status fail2ban

# 測試新的 SSH 連接埠
ssh -p 2222 -i ~/.ssh/id_ed25519_lab04 alice@localhost "echo '安全連接成功'"

# 查看 fail2ban 的封鎖列表
sudo fail2ban-client status sshd
```

---

## 小結

完成本 Lab，你已經建立了一個完整的工作站 NixOS 配置，具備以下能力：

- **硬體感知**：正確解讀 `hardware-configuration.nix`，並以獨立的 `hardware.nix` 管理額外硬體設定
- **安全開機**：以 systemd-boot 配置 EFI 開機，並固定使用最新核心
- **網路管理**：透過 NetworkManager 管理連線，以防火牆控制入站流量
- **使用者安全**：以雜湊密碼、群組隔離和 SSH 金鑰取代明文密碼
- **套件一致性**：宣告式管理系統套件，包含開發工具和非自由授權軟體
- **模組化架構**：6 個各司其職的模組，易於維護和擴充
- **回滾信心**：掌握 generation 管理和回滾流程，面對問題不慌亂

### 本 Lab 完成的配置架構圖

```text
/etc/nixos/
│
├── configuration.nix      ─────────────┐
│   （主入口，只做 imports）            │
│                                       │
├── hardware-configuration.nix  ←─── 安裝器生成，不手動修改
│
├── hardware.nix           ← GPU / 音效 / 藍牙
├── boot.nix               ← systemd-boot / 核心版本
├── networking.nix         ← NetworkManager / 防火牆 / SSH
├── users.nix              ← alice / 群組 / SSH 金鑰
└── packages.nix           ← 工具 / VSCode / Zsh / 字型
```

每個模組都是獨立的 Nix 表達式，共同通過 `imports` 合併成一個系統描述。這就是宣告式配置的威力：你的系統永遠等於你的配置檔案。

---

### 下一步：Lab 5 預告

**Lab 5：Home Manager 整合**（對應第 19 章）

到目前為止，我們配置的都是系統層（system-level）的設定，對所有使用者生效。但使用者的個人偏好——git 設定、編輯器主題、Shell 別名、dotfiles——應該在使用者層（user-level）管理。

**Lab 5 將學習：**

- 安裝並初始化 Home Manager
- 將 alice 的 `~/.gitconfig`、`~/.zshrc` 納入宣告式管理
- 用 Home Manager 管理 VSCode 擴充套件和設定
- 整合 Home Manager 作為 NixOS 模組（而非獨立工具）
- 了解「系統套件」與「使用者套件」的邊界在哪裡

學完 Lab 5，你的 NixOS 配置將覆蓋從系統核心到使用者桌面偏好的完整堆疊，真正實現「整台電腦的狀態完全由 Git 控制」的目標。
