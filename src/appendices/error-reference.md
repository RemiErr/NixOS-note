# 附錄D：常見 NixOS 錯誤速查

本附錄收錄 NixOS 使用者最常遇到的錯誤訊息，並提供原因說明、診斷方式與解決步驟。

---

## 使用方式

1. **複製錯誤訊息的關鍵字**，例如 `undefined variable`、`hash mismatch`、`conflicting values`。
2. 用瀏覽器或編輯器的「頁面搜尋」功能（Ctrl+F）搜尋關鍵字。
3. 找到對應的小節後，依照「原因 → 解決 → 範例」的順序診斷。
4. 若錯誤訊息未列出，請參考 **D.9 快速診斷流程**，從系統日誌開始追蹤。

> **注意：** 所有程式碼區塊中的錯誤訊息均為實際輸出，可直接複製搜尋。

---

## D.1 Nix 語言求值錯誤（Evaluation Errors）

這類錯誤發生在 Nix 解析和求值你的配置檔案時，通常出現在執行 `nixos-rebuild` 或 `nix eval` 的最初階段，尚未開始建置。

---

### D.1.1 undefined variable 'xxx'

**錯誤訊息：**

```
error: undefined variable 'pkgs'
       at /etc/nixos/configuration.nix:5:30:
            4|   environment.systemPackages = [
            5|     pkgs.git
              |                              ^
```

**原因：**

引用了在當前作用域中不存在的變數。最常見的情況有兩種：

- 函式參數列表中漏寫了 `pkgs`（或其他所需參數）
- 忘記 `let ... in` 語法，或拼寫錯誤變數名稱
- 忘記 `with pkgs;` 宣告就直接使用套件名稱

**解決：**

1. 確認函式簽名包含所需的參數：

```nix
# 錯誤：缺少 pkgs 參數
{ config, ... }: {
  environment.systemPackages = [ pkgs.git ];  # pkgs 未定義
}

# 正確：加入 pkgs 參數
{ config, pkgs, ... }: {
  environment.systemPackages = [ pkgs.git ];
}
```

2. 若使用 `let...in`，確認變數在 `let` 區塊中已定義：

```nix
{ pkgs, ... }: {
  # 正確用法
  environment.systemPackages = let
    myTools = [ pkgs.git pkgs.curl ];
  in myTools;
}
```

---

### D.1.2 attribute 'xxx' missing

**錯誤訊息：**

```
error: attribute 'nignx' missing
       at /etc/nixos/configuration.nix:12:5:
           11|   services = {
           12|     nignx.enable = true;
              |     ^
       Did you mean 'nginx'?
```

**原因：**

存取了 attribute set 中不存在的鍵（key）。常見原因：

- 拼字錯誤（typo），Nix 有時會提示「Did you mean」
- Option 路徑的大小寫錯誤（Nix 大小寫敏感）
- 套件名稱在 nixpkgs 中不存在，或已改名

**解決：**

1. 仔細核對 option 路徑大小寫，查閱 [NixOS Options](https://search.nixos.org/options)
2. 確認套件名稱：

```bash
nix search nixpkgs <關鍵字>
# 或在 nixpkgs 中查詢
nix-env -qaP | grep <關鍵字>
```

3. 查詢該套件是否已改名（查看 nixpkgs changelog）

---

### D.1.3 infinite recursion encountered

**錯誤訊息：**

```
error: infinite recursion encountered
       at /etc/nixos/configuration.nix:8:22:
            7|   networking.hostName = config.networking.hostName;
            8|                       ^
```

**原因：**

配置中存在循環依賴。某個 option 的值依賴自身，或兩個 option 互相依賴。常見於：

- 在 `rec` 區塊中定義了循環引用的屬性
- 一個 option 的 `default` 值引用了自身

**解決：**

避免循環依賴，改用字面值或不同的參考路徑：

```nix
# 錯誤：循環引用
{ config, ... }: {
  networking.hostName = config.networking.hostName;
}

# 正確：直接給值
{ config, ... }: {
  networking.hostName = "my-nixos";
}
```

若在 `rec` 中使用，要確認沒有循環：

```nix
# 錯誤：rec 中的循環引用
let
  attrs = rec {
    a = b + 1;
    b = a + 1;  # 循環！
  };
in attrs

# 正確：用字面值打破循環
let
  attrs = rec {
    a = 1;
    b = a + 1;  # b 依賴 a，但 a 不依賴 b
  };
in attrs
```

---

### D.1.4 cannot coerce xxx to string

**錯誤訊息：**

```
error: cannot coerce a set to a string
       at «string»:1:1:
            1| /home/user + "/config"
              | ^
```

**原因：**

Nix 在字串插值或字串連接時，遇到了無法自動轉換為字串的型別。常見情況：

- 路徑（path type）與字串（string）直接用 `+` 拼接
- attribute set 被誤當成字串使用

**解決：**

```nix
# 錯誤：路徑 + 字串
environment.etc."myconfig".source = /home/user + "/config";

# 正確方式一：全部用字串
environment.etc."myconfig".source = "/home/user/config";

# 正確方式二：用 toString 轉換
environment.etc."myconfig".source = toString /home/user + "/config";

# 正確方式三：字串插值（推薦）
let homeDir = "/home/user"; in
environment.etc."myconfig".source = "${homeDir}/config";
```

---

### D.1.5 value is a function, expected an attribute set

**錯誤訊息：**

```
error: value is a function, expected an attribute set
       at /nix/store/xxx-nixos/nixos/lib/eval-config.nix:85:17
```

**原因：**

某個地方應該傳入 attribute set（`{}`），但實際傳入了函式（未被呼叫）。最常見於：

- `imports` 列表中直接放入函式而非 attribute set
- 使用 overlay 時忘記呼叫函式

**解決：**

```nix
# 錯誤：imports 中放入了函式（未呼叫）
imports = [
  someModule   # 如果 someModule 是個函式，應該用 someModule { ... }
];

# 正確：傳入 attribute set
imports = [
  ./hardware-configuration.nix  # 路徑（會被求值為 attribute set）
  (import ./my-module.nix { inherit pkgs; })  # 呼叫函式
];
```

---

### D.1.6 assertion failed

**錯誤訊息：**

```
error: assertion '(config.services.postgresql.enable)' failed
       at /nix/store/xxx/nixos/modules/services/databases/postgresql.nix:42:5
```

**原因：**

某個模組或配置中的 `assert` 條件不成立。通常是前置依賴未滿足，或配置值不符合模組的限制條件。

**解決：**

1. 閱讀錯誤訊息，找到 assert 的位置
2. 確認相關的依賴條件是否已啟用：

```nix
# 若某服務需要 postgresql，要先啟用它
services.postgresql.enable = true;
services.someApp.enable = true;  # 此服務依賴 postgresql
```

---

### D.1.7 value called with unexpected argument

**錯誤訊息：**

```
error: function 'anonymous lambda' called with unexpected argument 'extraConfig'
       at /etc/nixos/my-module.nix:1:1
```

**原因：**

呼叫函式時傳入了函式定義中沒有的參數。常見於自訂模組的函式簽名不完整，或傳入了拼寫錯誤的參數名稱。

**解決：**

```nix
# 錯誤：函式不接受 extraConfig 參數
let myFunc = { pkgs, config }: { ... };
in myFunc { pkgs = pkgs; config = config; extraConfig = {}; }  # 多傳了 extraConfig

# 正確方式一：加入 ... 接受額外參數
let myFunc = { pkgs, config, ... }: { ... };

# 正確方式二：移除多餘的參數
let myFunc = { pkgs, config }: { ... };
in myFunc { pkgs = pkgs; config = config; }
```

---

## D.2 NixOS 模組系統錯誤（Module System Errors）

模組系統錯誤發生在 NixOS 合併所有模組配置時，通常涉及 option 定義、型別檢查和值合併。

---

### D.2.1 The option 'xxx' does not exist

**錯誤訊息：**

```
error: The option `services.nignx.enable' does not exist. Definition values:
       - In `/etc/nixos/configuration.nix': true
```

**原因：**

設定了 NixOS 中不存在的 option 路徑。常見原因：拼寫錯誤、大小寫錯誤、或相關模組未引入。

**解決：**

1. 搜尋正確的 option 名稱：[https://search.nixos.org/options](https://search.nixos.org/options)
2. 使用 `nixos-option` 指令查詢：

```bash
nixos-option services.nginx.enable
```

3. 確認 option 路徑完全正確（區分大小寫）

---

### D.2.2 The option 'xxx' has conflicting definition values

**錯誤訊息：**

```
error: The option `networking.hostName' has conflicting definition values:
       - In `/etc/nixos/configuration.nix': "host-a"
       - In `/etc/nixos/extra.nix': "host-b"
       Use `lib.mkForce' to override or `lib.mkDefault' to set a default value.
```

**原因：**

同一個 option 在多個模組中被設定為不同的值，且 Nix 無法自動解決衝突（只有 list 和 attrs 型別的 option 可以合併，string 和 bool 等無法合併）。

**解決：**

使用 `lib.mkForce` 或 `lib.mkDefault` 明確指定優先順序：

```nix
# 在需要優先的模組中
networking.hostName = lib.mkForce "host-a";  # 強制覆蓋其他所有定義

# 或在次要模組中設定預設值（可被覆蓋）
networking.hostName = lib.mkDefault "host-b";  # 可被其他模組覆蓋
```

優先順序：`mkForce` > 一般設定 > `mkDefault`

---

### D.2.3 A definition for option 'xxx' is not of type 'yyy'

**錯誤訊息：**

```
error: A definition for option `services.nginx.virtualHosts' is not of type
       `attribute set of submodules'. Definition values:
       - In `/etc/nixos/configuration.nix':
           [ "example.com" ]
```

**原因：**

option 的型別與提供的值不符。例如：

- 某 option 期望 `attrs`（attribute set），卻給了 `list`
- 期望 `bool`，卻給了 `string`（`"true"` 而非 `true`）
- 期望 `int`，卻給了 `string`

**解決：**

查閱 option 文件確認正確的型別，並相應修改值：

```nix
# 錯誤：virtualHosts 不是 list，是 attribute set
services.nginx.virtualHosts = [ "example.com" ];

# 正確：使用 attribute set 格式
services.nginx.virtualHosts = {
  "example.com" = {
    root = "/var/www/example";
  };
};
```

---

### D.2.4 The option 'xxx' is used but not defined

**錯誤訊息：**

```
error: The option `myModule.settings.port' is used but not defined.
```

**原因：**

自訂模組中使用了某個 option，但未在模組的 `options` 區塊中定義它。這通常是自訂模組開發時的問題。

**解決：**

在模組的 `options` 區塊中定義該 option：

```nix
{ config, lib, pkgs, ... }:
{
  options.myModule.settings.port = lib.mkOption {
    type = lib.types.port;
    default = 8080;
    description = "要監聽的連接埠號";
  };

  config = lib.mkIf config.myModule.enable {
    # 使用 config.myModule.settings.port
  };
}
```

---

### D.2.5 lib.mkIf: condition must be a boolean

**錯誤訊息：**

```
error: The option value `services.myService.enable' in `/etc/nixos/configuration.nix'
       is not a boolean, but a string "true". Use `true' or `false'.
```

或：

```
error: `lib.mkIf': condition must evaluate to a boolean (true or false), but got a string
```

**原因：**

`lib.mkIf` 的第一個參數必須是布林值（`true` 或 `false`），但傳入了字串或其他型別。

**解決：**

```nix
# 錯誤：傳入字串 "true"
services.nginx.enable = lib.mkIf "true" { ... };

# 錯誤：傳入 null
services.nginx.enable = lib.mkIf null { ... };

# 正確：傳入布林值
services.nginx.enable = lib.mkIf config.services.webServer.enable true;

# 正確：使用條件判斷
services.nginx.enable = lib.mkIf (config.myApp.backend == "nginx") true;
```

---

### D.2.6 specialArgs: module argument 'xxx' is missing

**錯誤訊息：**

```
error: module argument 'myCustomArg' is missing in call to
       '/etc/nixos/my-module.nix'
```

**原因：**

模組的函式簽名中列出了某個參數（如 `myCustomArg`），但在 `nixpkgs.lib.nixosSystem` 或 `evalModules` 的 `specialArgs` 中沒有提供該參數。

**解決：**

在 `flake.nix` 的 `nixosSystem` 呼叫中加入 `specialArgs`：

```nix
# flake.nix
nixosConfigurations.myHost = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = {
    myCustomArg = "someValue";  # 在這裡傳入
  };
  modules = [ ./configuration.nix ];
};

# my-module.nix（接收 specialArgs 的值）
{ config, pkgs, myCustomArg, ... }: {
  # 使用 myCustomArg
}
```

---

## D.3 建置錯誤（Build Errors）

建置錯誤發生在 Nix 實際編譯或下載套件時，此類錯誤通常包含較長的日誌輸出。

---

### D.3.1 builder for '...' failed with exit code N

**錯誤訊息：**

```
error: builder for '/nix/store/xxx-my-package-1.0.drv' failed with exit code 1;
       last 10 log lines:
       > make: *** [Makefile:42: main.o] Error 1
       > error: compilation of `main.c' failed
       ...
       For full logs, run 'nix log /nix/store/xxx-my-package-1.0.drv'.
```

**原因：**

套件的建置指令（通常是 `make`、`cmake` 或自訂腳本）返回了非零退出碼，表示建置失敗。

**解決：**

1. 查看完整建置日誌（最重要的步驟）：

```bash
nix log /nix/store/xxx-my-package-1.0.drv
# 或在建置時加 -L 參數顯示即時日誌
nixos-rebuild switch -L
nix build .#myPackage -L
```

2. 常見修復方向：
   - 缺少 build input：在 `buildInputs` 中加入所需的函式庫
   - 編譯旗標問題：調整 `CFLAGS` 或 `NIX_CFLAGS_COMPILE`
   - 上游 bug：搜尋 nixpkgs issues 或回報問題

---

### D.3.2 hash mismatch in fixed-output derivation

**錯誤訊息：**

```
error: hash mismatch in fixed-output derivation '/nix/store/xxx-source.drv':
         specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
            got:    sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=
```

**原因：**

`fetchurl`、`fetchFromGitHub` 等 fetcher 的 `hash`（或舊版 `sha256`）欄位與實際下載內容的雜湊值不符。通常是上游更新了檔案但雜湊值未更新。

**解決：**

方法一：使用錯誤訊息中的「got」雜湊值更新配置：

```nix
src = fetchFromGitHub {
  owner = "example";
  repo = "myrepo";
  rev = "v1.0.0";
  hash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";  # 替換為實際值
};
```

方法二：用 `lib.fakeSha256` 觸發 Nix 輸出正確的 hash：

```bash
# 先設定假的 hash
hash = lib.fakeSha256;
# 執行建置，從錯誤訊息中取得正確 hash，再替換
```

方法三（更新 flake.lock）：

```bash
nix flake update             # 更新所有輸入
nix flake update nixpkgs     # 只更新 nixpkgs
```

---

### D.3.3 source tree is dirty

**錯誤訊息：**

```
warning: Git tree '/home/user/nixos-config' is dirty
```

或（在嚴格模式下報錯）：

```
error: program source directory '/home/user/nixos-config' is not clean
```

**原因：**

在 flake 模式下，Nix 要求 git 儲存庫是乾淨狀態（所有變更都已提交）。未追蹤（untracked）或已修改但未提交的檔案會觸發此警告或錯誤。

**解決：**

```bash
# 暫時加入暫存區（不需要完整提交）
git add .

# 或提交所有變更
git add .
git commit -m "update config"

# 若只是要測試，可用 --impure 繞過（不建議長期使用）
nixos-rebuild switch --flake . --impure
```

---

### D.3.4 error: package 'xxx' is not available for architecture

**錯誤訊息：**

```
error: Package 'some-package-1.0' in /nix/store/xxx/pkgs/... is not available
       on the requested hostPlatform:
         hostPlatform.config = "aarch64-linux"
```

**原因：**

嘗試在不支援的架構上安裝某個套件。該套件可能只有 x86_64 的二進制快取，或源碼不支援 aarch64。

**解決：**

1. 確認套件是否支援目標架構：在 [status.nixos.org](https://status.nixos.org) 查詢
2. 改用替代套件
3. 強制本地建置（若源碼實際上支援該架構）：

```nix
# 允許不支援的套件（謹慎使用）
nixpkgs.config.allowUnsupportedSystem = true;
```

---

### D.3.5 substituter failed for

**錯誤訊息：**

```
warning: substituter 'https://cache.nixos.org' failed to download
         '/nix/store/xxx.narinfo': error: unable to download
         'https://cache.nixos.org/xxx.narinfo': HTTP error 404
```

**原因：**

Nix 嘗試從 binary cache（二進制快取）下載預建置的套件，但該快取中沒有對應的版本，或網路連線失敗。

**解決：**

1. 確認網路連線正常
2. 允許從源碼建置（移除 `--no-build-on-failure` 限制）：

```bash
# 讓 Nix 自動從源碼建置
nixos-rebuild switch 2>&1 | grep -v "substituter"
```

3. 若要跳過特定快取（臨時）：

```bash
nix build --option substitute false .#myPackage
```

4. 加入額外的 binary cache：

```nix
nix.settings = {
  substituters = [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
  ];
  trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkN8ETRuZfpIAFy0qsH7s="
  ];
};
```

---

## D.4 NixOS 啟用錯誤（Activation Errors）

這類錯誤發生在 `nixos-rebuild switch` 的最後階段，當 NixOS 嘗試將新配置應用到正在運行的系統時。

---

### D.4.1 Failed to start unit 'xxx.service'

**錯誤訊息：**

```
error: activation script snippet 'nixos-activation' failed (exit status 1)
Job for nginx.service failed. See 'journalctl -xe' for details.
```

**原因：**

systemd 服務啟動失敗。可能原因：配置檔案有語法錯誤、依賴的資源不存在、連接埠已被佔用等。

**診斷流程：**

```bash
# 步驟 1：查看服務詳細狀態
systemctl status nginx.service

# 步驟 2：查看服務日誌（最近 100 行）
journalctl -u nginx.service -n 100

# 步驟 3：查看系統日誌（啟動時的錯誤）
journalctl -xe

# 步驟 4：若是配置檔案問題，測試配置
nginx -t  # 測試 nginx 配置語法

# 步驟 5：手動啟動以取得詳細輸出
systemctl start nginx.service
journalctl -u nginx.service -f  # 即時追蹤日誌
```

---

### D.4.2 File exists（啟用時檔案衝突）

**錯誤訊息：**

```
error: File exists '/etc/nginx/nginx.conf'
setting up /etc...
```

**原因：**

NixOS 嘗試建立或替換 `/etc` 下的某個檔案，但該位置已存在一個不是由 NixOS 管理的普通檔案（不是 symlink）。

**解決：**

1. 確認衝突的檔案是否需要保留
2. 若不需要，刪除或備份後重新啟用：

```bash
# 備份舊檔案
sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak

# 重新啟用
sudo nixos-rebuild switch
```

3. 若需要保留舊檔案的內容，將其整合到 NixOS 配置中：

```nix
# 在 configuration.nix 中管理此檔案
environment.etc."nginx/nginx.conf".text = ''
  # 你原本的 nginx 配置內容
'';
```

---

### D.4.3 error: stateVersion must not be changed

**錯誤訊息：**

```
error: The stateVersion (currently "24.05") must not be changed. Once set, it
       remains fixed for the lifetime of the system to ensure compatibility.
```

**原因：**

`system.stateVersion` 一旦設定後不應隨意更改。它代表系統初始安裝時的 NixOS 版本，用於維持某些狀態目錄和格式的向後相容性。

**解決：**

保持 `system.stateVersion` 不變，它不代表你目前使用的 NixOS 版本：

```nix
# 正確做法：保留最初安裝時的版本號
system.stateVersion = "24.05";  # 這是你第一次安裝的版本，不要修改

# 你可以自由升級 nixpkgs 通道，不影響 stateVersion
```

若需要了解升級系統版本的正確方式，請查閱第二十章「NixOS 版本升級」。

---

### D.4.4 Permission denied（啟用時許可權問題）

**錯誤訊息：**

```
error: activation script snippet 'setup-etc' failed (exit status 1)
cp: cannot create regular file '/etc/hosts': Permission denied
```

**原因：**

NixOS 啟用腳本（activation script）沒有足夠的許可權寫入某個檔案或目錄。通常是因為未使用 `sudo` 執行 `nixos-rebuild`。

**解決：**

```bash
# 確保使用 sudo
sudo nixos-rebuild switch

# 若使用 flake
sudo nixos-rebuild switch --flake .#myHost
```

若問題持續存在，檢查目標檔案的擁有者：

```bash
ls -la /etc/hosts
# 若擁有者不是 root，修復它
sudo chown root:root /etc/hosts
```

---

## D.5 Flake 相關錯誤

---

### D.5.1 No such file or directory: flake.nix

**錯誤訊息：**

```
error: getting status of '/nix/store/xxx/flake.nix': No such file or directory
```

**原因：**

Nix 找不到 `flake.nix` 檔案。可能原因：

- 當前目錄沒有 `flake.nix`
- `flake.nix` 不在 git 儲存庫根目錄
- 拼寫錯誤（注意：是 `flake.nix` 不是 `Flake.nix`）

**解決：**

```bash
# 確認當前目錄有 flake.nix
ls flake.nix

# 確認檔案已加入 git 追蹤
git add flake.nix

# 明確指定 flake 路徑
nixos-rebuild switch --flake /path/to/config#hostname
```

---

### D.5.2 input 'xxx' has no flake.nix

**錯誤訊息：**

```
error: input 'myNonFlakeInput' has no flake.nix; if it has a flake.nix
       but is not meant to be a flake, add `flake = false` to its input definition.
```

**原因：**

在 `flake.nix` 的 `inputs` 中引用了一個非 flake 的 git 儲存庫，但沒有標記 `flake = false`。

**解決：**

```nix
# flake.nix
{
  inputs = {
    # 對於非 flake 的輸入（例如普通的 git repo），加入 flake = false
    myNonFlakeInput = {
      url = "github:example/non-flake-repo";
      flake = false;  # 必須加這一行
    };
  };
}
```

---

### D.5.3 attribute 'xxx' missing in flake outputs

**錯誤訊息：**

```
error: attribute 'nixosConfigurations' missing in flake outputs
```

或：

```
error: nixosConfiguration 'myHost' is not defined in flake.nix
```

**原因：**

`flake.nix` 的 `outputs` 中沒有定義所需的屬性，或 hostname 拼寫錯誤。

**解決：**

確認 `flake.nix` 的 outputs 包含正確的屬性：

```nix
{
  outputs = { nixpkgs, ... }: {
    # 確認 hostname 與實際呼叫時一致
    nixosConfigurations.myHost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration.nix ];
    };
  };
}
```

呼叫時確認 hostname 正確：

```bash
# hostname 必須對應 nixosConfigurations.myHost
nixos-rebuild switch --flake .#myHost
```

---

### D.5.4 Lock file doesn't match

**錯誤訊息：**

```
error: lock file '/home/user/config/flake.lock' is not up-to-date.
       Run 'nix flake update' first.
```

**原因：**

`flake.lock` 記錄的輸入版本與 `flake.nix` 中的 URL 不一致，或 lock 檔案損壞。

**解決：**

```bash
# 更新 lock 檔案
nix flake update

# 只更新特定輸入
nix flake update nixpkgs

# 若 lock 檔案損壞，刪除後重新生成
rm flake.lock
nix flake lock
```

---

### D.5.5 warning: Git tree is dirty

**錯誤訊息：**

```
warning: Git tree '/home/user/nixos-config' is dirty
```

**原因：**

工作目錄有未提交的變更（包含未 stage 或已 stage 但未 commit 的檔案）。在 flake 模式下，Nix 會複製 git 追蹤的檔案，因此未提交的變更不會被包含在建置中。

**解決：**

```bash
# 查看未追蹤的變更
git status

# 加入並提交（推薦）
git add .
git commit -m "update configuration"

# 臨時解法：只加入 stage（不需 commit）
git add .

# 若要包含未追蹤的檔案，使用 --impure（只用於測試）
nixos-rebuild switch --flake . --impure
```

---

## D.6 套件安裝錯誤

---

### D.6.1 Package 'xxx' has an unfree license

**錯誤訊息：**

```
error: Package 'vscode-1.85.0' in /nix/store/xxx/pkgs/... has an unfree license
       ('unfree'), refusing to evaluate.

       a) To temporarily allow unfree packages, you can use an environment variable:
          $ NIXPKGS_ALLOW_UNFREE=1 nix-env -iA nixpkgs.vscode

       b) For `nixos-rebuild` you may wish to add a `nixpkgs.config.allowUnfree = true;`
          declaration to your NixOS or Home Manager configuration.
```

**原因：**

嘗試安裝具有非自由（proprietary）授權的套件，但 nixpkgs 預設拒絕安裝非自由軟體。

**解決：**

在 `configuration.nix` 中全域允許：

```nix
nixpkgs.config.allowUnfree = true;
```

或只允許特定套件：

```nix
nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
  "vscode"
  "zoom"
];
```

---

### D.6.2 Package 'xxx' requires 'insecure'

**錯誤訊息：**

```
error: Package 'python2-2.7.18' in /nix/store/xxx is marked as insecure,
       refusing to evaluate.

       Known issues:
        - Python 2.7 has reached its end of life after 2020-01-01. See https://...
```

**原因：**

嘗試安裝已知存在安全問題（EOL、CVE 等）的套件。

**解決：**

```nix
# 允許特定不安全套件（請了解風險後再使用）
nixpkgs.config.permittedInsecurePackages = [
  "python-2.7.18.8"
];
```

---

### D.6.3 collision between 'xxx' and 'yyy'

**錯誤訊息：**

```
error: collision between `/nix/store/xxx-openssl-3.0/bin/openssl'
       and `/nix/store/yyy-openssl-1.1/bin/openssl'
```

**原因：**

兩個套件安裝了相同路徑的檔案，Nix 無法建立一致的環境。

**解決：**

1. 找出衝突的套件並移除其中一個
2. 若需要同時使用兩個版本，改用 `nix-shell` 或 `nix shell` 建立隔離環境：

```bash
# 只在 shell 中使用特定版本，不安裝到系統
nix shell nixpkgs#openssl_1_1
```

3. 若是在 `environment.systemPackages` 中，檢查是否意外加入了相同套件的不同版本

---

## D.7 網路與遠端部署錯誤

---

### D.7.1 ssh: Connection refused

**錯誤訊息：**

```
ssh: connect to host 192.168.1.100 port 22: Connection refused
error: cannot connect to 'ssh://user@192.168.1.100'
```

**原因：**

目標主機的 SSH 服務未啟動，或防火牆封鎖了 22 埠。

**解決：**

在目標主機上確認 SSH 已啟用：

```nix
# configuration.nix（目標主機）
services.openssh.enable = true;
networking.firewall.allowedTCPPorts = [ 22 ];
```

或：

```bash
# 在目標主機上手動啟動
sudo systemctl start sshd
sudo systemctl enable sshd
```

---

### D.7.2 sudo: a password is required

**錯誤訊息：**

```
sudo: a password is required
error: remote deployment failed
```

**原因：**

遠端部署時（如 `nixos-rebuild --target-host`），需要在目標主機執行 sudo，但 sudo 要求密碼，而自動化腳本無法輸入密碼。

**解決：**

在目標主機配置 sudoers 允許免密碼：

```nix
# 目標主機的 configuration.nix
security.sudo.extraRules = [{
  users = [ "deploy-user" ];
  commands = [{
    command = "ALL";
    options = [ "NOPASSWD" ];
  }];
}];
```

或使用 SSH 金鑰認證並配置 `NOPASSWD`。

---

### D.7.3 error: opening file '/nix/var/nix/daemon-socket/socket'

**錯誤訊息：**

```
error: opening file '/nix/var/nix/daemon-socket/socket': No such file or directory
```

**原因：**

nix-daemon 未運行。這在單機環境中不常見，但在新安裝或系統異常後可能發生。

**解決：**

```bash
# 啟動 nix-daemon
sudo systemctl start nix-daemon.service

# 設定開機自動啟動
sudo systemctl enable nix-daemon.service

# 確認狀態
systemctl status nix-daemon.service
```

---

## D.8 Home Manager 錯誤

---

### D.8.1 Existing file '...' is in the way of 'xxx'

**錯誤訊息：**

```
Error: Existing file '/home/user/.config/fish/config.fish' is in the way of
'/nix/store/xxx-home-manager-files/.config/fish/config.fish'.
Please move the file and try again.
```

**原因：**

Home Manager 嘗試建立一個 symlink，但目標位置已存在由其他方式建立的普通檔案。

**解決：**

方法一：手動備份並移除衝突的檔案：

```bash
mv ~/.config/fish/config.fish ~/.config/fish/config.fish.bak
home-manager switch  # 重新執行
```

方法二：使用 `home-manager` 的備份選項：

```bash
home-manager switch -b bak  # 自動將衝突檔案備份為 .bak
```

方法三（若確認原檔案不需要）：

```bash
rm ~/.config/fish/config.fish
home-manager switch
```

---

### D.8.2 The home-manager configuration has errors

**錯誤訊息：**

```
Error: The home-manager configuration has errors, please fix them and try again:
       The option `programs.unknown-program.enable' does not exist.
```

**原因：**

Home Manager 配置中存在錯誤，通常是 option 路徑不正確，或使用了不存在的 Home Manager option。

**解決：**

1. 查閱 Home Manager option 文件：[https://nix-community.github.io/home-manager/options.xhtml](https://nix-community.github.io/home-manager/options.xhtml)
2. 確認 Home Manager 版本是否支援該 option（較新的 option 可能只在新版 Home Manager 中存在）
3. 更新 Home Manager：

```bash
# 若使用 flake
nix flake update home-manager
```

---

### D.8.3 Module '...' does not exist

**錯誤訊息：**

```
error: module '/home/user/config/home/missing-module.nix' does not exist
```

**原因：**

Home Manager 配置的 `imports` 列表中引用了不存在的模組檔案。

**解決：**

```bash
# 確認檔案存在
ls /home/user/config/home/missing-module.nix

# 若路徑錯誤，修正 imports 中的路徑
# 若檔案確實不存在，建立它或移除 import
```

---

## D.9 快速診斷流程

當你遇到 NixOS 問題但不確定從哪裡開始時，按照以下流程逐步縮小問題範圍。

---

### 流程一：nixos-rebuild switch 失敗

```
nixos-rebuild switch 失敗
         |
         v
    [1] 是 Evaluation Error？
    （訊息含 "error: ..." 且沒有 "building" 字樣）
         |是                          |否
         v                            v
    → 到 D.1 / D.2               [2] 是 Build Error？
      查閱對應錯誤                （訊息含 "builder for ... failed"）
                                       |是                    |否
                                       v                      v
                                  → 看完整 log          [3] 是 Activation Error？
                                    nix log <drv>        （服務啟動失敗）
                                    → 到 D.3                  |是
                                                              v
                                                         → journalctl -xe
                                                           systemctl status <svc>
                                                           → 到 D.4
```

---

### 流程二：服務啟動失敗的診斷步驟

```
步驟 1   systemctl status <服務名稱>
          → 查看 Active 狀態和最後幾行日誌

步驟 2   journalctl -u <服務名稱> -n 50
          → 查看服務的詳細日誌（最近 50 行）

步驟 3   journalctl -xe
          → 查看系統層級的錯誤事件

步驟 4   systemctl cat <服務名稱>
          → 查看服務的 unit 檔案定義

步驟 5   （視服務類型）手動執行服務的指令
          → 例如 nginx -t 測試配置，或直接執行二進制檔案

步驟 6   確認相關檔案/目錄存在且許可權正確
          ls -la /var/lib/<服務>
          ls -la /etc/<服務>
```

---

### 流程三：Nix 求值錯誤的通用診斷

```bash
# 測試配置是否可以求值（不實際建置）
nix eval .#nixosConfigurations.myHost.config.system.build.toplevel

# 列出配置的所有 option（用於確認 option 是否存在）
nixos-option services.nginx

# 詳細輸出（顯示完整的 Nix 評估過程）
nixos-rebuild dry-build --show-trace 2>&1 | head -100
```

---

### 常用日誌查詢指令速覽

| 目的 | 指令 |
|---|---|
| 查看啟動錯誤 | `journalctl -b -p err` |
| 追蹤特定服務 | `journalctl -u <service> -f` |
| 查看建置日誌 | `nix log <.drv 路徑>` |
| 查看系統切換日誌 | `journalctl -u nixos-activation` |
| 查看所有啟動日誌 | `journalctl -b` |
| 查看上次啟動日誌 | `journalctl -b -1` |
| 查看 nix-daemon 日誌 | `journalctl -u nix-daemon` |

---

### 緊急回滾

若新配置導致系統無法使用，可在 GRUB 選單選擇舊版系統，或執行：

```bash
# 切換到上一個世代
sudo nixos-rebuild switch --rollback

# 列出所有世代
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# 切換到指定世代
sudo nix-env --switch-generation <N> --profile /nix/var/nix/profiles/system
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

---

*如需查詢本附錄未列出的錯誤，可參考：*

- *NixOS Discourse 論壇：[https://discourse.nixos.org](https://discourse.nixos.org)*
- *nixpkgs GitHub Issues：[https://github.com/NixOS/nixpkgs/issues](https://github.com/NixOS/nixpkgs/issues)*
- *NixOS Wiki：[https://wiki.nixos.org](https://wiki.nixos.org)*
