# Lab 7：除錯工作坊

**對應章節：** 第 26–28 章（除錯工具鏈、服務診斷、系統維護）

**預估時間：** 90–120 分鐘

**難度：** ★★★★☆（中高級）

---

## 目標

完成本 Lab 後，你將能夠：

1. 讀懂並逐行解析 Nix 的 evaluation error（評估錯誤）和 stack trace（呼叫堆疊）
2. 使用 `nix repl` 和 `nixos-option` 互動式查詢系統配置值，確認 option 的實際來源
3. 識別並修復三類最常見的配置錯誤：evaluation error（attribute 拼字錯誤、不存在的 option）、option conflict（選項衝突）、service failure（服務啟動失敗）
4. 使用 `journalctl` 和 `systemctl` 診斷 systemd 服務啟動失敗問題
5. 建立一套系統性的除錯工作流程：「重現 → 讀懂錯誤 → 找出根因 → 修復 → 驗證」

---

## 前置要求

完成本 Lab 前，請確認你已具備下列知識與環境：

| 項目 | 說明 |
|---|---|
| 完成 Lab 1–6 | 或具備 NixOS 基本操作與 Flakes 使用能力 |
| 理解 NixOS Module System | 對應第 7 章（options、config、imports） |
| 理解 `imports` 機制 | 對應第 5 章 |
| 了解 systemd 基本概念 | 知道什麼是 unit file、target、service |
| 了解 Flakes 基本操作 | 能夠執行 `nixos-rebuild switch --flake .#nixos` |

---

## 建議環境

| 項目 | 建議規格 |
|---|---|
| 作業系統 | NixOS 25.05（安裝在實體機或 VM） |
| CPU | 2 核心以上 |
| 記憶體 | 4 GB 以上 |
| 磁碟空間 | 20 GB 以上空閒空間 |
| 網路連線 | 必須，用於確認套件與下載 |
| 使用者 | 以 `alice` 帳號操作，具備 `sudo` 權限 |
| 主機名稱 | `nixos`（`networking.hostName = "nixos"`） |

> **注意：** 本 Lab 的所有任務都設計在單一 NixOS 機器上執行。任務三的服務範例可以直接複製到你的配置中測試，不需要額外的基礎設施。

---

## 除錯工具速查

在開始之前，先瀏覽本 Lab 會用到的工具：

| 工具 | 用途 | 基本用法 |
|---|---|---|
| `nixos-rebuild dry-run` | 評估配置但不套用，快速發現語法錯誤 | `sudo nixos-rebuild dry-run 2>&1` |
| `nixos-option` | 查詢特定 NixOS option 的值與來源檔案 | `nixos-option services.openssh.enable` |
| `nix repl` | 互動式 Nix 表達式評估環境 | `nix repl` 然後 `:lf .` |
| `journalctl` | 查詢 systemd journal 日誌 | `journalctl -u 服務名.service -p err` |
| `systemctl` | 控制與查詢 systemd 服務狀態 | `systemctl status 服務名.service` |
| `nix why-depends` | 找出套件依賴路徑 | `nix why-depends /nix/store/... /nix/store/...` |
| `nix build --show-trace` | 建置時顯示完整 stack trace | `nix build .#system --show-trace` |

---

## 環境準備：建立測試用配置目錄

本 Lab 的每個任務都會使用獨立的配置檔案，而非直接修改 `/etc/nixos/configuration.nix`。這樣可以安全地製造錯誤並修復，不影響系統正常運作。

在你的 home 目錄下建立一個工作目錄：

```bash
mkdir -p ~/lab07-debugging
cd ~/lab07-debugging
```

接著確認系統已啟用 Flakes（應已在 Lab 6 中完成）：

```bash
# 確認 Flakes 功能可用
nix flake --help | head -3
```

如果出現說明文字而非錯誤，代表環境就緒。

---

## 任務一：修復 Evaluation Error（評估錯誤）

### 背景說明

Nix 在套用配置之前，會先「評估（evaluate）」整個配置樹。這個過程稱為 evaluation。如果配置中有拼字錯誤、不存在的 option、或型別不符，Nix 會在評估階段就直接報錯，根本不會進入建置程序。

這類錯誤通常是最容易修復的，關鍵在於讀懂錯誤訊息。

---

### Step 1：建立有問題的配置並重現錯誤

在 `~/lab07-debugging/` 目錄下建立 `buggy-config-1.nix`：

```nix
# ~/lab07-debugging/buggy-config-1.nix
# 這份配置包含兩個故意的錯誤，請不要先看答案
{ config, pkgs, lib, ... }:

{
  # 錯誤一：option 名稱拼字錯誤（多了一個 m）
  networking.hostNamme = "nixos";

  # 錯誤二：NixOS 25.05 已廢棄的 option 寫法
  # 正確應為 services.openssh.settings.PermitRootLogin
  services.openssh.permitRootLogin = "no";

  system.stateVersion = "25.05";
}
```

接著建立一個最小的 `flake.nix` 來載入這個配置，以便使用 `nixos-rebuild` 測試：

```nix
# ~/lab07-debugging/flake.nix
{
  description = "Lab 7 debugging sandbox";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # 使用測試用的有問題配置
        ./buggy-config-1.nix
      ];
    };
  };
}
```

初始化 Git repository（Flakes 必須在 git repo 中）：

```bash
cd ~/lab07-debugging
git init
git add .
```

現在觸發錯誤。`dry-run` 會評估配置但不實際建置，是最快重現 evaluation error 的方式：

```bash
sudo nixos-rebuild dry-run --flake ~/lab07-debugging#nixos 2>&1 | head -40
```

---

### Step 2：解讀錯誤訊息

你應該會看到類似以下的錯誤輸出。仔細閱讀每一行：

```
error: The option `networking.hostNamme' does not exist. Definition values:
- In `/home/alice/lab07-debugging/buggy-config-1.nix': "nixos"

Did you mean networking.hostName?

(use '--show-trace' to show detailed location information)
```

**逐行解析：**

- `error: The option 'networking.hostNamme' does not exist.`
  — Nix 告訴你，它在 NixOS 的 option 定義中找不到 `networking.hostNamme` 這個 option。這個 option 根本不存在。

- `Definition values: - In '/home/alice/lab07-debugging/buggy-config-1.nix': "nixos"`
  — 這個不存在的 option 是在哪個檔案的哪一行被設定的。這讓你不用猜就能直接定位問題。

- `Did you mean networking.hostName?`
  — Nix 很聰明，它會根據相似度建議你可能想用的正確 option 名稱。

現在用 `nixos-option` 確認正確的 option 名稱：

```bash
# 在系統上查詢 networking.hostName 的當前值與來源
nixos-option networking.hostName
```

預期輸出：

```
Value:
"nixos"

Default:
"nixos"

Declarations:
- /nix/store/.../nixos/modules/tasks/network-interfaces.nix

Description:
The name of the machine. Leave it empty if you want to obtain it
(through DHCP, for instance) at runtime rather than to set it at
boot time.
```

這告訴你 `networking.hostName`（不是 `hostNamme`）確實存在，而且是合法的 option。

接著看第二個錯誤。使用 `--show-trace` 取得更詳細的資訊：

```bash
sudo nixos-rebuild dry-run --flake ~/lab07-debugging#nixos --show-trace 2>&1 | head -60
```

你會看到關於 `services.openssh.permitRootLogin` 的錯誤，類似：

```
error: The option `services.openssh.permitRootLogin' does not exist. Definition values:
- In `/home/alice/lab07-debugging/buggy-config-1.nix': "no"

Did you mean one of services.openssh.settings.PermitRootLogin or
services.openssh.authorizedKeysCommand?
```

這是因為 NixOS 25.05 將 OpenSSH 的設定遷移到了 `settings` 子模組（對應 `sshd_config` 的結構），舊的 `permitRootLogin` option 已不存在。

---

### Step 3：修復並驗證

現在你已經知道兩個問題所在。建立修復後的版本 `fixed-config-1.nix`：

```nix
# ~/lab07-debugging/fixed-config-1.nix
# 修復後的配置
{ config, pkgs, lib, ... }:

{
  # 修復一：正確的 option 名稱（只有一個 m）
  networking.hostName = "nixos";

  # 修復二：NixOS 25.05 正確的 OpenSSH 設定語法
  # settings 子模組對應 sshd_config 的設定鍵（大小寫須與 sshd_config 一致）
  services.openssh = {
    enable = true;
    settings = {
      # 禁止 root 直接登入（安全最佳實踐）
      PermitRootLogin = "no";
      # 禁止密碼登入，只允許公鑰認證
      PasswordAuthentication = false;
    };
  };

  system.stateVersion = "25.05";
}
```

更新 `flake.nix` 改用修復後的配置：

```nix
# ~/lab07-debugging/flake.nix
{
  description = "Lab 7 debugging sandbox";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # 切換到修復後的配置
        ./fixed-config-1.nix
      ];
    };
  };
}
```

更新 Git 追蹤：

```bash
git add fixed-config-1.nix flake.nix
```

再次執行 `dry-run`，確認錯誤已消失：

```bash
sudo nixos-rebuild dry-run --flake ~/lab07-debugging#nixos 2>&1
```

預期輸出（沒有 error 字樣，只有進度訊息）：

```
building the system configuration...
these derivations will be built:
  /nix/store/...-nixos-system-nixos-25.05.drv
```

> **為什麼 NixOS 25.05 要用 `settings.PermitRootLogin`？**
>
> 在舊版 NixOS 中，常用的 daemon 設定被「扁平化（flatten）」成 NixOS option，例如 `services.openssh.permitRootLogin`。這種做法的問題是：每次 OpenSSH 新增設定項目，NixOS 模組就要同步新增 option，維護成本高且容易落後。
>
> NixOS 25.05 起，許多服務模組改用 `settings` 子模組，直接映射到底層設定檔的結構。`settings.PermitRootLogin` 對應 `sshd_config` 中的 `PermitRootLogin` 設定鍵，大小寫完全一致，讓你可以直接對照 `man sshd_config` 使用。

---

## 任務二：診斷 Option Conflict（選項衝突）

### 背景說明

NixOS 模組系統允許多個模組設定同一個 option。對於「合併語意（merge semantics）」的 option（例如 `environment.systemPackages` 列表），多個模組各自新增項目是完全合法的。

然而，對於「唯一值（single value）」的 option（例如 `services.nginx.enable` 布林值），如果兩個模組設定了**不同的值**，Nix 無法決定誰對誰錯，就會報出 option conflict（選項衝突）錯誤。

---

### Step 4：建立衝突配置並觸發錯誤

建立兩個互相衝突的模組。首先是 `module-a.nix`：

```nix
# ~/lab07-debugging/module-a.nix
# 模組 A：啟用 nginx
{ config, lib, pkgs, ... }:

{
  # 這個模組負責提供 Web 服務，所以啟用 nginx
  services.nginx.enable = true;
}
```

接著是 `module-b.nix`：

```nix
# ~/lab07-debugging/module-b.nix
# 模組 B：認為不需要 nginx
{ config, lib, pkgs, ... }:

{
  # 這個模組認為伺服器不應該有 Web 服務
  services.nginx.enable = false;
}
```

建立一個同時引入兩個模組的配置 `conflict-config.nix`：

```nix
# ~/lab07-debugging/conflict-config.nix
# 這個配置同時引入兩個對 services.nginx.enable 有不同意見的模組
{ config, pkgs, lib, ... }:

{
  imports = [
    ./module-a.nix
    ./module-b.nix
  ];

  # 系統基本設定
  networking.hostName = "nixos";
  system.stateVersion = "25.05";
}
```

更新 `flake.nix` 使用衝突配置：

```nix
# ~/lab07-debugging/flake.nix
{
  description = "Lab 7 debugging sandbox";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./conflict-config.nix
      ];
    };
  };
}
```

將所有新檔案加入 Git：

```bash
git add module-a.nix module-b.nix conflict-config.nix flake.nix
```

觸發錯誤：

```bash
sudo nixos-rebuild dry-run --flake ~/lab07-debugging#nixos 2>&1
```

你應該看到類似以下的錯誤：

```
error: The option `services.nginx.enable' has conflicting definition values:
- In `/home/alice/lab07-debugging/module-a.nix': true
- In `/home/alice/lab07-debugging/module-b.nix': false

Use `lib.mkForce value' or `lib.mkDefault value' to change the priority of the definition.
```

**為什麼布林 option 會衝突？**

布林值 option 的合併語意是「不允許衝突」：如果兩個定義的值不同，模組系統無法決定哪個正確，所以直接報錯。這與 list 類型的 option 不同——list 的合併語意是「合併所有定義」，所以多個模組各自新增到列表中是合法的。

---

### Step 5：使用 nixos-option 找出衝突來源

在真實的大型配置中，你不一定知道哪兩個檔案設定了同一個 option。`nixos-option` 可以顯示 option 的所有定義來源：

```bash
# 查詢 services.nginx.enable 的所有定義
nixos-option services.nginx.enable
```

預期輸出（在衝突已被修復的系統上）：

```
Value:
true

Default:
false

Declarations:
- /nix/store/.../nixos/modules/services/web-servers/nginx/default.nix

Definitions:
- In `/etc/nixos/configuration.nix': true
```

`Definitions` 欄位列出了所有「明確設定了這個 option」的檔案。如果看到同一個 option 被兩個不同檔案設定為不同的值，那就是衝突的來源。

你也可以用 `--show-trace` 取得更詳細的位置資訊：

```bash
sudo nixos-rebuild dry-run --flake ~/lab07-debugging#nixos --show-trace 2>&1 | grep -A 5 "conflicting"
```

---

### Step 6：三種解法與適用時機

Option conflict 有三種標準解法，選擇哪一種取決於你的設計意圖。

**解法一：用 `lib.mkDefault` 降低某方的優先級**

`lib.mkDefault` 將 option 標記為「預設值，可被覆蓋」。其他沒有用 `mkDefault` 或 `mkForce` 的定義會自動贏過它。

更新 `module-a.nix`：

```nix
# ~/lab07-debugging/module-a.nix
# 解法一：用 mkDefault 讓 module-b 的設定可以覆蓋這裡的預設
{ config, lib, pkgs, ... }:

{
  # lib.mkDefault：「預設啟用 nginx，但其他模組可以覆蓋這個決定」
  # 這樣 module-b 的 `services.nginx.enable = false` 就能勝出
  services.nginx.enable = lib.mkDefault true;
}
```

`module-b.nix` 保持不變（`= false`）。結果：`false` 勝出（module-b 的普通定義優先級高於 mkDefault）。

**解法二：用 `lib.mkForce` 強制覆蓋**

`lib.mkForce` 讓某個定義擁有最高優先級，強制覆蓋其他所有定義。

更新 `module-b.nix` 改為強制啟用（反轉邏輯）：

```nix
# ~/lab07-debugging/module-b.nix
# 解法二：用 mkForce 強制讓這個模組的設定勝出
{ config, lib, pkgs, ... }:

{
  # lib.mkForce：「無論其他模組怎麼說，nginx 一定要啟用」
  # 適合用在安全政策等「不允許被覆蓋」的設定
  services.nginx.enable = lib.mkForce true;
}
```

結果：`true` 勝出，即使 `module-a.nix` 設定了 `false` 也不影響。

**解法三：重新思考模組架構（推薦）**

`lib.mkDefault` 和 `lib.mkForce` 是工具，但最根本的問題是：**為什麼兩個模組需要設定同一個 option？**

正確的架構通常是：

```nix
# ~/lab07-debugging/module-a.nix
# 重構：module-a 提供 nginx 相關的設定，但不自己決定要不要啟用
# 由最上層的配置決定是否引入這個模組
{ config, lib, pkgs, ... }:

{
  # 只在 nginx 已啟用的情況下，才加入額外的 nginx 配置
  # 這樣就不會與其他模組產生 enable 的衝突
  services.nginx = lib.mkIf config.services.nginx.enable {
    virtualHosts."localhost" = {
      root = "/var/www/html";
    };
  };
}
```

```nix
# ~/lab07-debugging/conflict-config.nix
# 重構：由最上層配置統一決定 enable/disable
{ config, pkgs, lib, ... }:

{
  imports = [
    ./module-a.nix
    # 不再引入 module-b，因為 module-b 的唯一功能就是設定 enable = false
  ];

  # 在這裡明確決定是否啟用 nginx
  services.nginx.enable = true;

  networking.hostName = "nixos";
  system.stateVersion = "25.05";
}
```

**適用時機總結：**

| 情境 | 建議解法 |
|---|---|
| 某模組提供「預設值」，其他模組可以覆蓋 | `lib.mkDefault` |
| 安全政策或系統不變量，不允許被覆蓋 | `lib.mkForce` |
| 兩個模組職責重疊，設計上有問題 | 重構模組邊界 |

更新所有修改後的檔案：

```bash
git add module-a.nix module-b.nix conflict-config.nix
```

驗證衝突已解決：

```bash
sudo nixos-rebuild dry-run --flake ~/lab07-debugging#nixos 2>&1
```

沒有出現 `error: The option` 字樣，代表衝突修復成功。

---

## 任務三：修復服務啟動失敗

### 背景說明

有些錯誤不發生在 evaluation 階段，而是在服務實際啟動時。這類錯誤不會阻止 `nixos-rebuild switch` 完成，但服務會處於 `failed` 狀態。

診斷這類問題需要用到 `systemctl` 查看服務狀態，以及 `journalctl` 讀取詳細日誌。

---

### Step 7：套用有問題的服務配置並觀察失敗

建立一個包含有問題服務定義的配置 `broken-service.nix`：

```nix
# ~/lab07-debugging/broken-service.nix
# 這個配置定義了一個有 permission（權限）問題的自訂服務
{ config, pkgs, lib, ... }:

{
  networking.hostName = "nixos";

  # 定義一個自訂的 systemd 服務
  systemd.services.broken-webapp = {
    description = "A webapp with permission issues";

    # wantedBy：讓這個服務在系統進入多人模式時自動啟動
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      # 啟動指令：用 Python 內建的 HTTP server 監聽 8080 port
      ExecStart = "${pkgs.python3}/bin/python3 -m http.server 8080";

      # 問題在這裡：WorkingDirectory 設為 /root（root 的 home 目錄）
      # 但 User = "nobody" 代表服務以 nobody 身份執行
      # nobody 使用者沒有讀取 /root 的權限！
      WorkingDirectory = "/root";
      User = "nobody";

      # PrivateTmp：為服務建立獨立的 /tmp，避免服務間干擾
      PrivateTmp = true;
    };
  };

  # 開放防火牆的 8080 port
  networking.firewall.allowedTCPPorts = [ 8080 ];

  system.stateVersion = "25.05";
}
```

更新 `flake.nix` 使用這個配置：

```nix
# ~/lab07-debugging/flake.nix
{
  description = "Lab 7 debugging sandbox";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./broken-service.nix
      ];
    };
  };
}
```

更新 Git 追蹤：

```bash
git add broken-service.nix flake.nix
```

套用配置（`switch` 會真正啟動服務，不只是 dry-run）：

```bash
sudo nixos-rebuild switch --flake ~/lab07-debugging#nixos
```

`nixos-rebuild switch` 會成功完成（因為配置語法正確），但服務本身會啟動失敗。觀察服務狀態：

```bash
systemctl status broken-webapp.service
```

你會看到類似以下的輸出：

```
● broken-webapp.service - A webapp with permission issues
     Loaded: loaded (/etc/systemd/system/broken-webapp.service; enabled; vendor preset: enabled)
     Active: failed (Result: exit-code) since Sun 2026-05-18 10:23:45 UTC; 3s ago
    Process: 1234 ExecStart=/nix/store/...-python3-3.12.x/bin/python3 -m http.server 8080
             (code=exited, status=1/FAILURE)
   Main PID: 1234 (code=exited, status=1/FAILURE)

May 18 10:23:45 nixos systemd[1]: broken-webapp.service: Main process exited,
                                   code=exited, status=1/FAILURE
May 18 10:23:45 nixos systemd[1]: broken-webapp.service: Failed with result 'exit-code'.
May 18 10:23:45 nixos systemd[1]: Failed to start A webapp with permission issues.
```

關鍵資訊：`Active: failed` 和 `status=1/FAILURE`。但 `systemctl status` 只顯示最近幾行日誌，要看完整的錯誤需要 `journalctl`。

---

### Step 8：使用 journalctl 診斷

`journalctl`（journal control）是查詢 systemd journal 日誌的工具。以下幾個選項組合起來最有用：

```bash
# -u：指定 unit（服務名稱）
# -p err：只顯示 err（error）等級以上的日誌
# --since "5 min ago"：只看最近 5 分鐘的日誌（避免舊的干擾）
journalctl -u broken-webapp.service -p err --since "5 min ago"
```

預期看到：

```
May 18 10:23:45 nixos python3[1234]: Traceback (most recent call last):
May 18 10:23:45 nixos python3[1234]:   File "<frozen runpy>", line 198, in _run_module_as_main
May 18 10:23:45 nixos python3[1234]:   File "<frozen runpy>", line 88, in _run_module_as_main
May 18 10:23:45 nixos python3[1234]:   File "/nix/store/.../http/server.py", line 1284, in main
May 18 10:23:45 nixos python3[1234]: PermissionError: [Errno 13] Permission denied: '/root'
```

或者是 systemd 本身的錯誤（在 Python 啟動前就失敗）：

```
May 18 10:23:45 nixos systemd[1]: broken-webapp.service: Failed to change to
                                   working directory '/root': Permission denied
May 18 10:23:45 nixos systemd[1]: broken-webapp.service: Failed to set up process
                                   environment: Permission denied
```

**解讀關鍵錯誤訊息：**

- `Failed to change to working directory '/root': Permission denied`
  — systemd 在啟動進程之前，會先切換到 `WorkingDirectory` 指定的目錄。以 `nobody` 身份切換到 `/root` 時，因為 `/root` 的權限是 `drwx------`（只有 root 本人可進入），所以立即收到 Permission denied。

- `PermissionError: [Errno 13] Permission denied: '/root'`
  — 如果 systemd 允許了，Python 本身在嘗試列出 `/root` 目錄時也會遇到同樣的問題。

確認問題根本原因：`nobody` 使用者無法存取 `/root` 目錄。

你可以用以下指令手動驗證：

```bash
# 確認 /root 的實際權限
ls -la / | grep root

# 預期輸出：
# drwx------  1 root root  ... root
```

`drwx------` 的最後六個字元 `------` 表示「非 root 使用者沒有任何權限（讀取、寫入、執行都沒有）」。

---

### Step 9：修復服務——兩種方案

有兩種方式可以修復這個問題，各有適用場景。

**方案一：改用安全的 WorkingDirectory**

最直接的修復：把 `WorkingDirectory` 改到 `nobody` 可以存取的地方。

建立修復後的配置 `fixed-service-v1.nix`：

```nix
# ~/lab07-debugging/fixed-service-v1.nix
# 方案一：改用 /tmp 作為工作目錄
{ config, pkgs, lib, ... }:

{
  networking.hostName = "nixos";

  systemd.services.fixed-webapp = {
    description = "A webapp - fixed by using accessible WorkingDirectory";
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 -m http.server 8080";

      # 修復：使用 /tmp 作為工作目錄
      # /tmp 的權限是 drwxrwxrwt，任何使用者都可以存取
      WorkingDirectory = "/tmp";

      User = "nobody";
      PrivateTmp = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 8080 ];
  system.stateVersion = "25.05";
}
```

**方案二：使用 `RuntimeDirectory` 讓 systemd 自動建立目錄（推薦）**

更好的做法是讓 systemd 負責建立和管理服務的工作目錄，並自動設定正確的擁有者和權限：

```nix
# ~/lab07-debugging/fixed-service-v2.nix
# 方案二：用 RuntimeDirectory 讓 systemd 管理目錄的建立與權限
{ config, pkgs, lib, ... }:

{
  networking.hostName = "nixos";

  systemd.services.fixed-webapp-v2 = {
    description = "A webapp - fixed with RuntimeDirectory";
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 -m http.server 8080";

      # RuntimeDirectory：讓 systemd 在 /run/ 下建立同名目錄
      # systemd 會自動將目錄擁有者設為 User 指定的使用者（nobody）
      # 服務啟動時目錄存在，服務停止後自動清理
      RuntimeDirectory = "fixed-webapp-v2";

      # WorkingDirectory 改為 systemd 建立的目錄
      # %t 是 systemd specifier，代表 /run（runtime 目錄）
      WorkingDirectory = "/run/fixed-webapp-v2";

      User = "nobody";
      PrivateTmp = true;

      # 進一步加強安全性：限制服務只能讀取自己的 RuntimeDirectory
      # ReadOnlyPaths = "/";
      # ReadWritePaths = [ "/run/fixed-webapp-v2" ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 8080 ];
  system.stateVersion = "25.05";
}
```

> **為什麼 `RuntimeDirectory` 比 `/tmp` 更好？**
>
> 使用 `RuntimeDirectory`，systemd 會自動：
> 1. 在服務啟動前建立目錄（`/run/<RuntimeDirectory>/<name>`）
> 2. 將目錄的擁有者設為 `User` 指定的使用者
> 3. 在服務停止後自動刪除目錄（不留垃圾）
>
> 而手動指定 `/tmp` 需要自己確保 `/tmp` 確實存在且有正確的 sticky bit，也不會在服務停止時自動清理。`RuntimeDirectory` 是 systemd 服務設計的最佳實踐。

選用方案二，更新 `flake.nix` 套用修復：

```nix
# ~/lab07-debugging/flake.nix
{
  description = "Lab 7 debugging sandbox";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./fixed-service-v2.nix
      ];
    };
  };
}
```

加入 Git 並套用：

```bash
git add fixed-service-v1.nix fixed-service-v2.nix flake.nix
sudo nixos-rebuild switch --flake ~/lab07-debugging#nixos
```

確認服務成功啟動：

```bash
# 確認服務狀態為 active (running)
systemctl status fixed-webapp-v2.service
```

預期輸出：

```
● fixed-webapp-v2.service - A webapp - fixed with RuntimeDirectory
     Loaded: loaded (/etc/systemd/system/fixed-webapp-v2.service; enabled)
     Active: active (running) since Sun 2026-05-18 10:30:00 UTC; 5s ago
   Main PID: 5678 (python3)
      Tasks: 1 (limit: 4096)
     Memory: 8.2M
        CPU: 42ms
     CGroup: /system.slice/fixed-webapp-v2.service
             └─5678 /nix/store/...-python3-3.12.x/bin/python3 -m http.server 8080
```

驗證服務真正可用：

```bash
# 對 127.0.0.1:8080 發送 HTTP 請求
# 應該看到目錄列表（/run/fixed-webapp-v2 的內容）
curl -s http://127.0.0.1:8080
```

預期看到 HTML 目錄列表，類似：

```html
<!DOCTYPE HTML>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Directory listing for /</title>
...
```

收到 HTML 回應就代表服務正常運作。

---

## 任務四：使用 nix repl 探索配置

### 背景說明

`nix repl`（REPL，Read-Eval-Print Loop，互動式讀取-評估-輸出循環）是 Nix 的互動式評估環境，讓你可以不用執行 `nixos-rebuild` 就能查詢和探索配置值。

在除錯時，`nix repl` 特別適合用來：
- 確認某個 option 最終被評估為什麼值
- 探索 nixpkgs 中套件的 derivation 結構
- 測試 Nix 表達式的行為

---

### Step 10：載入 flake 並查詢配置值

確保你的工作目錄下有有效的 `flake.nix`（使用任一前面修復後的配置都可以）。

進入 `nix repl`：

```bash
cd ~/lab07-debugging
nix repl
```

你會看到提示符：

```
Nix 2.24.x
Type :? for help.

nix-repl>
```

使用 `:lf`（load flake）載入當前目錄的 `flake.nix`：

```
nix-repl> :lf .
Added 6 variables.
```

現在你可以查詢配置值。先確認 `nixosConfigurations` 中有什麼：

```
nix-repl> nixosConfigurations
{ nixos = { ... }; }
```

查詢主機名稱（對應 `networking.hostName`）：

```
nix-repl> nixosConfigurations.nixos.config.networking.hostName
"nixos"
```

查詢 OpenSSH 是否啟用（根據你最後用的配置）：

```
nix-repl> nixosConfigurations.nixos.config.services.openssh.enable
true
```

查詢我們修復後的服務定義：

```
nix-repl> nixosConfigurations.nixos.config.systemd.services.fixed-webapp-v2
{ ... }
```

使用 `:p`（print，展開完整輸出，不省略巢狀結構）查看完整的服務設定：

```
nix-repl> :p nixosConfigurations.nixos.config.systemd.services.fixed-webapp-v2
{
  description = "A webapp - fixed with RuntimeDirectory";
  serviceConfig = {
    ExecStart = "/nix/store/...-python3-3.12.x/bin/python3 -m http.server 8080";
    PrivateTmp = true;
    RuntimeDirectory = "fixed-webapp-v2";
    User = "nobody";
    WorkingDirectory = "/run/fixed-webapp-v2";
  };
  wantedBy = [ "multi-user.target" ];
}
```

這讓你可以確認服務的最終設定值確實如你預期，非常適合在「配置看起來是對的，但服務行為不符預期」時使用。

---

### Step 11：探索 nixpkgs 套件資訊

`nix repl` 也可以用來探索 nixpkgs 中的套件。

查看系統使用的 `pkgs` 物件：

```
nix-repl> nixosConfigurations.nixos.pkgs
{ ... }  # 這是整個 nixpkgs 套件集合
```

查詢特定套件的 derivation 路徑：

```
nix-repl> nixosConfigurations.nixos.pkgs.python3
«derivation /nix/store/...-python3-3.12.x.drv»
```

查詢套件版本：

```
nix-repl> nixosConfigurations.nixos.pkgs.python3.version
"3.12.x"
```

查詢套件的實際執行檔路徑：

```
nix-repl> nixosConfigurations.nixos.pkgs.python3.outPath
"/nix/store/...-python3-3.12.x"
```

查看 `git` 套件的詳細資訊（使用 `:p` 展開）：

```
nix-repl> :p nixosConfigurations.nixos.pkgs.git.meta
{
  description = "Distributed version control system";
  homepage = "https://git-scm.com";
  license = { ... };
  mainProgram = "git";
  platforms = [ ... ];
}
```

退出 `nix repl`：

```
nix-repl> :q
```

> **`nix repl` 的值是 lazy evaluated（惰性求值）**
>
> 在 `nix repl` 中，大部分值都是惰性的：直到你真正存取某個欄位，Nix 才會去評估它。這就是為什麼查詢 `nixosConfigurations.nixos.config` 時會看到 `{ ... }` 而不是完整展開的內容——展開整個配置樹會非常耗時。使用 `:p` 會強制展開，但對於頂層的大型 attribute set 要謹慎使用，以免等待太久。

---

## 驗證清單

完成本 Lab 後，請逐一確認以下項目：

| 編號 | 驗證項目 | 驗證方式 | 預期結果 |
|---|---|---|---|
| 1 | 任務一：能讀懂 attribute missing 錯誤 | 對 `buggy-config-1.nix` 執行 `dry-run`，確認你能指出兩個錯誤的位置 | 錯誤訊息中清楚顯示 `hostNamme` 和 `permitRootLogin` 的問題 |
| 2 | 任務一：正確修復 evaluation error | 對 `fixed-config-1.nix` 執行 `dry-run` | 不出現 `error:` 字樣 |
| 3 | 任務二：能解釋 option conflict 的原因 | 能口述為什麼 Bool 類型的 option 衝突會報錯 | 理解「合併語意」與「唯一值」的差異 |
| 4 | 任務二：至少用一種解法消除衝突 | 對修復後的配置執行 `dry-run` | 不出現 `conflicting definition values` |
| 5 | 任務三：服務成功啟動 | `systemctl status fixed-webapp-v2.service` | 顯示 `Active: active (running)` |
| 6 | 任務三：能用 journalctl 找到錯誤根因 | 能解釋 `Permission denied: '/root'` 的原因 | 理解 `nobody` 使用者的權限限制 |
| 7 | 任務三：curl 收到回應 | `curl -s http://127.0.0.1:8080` | 回傳 HTML 目錄列表 |
| 8 | 任務四：成功在 nix repl 中查詢配置值 | 啟動 `nix repl`、`:lf .`、查詢 `networking.hostName` | 回傳 `"nixos"` 字串 |

---

## 常見問題

### Q1：`nixos-option` 說 option 不存在，但 NixOS 官方文件說它有？

**可能原因一：** 文件的版本與你的系統版本不同。NixOS 25.05 的 `nixos-option` 只能查詢當前系統已安裝的 option，而官方文件可能是描述更新版本的 option。

**可能原因二：** 這個 option 是由某個模組提供的，但該模組的 `enable` 選項尚未設為 `true`。許多 service 的相關 option 只有在服務啟用後才能查詢。

**排查方式：**

```bash
# 確認當前系統版本
nixos-version

# 在 nix repl 中探索，確認 option 是否存在
nix repl
nix-repl> :lf .
nix-repl> nixosConfigurations.nixos.options.services.openssh
# 如果有這個 option，會顯示其定義；如果不存在，會報 attribute missing
```

---

### Q2：`nix repl` 載入 flake 失敗，說「not a flake」？

**錯誤訊息：**

```
error: path '/home/alice/lab07-debugging' does not contain a 'flake.nix'
```

或：

```
error: 'flake.nix' file is not tracked by Git
```

**排查步驟：**

1. 確認當前目錄確實有 `flake.nix`：

```bash
ls ~/lab07-debugging/flake.nix
```

2. 確認 `flake.nix` 已被 Git 追蹤：

```bash
cd ~/lab07-debugging
git status
# 確認 flake.nix 出現在 "Changes to be committed" 或已 commit
```

3. 如果 `flake.nix` 是 untracked（新建但未 `git add`），執行：

```bash
git add flake.nix
```

4. 在 `nix repl` 中指定完整路徑：

```
nix-repl> :lf /home/alice/lab07-debugging
```

---

### Q3：任務三的服務修好了，但 `curl` 還是被拒絕？

**可能原因一：** 防火牆還沒重新載入，舊的規則仍然有效。

```bash
# 確認防火牆規則已更新
sudo iptables -L INPUT -n | grep 8080
```

**可能原因二：** 服務啟動了但 Python HTTP server 綁定的是 `0.0.0.0:8080` 而非 `127.0.0.1:8080`，但防火牆只允許來自特定來源的連線。

由於是測試環境，確認服務確實在監聽：

```bash
# 查看 8080 port 的監聽狀態
ss -tlnp | grep 8080

# 預期輸出：
# LISTEN  0  5  0.0.0.0:8080  0.0.0.0:*  users:(("python3",pid=XXXX,fd=3))
```

**可能原因三：** `PrivateTmp = true` 加上 `RuntimeDirectory` 的組合在某些情況下會讓 Python 無法找到正確的工作目錄。嘗試加入更多日誌：

```bash
journalctl -u fixed-webapp-v2.service -f
# 在另一個終端執行 curl，觀察日誌輸出
curl http://127.0.0.1:8080
```

---

### Q4：Stack trace 很長，不知道從哪裡看起？

閱讀長 stack trace 的技巧：

**技巧一：從錯誤訊息本身開始，不是從 stack trace 開始。**

Nix 的 stack trace 是從最底層（問題發生處）列到最頂層（呼叫入口）。但真正有用的資訊通常在最開頭的 `error:` 行，而不是 stack trace 中間。

```bash
# 只看前 20 行（通常包含最重要的錯誤描述）
sudo nixos-rebuild dry-run --flake .#nixos --show-trace 2>&1 | head -20

# 或者只看包含 error: 的行
sudo nixos-rebuild dry-run --flake .#nixos --show-trace 2>&1 | grep "error:"
```

**技巧二：找「在你的檔案裡」發生的行。**

Nix 的 stack trace 會包含 nixpkgs 內部的呼叫路徑（`/nix/store/...`）和你自己的檔案路徑（`/etc/nixos/...` 或 `/home/alice/...`）。你只需要關注自己的檔案中發生了什麼。

```bash
# 過濾出包含你的配置路徑的行
sudo nixos-rebuild dry-run --flake .#nixos --show-trace 2>&1 | grep "lab07-debugging"
```

**技巧三：找最淺層的問題。**

stack trace 中通常有一行描述「最根本的問題在哪裡」，格式是 `... called from ...` 或 `at /path/to/file.nix:行號:欄號`。找到最靠近錯誤根因的那一行，就是需要修改的地方。

---

## 延伸練習

### 練習 1：設計一個包含 assertions 的模組，刻意違反條件

NixOS 模組系統支援 `assertions`（斷言），讓你可以在配置評估時執行自訂的邏輯驗證，並提供友善的錯誤訊息。

建立一個包含 assertion 的模組 `assertion-module.nix`：

```nix
# ~/lab07-debugging/assertion-module.nix
# 示範 assertions 的用法
{ config, lib, pkgs, ... }:

{
  imports = [];

  # 定義一個自訂 option
  options.myApp = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable my custom application";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port for the application to listen on";
    };
  };

  config = lib.mkIf config.myApp.enable {
    # assertions：列表中每個元素都是一個斷言
    # assertion：布林條件（必須為 true 才能繼續評估）
    # message：條件不滿足時顯示的錯誤訊息
    assertions = [
      {
        # 斷言：port 必須大於 1024（非特權 port）
        assertion = config.myApp.port > 1024;
        message = ''
          myApp.port must be greater than 1024 (unprivileged port).
          Current value: ${toString config.myApp.port}
          Hint: ports 1-1024 require root privileges.
        '';
      }
      {
        # 斷言：如果啟用了 myApp，防火牆必須開放對應的 port
        assertion =
          !config.networking.firewall.enable ||
          builtins.elem config.myApp.port config.networking.firewall.allowedTCPPorts;
        message = ''
          myApp is enabled on port ${toString config.myApp.port},
          but the firewall is not configured to allow it.
          Add ${toString config.myApp.port} to networking.firewall.allowedTCPPorts.
        '';
      }
    ];
  };
}
```

建立刻意違反斷言的配置，觀察錯誤訊息格式：

```nix
# ~/lab07-debugging/assertion-test.nix
{ config, pkgs, lib, ... }:

{
  imports = [
    ./assertion-module.nix
  ];

  networking.hostName = "nixos";

  # 啟用 myApp 但使用 privileged port（違反斷言一）
  myApp.enable = true;
  myApp.port = 80;  # 小於 1024，會觸發第一個 assertion

  # 防火牆啟用但沒開放 port 80（也會觸發第二個 assertion）
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [];

  system.stateVersion = "25.05";
}
```

執行並觀察 assertion 錯誤的格式，與一般的 evaluation error 有何不同？

---

### 練習 2：用 `nix why-depends` 找出隱藏的依賴

有時候你的系統會包含某個你沒有明確安裝的套件，佔用了大量磁碟空間。`nix why-depends` 可以找出依賴路徑。

首先確認系統根路徑：

```bash
# 找出目前系統的 /run/current-system 路徑
readlink /run/current-system
```

接著找出為什麼系統包含 `perl`（舉例）：

```bash
# 語法：nix why-depends <source-path> <dependency-path>
nix why-depends /run/current-system $(nix eval --raw nixpkgs#perl)
```

這個指令會顯示從系統根路徑到 `perl` 的依賴鏈，讓你知道是哪個套件把 `perl` 拉進來的。

進階練習：找出你的系統中佔用空間最大的套件，並用 `nix why-depends` 追蹤為什麼它在系統裡。

```bash
# 查看 /nix/store 中最大的路徑
du -sh /nix/store/* 2>/dev/null | sort -rh | head -20
```

---

### 練習 3：製造 infinite recursion 並用 --show-trace 找到根因

`infinite recursion`（無限遞迴）是 Nix 中另一類特殊錯誤，通常發生在模組之間互相引用對方的 `config` 值而形成循環。

在 overlay（套件覆蓋）中，一個常見的錯誤是把 `final` 用在應該用 `prev` 的地方：

```nix
# ~/lab07-debugging/bad-overlay.nix
# 這個 overlay 有 infinite recursion 問題
{ config, pkgs, lib, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      # 問題：用 final.python3 引用 python3，而 final.python3 又是這個 overlay 定義的
      # 這形成了 python3 → python3 → python3 的無限循環
      python3 = final.python3.override {
        # 嘗試覆蓋 python3，但引用的是 final.python3（自己）而非 prev.python3（原版）
        enableOptimizations = true;
      };
    })
  ];

  networking.hostName = "nixos";
  system.stateVersion = "25.05";
}
```

執行時加上 `--show-trace` 觀察完整的 stack trace：

```bash
sudo nixos-rebuild dry-run --flake ~/lab07-debugging#nixos --show-trace 2>&1 | head -50
```

你會看到 stack trace 中重複出現相同的路徑，這就是無限遞迴的特徵。

修復方法：把 `final.python3` 改為 `prev.python3`（引用 overlay 套用前的版本，而非套用後的版本），打破循環。

```nix
# 修復後的 overlay
(final: prev: {
  # 正確：使用 prev.python3（overlay 套用前的原始版本）
  python3 = prev.python3.override {
    enableOptimizations = true;
  };
})
```

---

## 小結

恭喜你完成了 Lab 7！

### 你在本 Lab 中學到的

**除錯的核心工作流程：**

```
重現錯誤 → 讀懂錯誤訊息 → 找出根因 → 修復 → 驗證
```

這個流程看起來簡單，但每一步都需要練習。真實環境中的錯誤往往不如本 Lab 的範例那麼清楚，需要多次迭代才能找到根因。

**三類錯誤的診斷工具：**

| 錯誤類型 | 主要工具 | 關鍵訊號 |
|---|---|---|
| Evaluation error | `nixos-rebuild dry-run --show-trace`、`nixos-option` | `error: The option '...' does not exist` |
| Option conflict | `nixos-rebuild dry-run`、`nixos-option`（查 Definitions 欄位） | `conflicting definition values` |
| Service failure | `systemctl status`、`journalctl -u -p err` | `Active: failed`、`Permission denied` |

**`nix repl` 是你的瑞士刀：**

在不確定「這個 option 最終被評估為什麼值」時，`nix repl` + `:lf .` 可以讓你在不套用配置的情況下直接查詢任何值。把它養成習慣，在修改配置前先在 repl 中驗證邏輯。

---

### 第七篇總結：除錯與維護

第 26–28 章帶你建立了完整的 NixOS 除錯與維運能力：

- **第 26 章**：NixOS 除錯工具與技巧——`nixos-option`、`nix repl`、`nix-tree`、`nix log`、systemd/journald 等工具的系統化使用
- **第 27 章**：升級與遷移策略——channel 與 flake 的版本管理、stateVersion 的意義、跨大版本升級的安全步驟、rollback 機制
- **第 28 章**：常見陷阱與錯誤訊息速查——新手最常踩到的問題（fetchurl hash、mkForce 衝突、stateVersion、impurity 等）與對應解法

這些技能共同構成了「系統出問題時你不會慌」的能力基礎。NixOS 的宣告式設計讓錯誤更可重現、回滾更安全，但這些優勢需要你熟悉工具才能充分發揮。

---

### 預告：第八篇——企業與基礎設施（第 29–32 章）

完成除錯能力的建立後，書籍的最後一篇將把視野擴展到團隊與企業層級的應用：

- **第 29 章**：伺服器配置模式——Web Server、Database Server、Virtualization Host、Container Host、Backup Server、Monitoring Stack 等實戰 profile 設計
- **第 30 章**：雲端與虛擬化——Proxmox、KVM/QEMU、LXC、AWS EC2、OCI image 建置、`nixos-anywhere` 遠端安裝
- **第 31 章**：CI/CD 與 GitOps——GitHub Actions + Nix、`nix flake check` 驗證、Cachix binary cache、自動部署 pipeline、Hydra
- **第 32 章**：NixOS 團隊協作架構——monorepo vs multi-repo、Branch/PR 流程、Code Review、Module Ownership、Onboarding 與 Breaking Change 管理

第八篇的章節將把你在 Lab 6 學到的多主機 Flakes 架構，擴展到真實工程團隊的協作場景。
