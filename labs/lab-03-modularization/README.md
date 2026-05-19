# Lab 3：撰寫第一個自訂 Module

**對應章節：** 第 6–7 章

---

## 目標

完成本 Lab 後，你將能夠：

- 理解 options 宣告和 config 實作的分離原則
- 撰寫帶有 `mkEnableOption` 和 `mkOption` 的 NixOS 模組
- 使用 `lib.mkIf` 實作條件配置
- 加入 `assertions` 驗證配置合法性
- 設計可供他人重用的模組介面

---

## 前置要求

- 完成 Lab 2（已有模組化配置，目錄結構如 `/etc/nixos/modules/`）
- 完成第 6、7 章閱讀
- 了解 `lib.mkEnableOption`、`lib.mkOption`、`lib.mkIf` 的基本概念

---

## 建議環境

- 一台已安裝 NixOS（版本 25.05）的機器或虛擬機
- 具備 `sudo` 權限的使用者（本 Lab 以 `alice` 為例）
- 文字編輯器（vim、neovim 或 nano）

---

## Part 1：理解 options/config 分離

### 為什麼需要 options？

NixOS 模組有兩種寫法：

**寫法一：直接設定值（無 options）**

```nix
# packages.nix（Lab 2 建立的簡單模組）
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    curl
    ripgrep
  ];
}
```

這種寫法很直白，但有一個限制：**使用者無法「開關」它**。只要這個模組被 import，這些套件就一定會被安裝。

**寫法二：宣告 options，再用 config 回應**

```nix
{ config, pkgs, lib, ... }:
{
  options.my.devTools = {
    enable = lib.mkEnableOption "development tools";
  };

  config = lib.mkIf config.my.devTools.enable {
    environment.systemPackages = with pkgs; [ git curl ripgrep ];
  };
}
```

這種寫法讓使用這個模組的人可以自行決定「要不要啟用」。

---

### Step 1：觀察現有的配置模式

先看看 Lab 2 建立的簡單模組長什麼樣子。

**指令：**

```bash
cat /etc/nixos/modules/packages.nix
```

**預期結果：**

你應該看到類似下面的內容，直接設定了套件，沒有 `options` 區塊：

```nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    curl
    # ...
  ];
}
```

**重點觀察：**

這個模組沒有「啟用開關」。如果你有一台桌面工作站和一台伺服器，兩台都 import 這個模組，兩台就都會安裝同樣的套件。

如果你想「只在桌面工作站上安裝開發工具」，就需要 options。

---

### Step 2：建立帶有 options 的模組骨架

先確認模組目錄存在。

**指令：**

```bash
ls /etc/nixos/modules/
```

**預期結果：**

列出 Lab 2 建立的模組檔案，例如 `packages.nix`、`users.nix` 等。

接著建立新模組檔案：

**指令：**

```bash
sudo vim /etc/nixos/modules/dev-tools.nix
```

**先輸入最簡單的骨架：**

```nix
{ config, pkgs, lib, ... }:

{
  options.my.devTools = {
    enable = lib.mkEnableOption "development tools";
  };

  config = lib.mkIf config.my.devTools.enable {
    environment.systemPackages = [ pkgs.git ];
  };
}
```

**儲存並離開編輯器（`:wq`）。**

**這個骨架做了什麼？**

| 區塊 | 作用 |
|---|---|
| `options.my.devTools.enable` | 宣告一個可以被外部設定的開關 |
| `lib.mkEnableOption` | 建立標準的 bool option，預設為 `false` |
| `lib.mkIf config.my.devTools.enable` | 只有當 `enable = true` 時，才套用 config |
| `config = { ... }` | 實際影響系統的設定都放在這裡 |

> **關鍵概念：** `options` 是「模組對外宣告它接受什麼設定」，`config` 是「根據這些設定決定要做什麼」。這兩個區塊的分離，是 NixOS 模組系統的核心設計。

---

## Part 2：撰寫完整的開發環境模組

骨架只是開始。現在把它擴充成一個真正實用的模組。

---

### Step 3：定義完整的 options

重新編輯模組，加入完整的 options 定義。

**指令：**

```bash
sudo vim /etc/nixos/modules/dev-tools.nix
```

**將檔案內容全部替換為以下內容（只寫到 options 部分，config 留到下一步）：**

```nix
{ config, pkgs, lib, ... }:

{
  options.my.devTools = {

    # 主開關：是否啟用這個開發工具模組
    enable = lib.mkEnableOption "development tools";

    # 是否安裝 GUI 編輯器
    enableGui = lib.mkOption {
      type        = lib.types.bool;
      default     = false;
      description = "Whether to install GUI editors (VS Code).";
    };

    # 選擇終端機編輯器
    editor = lib.mkOption {
      type        = lib.types.enum [ "vim" "neovim" "nano" ];
      default     = "neovim";
      description = "The terminal editor to install.";
    };

    # 要安裝的程式語言工具
    languages = lib.mkOption {
      type        = lib.types.listOf (lib.types.enum [ "python" "rust" "go" "nodejs" ]);
      default     = [];
      description = "Programming language toolchains to install.";
      example     = [ "python" "rust" ];
    };

    # 額外套件（讓使用者自由擴充）
    extraPackages = lib.mkOption {
      type        = lib.types.listOf lib.types.package;
      default     = [];
      description = "Additional packages to install in the dev environment.";
      example     = lib.literalExpression "[ pkgs.jq pkgs.httpie ]";
    };

  };

  # config 部分將在 Step 4 加入

}
```

**儲存（`:wq`）。**

**設計說明：**

**為什麼 `editor` 用 `lib.types.enum`？**

`enum` 限制了使用者只能輸入 `"vim"`、`"neovim"`、或 `"nano"` 三者之一。如果輸入了 `"emacs"`，nixos-rebuild 會在套用配置前就報錯，避免安裝到不存在的套件對應邏輯。

**為什麼 `languages` 預設是空列表 `[]`？**

語言工具通常佔用較多空間（例如 Rust 的 `rustup` 加上工具鏈）。預設不安裝，讓使用者明確選擇需要的語言，避免不必要的系統膨脹。

**為什麼要有 `extraPackages`？**

模組不可能預先知道每個使用者的所有需求。`extraPackages` 讓模組在設計完整的同時，保留彈性給使用者自行添加。這是「封閉中有開放」的常見設計模式。

---

### Step 4：實作 config

繼續編輯模組，加入 config 部分。

**指令：**

```bash
sudo vim /etc/nixos/modules/dev-tools.nix
```

**將整個檔案替換為完整版本：**

```nix
{ config, pkgs, lib, ... }:

{
  options.my.devTools = {

    enable = lib.mkEnableOption "development tools";

    enableGui = lib.mkOption {
      type        = lib.types.bool;
      default     = false;
      description = "Whether to install GUI editors (VS Code).";
    };

    editor = lib.mkOption {
      type        = lib.types.enum [ "vim" "neovim" "nano" ];
      default     = "neovim";
      description = "The terminal editor to install.";
    };

    languages = lib.mkOption {
      type        = lib.types.listOf (lib.types.enum [ "python" "rust" "go" "nodejs" ]);
      default     = [];
      description = "Programming language toolchains to install.";
      example     = [ "python" "rust" ];
    };

    extraPackages = lib.mkOption {
      type        = lib.types.listOf lib.types.package;
      default     = [];
      description = "Additional packages to install in the dev environment.";
      example     = lib.literalExpression "[ pkgs.jq pkgs.httpie ]";
    };

  };

  # ──────────────────────────────────────────────
  # config：只有在 enable = true 時才生效
  # ──────────────────────────────────────────────
  config = lib.mkIf config.my.devTools.enable (
    let
      cfg = config.my.devTools;

      # 根據使用者選擇的編輯器，對應到實際套件
      editorPkg = {
        vim    = pkgs.vim;
        neovim = pkgs.neovim;
        nano   = pkgs.nano;
      }.${cfg.editor};

      # 根據使用者選擇的語言，組合出套件清單
      langPackages = lib.concatLists [
        (lib.optional (lib.elem "python" cfg.languages)
          (with pkgs; [ python3 python3Packages.pip ]))
        (lib.optional (lib.elem "rust"   cfg.languages)
          (with pkgs; [ rustup cargo ]))
        (lib.optional (lib.elem "go"     cfg.languages)
          [ pkgs.go ])
        (lib.optional (lib.elem "nodejs" cfg.languages)
          (with pkgs; [ nodejs nodePackages.npm ]))
      ];

      # GUI 套件（只有 enableGui = true 時才加入）
      guiPackages = lib.optionals cfg.enableGui [ pkgs.vscode ];

    in
    {
      environment.systemPackages =
        [ editorPkg pkgs.git pkgs.curl pkgs.ripgrep ]
        ++ langPackages
        ++ guiPackages
        ++ cfg.extraPackages;

      programs.git.enable = true;
    }
  );
}
```

**儲存（`:wq`）。**

**逐行解說關鍵函式：**

**`let cfg = config.my.devTools;`**

把 `config.my.devTools` 存進短名稱 `cfg`，避免後面反覆輸入完整路徑。這是 NixOS 模組的慣例寫法。

**`lib.concatLists [ ... ]`**

接受一個「列表的列表」，把它們全部展開合併成單一列表。

```
lib.concatLists [ [a b] [c] [d e] ]
→ [a b c d e]
```

**`lib.optional <條件> <值>`**

如果條件為 `true`，回傳 `[ 值 ]`（包含一個元素的列表）。  
如果條件為 `false`，回傳 `[]`（空列表）。

```
lib.optional true  pkgs.git   → [ pkgs.git ]
lib.optional false pkgs.vscode → []
```

**`lib.optionals <條件> <列表>`**

和 `lib.optional` 類似，但接受的是整個列表，而不是單一值。

```
lib.optionals true  [ pkgs.vscode pkgs.electron ] → [ pkgs.vscode pkgs.electron ]
lib.optionals false [ pkgs.vscode pkgs.electron ] → []
```

**`lib.elem "python" cfg.languages`**

檢查 `"python"` 是否存在於 `cfg.languages` 列表中。回傳 `true` 或 `false`。

**`.${cfg.editor}` 的 Attribute Set 查詢**

```nix
editorPkg = {
  vim    = pkgs.vim;
  neovim = pkgs.neovim;
  nano   = pkgs.nano;
}.${cfg.editor};
```

這是用 attribute set（屬性集合）做「字串到值的對應表」的慣用寫法。`cfg.editor` 是 `"vim"`、`"neovim"` 或 `"nano"` 其中之一，所以查詢必定成功。因為 `enum` 已確保值的範圍，這裡不需要額外的防護。

---

### Step 5：在 configuration.nix 中使用這個模組

先把模組加入 imports，再設定 options。

**指令：**

```bash
sudo vim /etc/nixos/configuration.nix
```

**場景一：桌面工作站（alice 的主力開發機）**

```nix
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/packages.nix   # Lab 2 建立的模組
    ./modules/dev-tools.nix  # 剛建立的模組
  ];

  # 啟用開發工具
  my.devTools.enable       = true;
  my.devTools.editor       = "neovim";
  my.devTools.languages    = [ "python" "rust" ];
  my.devTools.enableGui    = true;
  my.devTools.extraPackages = with pkgs; [ jq httpie ];

  # 其他系統設定
  networking.hostName = "alice-desktop";
  time.timeZone       = "Asia/Taipei";

  users.users.alice = {
    isNormalUser = true;
    extraGroups  = [ "wheel" ];
  };

  system.stateVersion = "25.05";
}
```

**場景二：輕量級伺服器（只需要最小工具）**

```nix
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/dev-tools.nix
  ];

  # 同一個模組，但只選最精簡的配置
  my.devTools.enable    = true;
  my.devTools.editor    = "vim";
  my.devTools.languages = [ "python" ];
  # enableGui 預設是 false，不需要寫，VS Code 不會被安裝
  # extraPackages 預設是 []，不需要寫

  networking.hostName = "alice-server";
  time.timeZone       = "Asia/Taipei";

  system.stateVersion = "25.05";
}
```

**場景三：完全不啟用開發工具（例如嵌入式裝置）**

```nix
# 只要 import 模組，但不設定 enable = true
# 模組的 config 區塊完全不會生效
my.devTools.enable = false;  # 或直接省略這一行（預設就是 false）
```

> **重點：** 三台機器 import 了同一個 `dev-tools.nix`，但得到完全不同的結果。這就是 options 帶來的彈性。

---

### Step 6：驗證模組運作

先做語法檢查，確認沒有錯誤再套用。

**Step 6-1：語法與配置檢查**

**指令：**

```bash
sudo nixos-rebuild dry-run
```

**預期結果：**

輸出訊息中沒有 `error:`。你可能會看到列出將要安裝的套件，但不會實際套用。

如果出現錯誤，先看「常見問題」章節再繼續。

**Step 6-2：套用配置**

**指令：**

```bash
sudo nixos-rebuild switch
```

**預期結果：**

終端機顯示類似下面的訊息，最後沒有錯誤：

```
building the system configuration...
activating the configuration...
setting up /etc...
```

**Step 6-3：驗證已安裝的工具**

根據你在 Step 5 設定的 `editor` 選擇對應指令：

```bash
# 如果 editor = "neovim"
nvim --version

# 如果 editor = "vim"
vim --version

# 如果 editor = "nano"
nano --version
```

**預期結果：** 顯示版本號，例如 `NVIM v0.9.x`。

```bash
# Git 應該總是可用
git --version
```

**預期結果：** 顯示 `git version 2.x.x`。

```bash
# 如果設定了 languages = [ "python" ... ]
python3 --version

# 如果設定了 languages = [ ... "rust" ]
rustup --version
```

**預期結果：** 顯示各自的版本號。

**Step 6-4：用 nixos-option 查詢 option 的值**

**指令：**

```bash
nixos-option my.devTools.enable
```

**預期結果：**

```
Value:
true

Default:
false

Description:
Whether to enable development tools.
```

```bash
nixos-option my.devTools.editor
```

**預期結果：**

```
Value:
"neovim"
```

---

## Part 3：擴充模組功能

---

### Step 7：加入更多 options（引導練習）

這一步由你自己動手完成。目標是加入一個 `gitUserName` option。

**任務描述：**

在 `options.my.devTools` 區塊中新增：

```nix
gitUserName = lib.mkOption {
  type        = lib.types.nullOr lib.types.str;
  default     = null;
  description = "Git global user.name to configure. Set to null to skip.";
};
```

接著在 `config` 的 `in { ... }` 區塊中加入：

```nix
programs.git.config = lib.mkIf (cfg.gitUserName != null) {
  user.name = cfg.gitUserName;
};
```

然後在 `configuration.nix` 中加入：

```nix
my.devTools.gitUserName = "Alice Chen";
```

**驗證：**

```bash
sudo nixos-rebuild switch
git config --global user.name
```

**預期結果：** 顯示 `Alice Chen`。

**`lib.types.nullOr` 的含義：**

`lib.types.nullOr lib.types.str` 表示這個 option 可以接受 `null` 或一個字串。當值是 `null` 時，代表使用者沒有設定，我們就跳過相關配置。這是 NixOS 模組中表示「可選設定」的標準做法。

---

### Step 8：加入 assertions 驗證

assertions（斷言）讓模組在 rebuild 前就能主動檢查配置是否合理，並給出清楚的錯誤訊息。

**問題場景：**

如果使用者在沒有桌面環境的伺服器上設定 `enableGui = true`，VS Code 會被安裝，但完全無法啟動。使用者可能不知道原因在哪。

**加入 assertions 後，rebuild 時就會直接告訴使用者問題所在。**

**指令：**

```bash
sudo vim /etc/nixos/modules/dev-tools.nix
```

在 `config = lib.mkIf config.my.devTools.enable (` 後、`let` 區塊之前，加入 `assertions`：

```nix
config = lib.mkIf config.my.devTools.enable (
  let
    cfg = config.my.devTools;
    # ... 其他 let 定義
  in
  {
    # ── assertions：提前攔截不合理的配置 ──
    assertions = [
      {
        assertion = !(cfg.enableGui && !config.services.xserver.enable);
        message   = ''
          my.devTools.enableGui = true 需要桌面環境支援。
          請加入 services.xserver.enable = true，
          或將 my.devTools.enableGui 改為 false。
        '';
      }
    ];

    # ── 其他配置保持不變 ──
    environment.systemPackages =
      [ editorPkg pkgs.git pkgs.curl pkgs.ripgrep ]
      ++ langPackages
      ++ guiPackages
      ++ cfg.extraPackages;

    programs.git.enable = true;
  }
);
```

**測試 assertion（選做）：**

臨時在 `configuration.nix` 設定：

```nix
my.devTools.enableGui = true;
# 確保 services.xserver.enable 沒有被設定為 true
```

然後執行：

```bash
sudo nixos-rebuild dry-run
```

**預期結果：** rebuild 立即中止，顯示我們寫的錯誤訊息，而不是嘗試安裝後才失敗。

**assertions 的設計原則：**

- `assertion` 是一個布林值（Nix 表達式），`true` 代表「配置合法」，`false` 代表「配置有問題」。
- `message` 是錯誤訊息字串，盡量說明「要怎麼修正」，而不只是說「有錯誤」。
- 一個模組可以有多條 assertions，NixOS 會在 rebuild 時全部檢查。

---

## 驗證清單

完成本 Lab 後，以下所有項目應該都能正常運作：

| 驗證項目 | 指令 | 預期結果 |
|---|---|---|
| 模組語法正確 | `sudo nixos-rebuild dry-run` | 無 `error:` 輸出 |
| 配置套用成功 | `sudo nixos-rebuild switch` | 正常結束，無錯誤 |
| 已安裝的編輯器 | `nvim --version`（或 `vim`/`nano`）| 顯示版本號 |
| Git 可用 | `git --version` | 顯示 `git version 2.x.x` |
| Option 值查詢 | `nixos-option my.devTools.enable` | 顯示 `true` |
| Python（如已選）| `python3 --version` | 顯示 `Python 3.x.x` |
| Rust（如已選）| `rustup --version` | 顯示版本號 |
| Go（如已選）| `go version` | 顯示 `go version go1.x.x` |
| Node.js（如已選）| `node --version` | 顯示 `v20.x.x` |
| Git 使用者名稱（Step 7）| `git config --global user.name` | 顯示設定的名稱 |

---

## 常見問題

### 1. `error: undefined variable 'lib'`

**原因：** 模組的函式簽名漏掉了 `lib` 參數。

**錯誤寫法：**

```nix
{ config, pkgs, ... }:
```

**正確寫法：**

```nix
{ config, pkgs, lib, ... }:
```

NixOS 模組必須明確在函式參數中宣告它要使用的輸入。`lib` 不會自動注入，忘記加就會找不到。

---

### 2. `The option 'my.devTools' does not exist`

**原因：** 模組沒有被加入 `imports` 清單。

**檢查 configuration.nix：**

```bash
grep -n "dev-tools" /etc/nixos/configuration.nix
```

如果沒有輸出，代表你忘記把模組加入 imports。

**修正：**

```nix
imports = [
  ./hardware-configuration.nix
  ./modules/dev-tools.nix   # ← 確保這一行存在
];
```

---

### 3. `value "emacs" is not of type 'enum ["vim" "neovim" "nano"]'`

**原因：** `editor` 設定了不在 `enum` 範圍內的值。

**正確的值只有三個：**

```nix
my.devTools.editor = "vim";    # ✓
my.devTools.editor = "neovim"; # ✓
my.devTools.editor = "nano";   # ✓
my.devTools.editor = "emacs";  # ✗ 會報錯
```

如果你想支援更多編輯器，需要回到 `dev-tools.nix` 修改 `enum` 的列表，並在 `editorPkg` 的 attribute set 中加入對應的套件。

---

### 4. `infinite recursion encountered`

**原因：** 在 `options` 定義中不小心參照到 `config`，或在 `config` 中自我循環參照。

**常見錯誤模式：**

```nix
options.my.devTools = {
  packages = lib.mkOption {
    default = config.environment.systemPackages;  # ✗ 不能在 options 中用 config
    # ...
  };
};
```

**修正原則：** `options` 區塊只能定義型別（type）、預設值（default）、描述（description）等靜態資訊。所有需要讀取 `config` 的邏輯，都必須放在 `config` 區塊裡。

---

### 5. `assertion failed` 但不確定原因

**指令：**

```bash
sudo nixos-rebuild dry-run 2>&1 | grep -A 5 "assertion"
```

這會顯示觸發的 assertion 以及我們寫的 `message`，根據訊息修正配置即可。

---

## 延伸練習

完成以下練習，加深對 NixOS 模組設計的理解：

### 練習 1：Shell 環境 option

在 `dev-tools.nix` 中新增一個 `shellEnv` option：

```nix
shellEnv = lib.mkOption {
  type    = lib.types.enum [ "bash" "zsh" "fish" ];
  default = "bash";
  description = "The default shell for alice.";
};
```

在 `config` 中根據設定，把 alice 的 shell 設定為對應程式：

```nix
users.users.alice.shell =
  if      cfg.shellEnv == "zsh"  then pkgs.zsh
  else if cfg.shellEnv == "fish" then pkgs.fish
  else    pkgs.bash;
```

記得同時啟用對應的 program 選項（如 `programs.zsh.enable = true`）。

---

### 練習 2：Docker 支援 option

新增一個 `dockerSupport` bool option，啟用時：

1. 啟用 `virtualisation.docker.enable`
2. 把 `alice` 加入 `docker` 群組

```nix
dockerSupport = lib.mkOption {
  type    = lib.types.bool;
  default = false;
  description = "Whether to enable Docker support for alice.";
};
```

在 config 中：

```nix
virtualisation.docker.enable = lib.mkIf cfg.dockerSupport true;

users.users.alice.extraGroups =
  lib.optional cfg.dockerSupport "docker";
```

同時加入一條 assertion，確認在沒有啟用 Docker 的情況下，`dockerSupport` 不會被設為 `true`（提示：這條其實是多餘的，因為 `virtualisation.docker.enable` 會自己處理，但作為練習，試著寫出這條 assertion）。

---

### 練習 3：改變 languages 的型別

把 `languages` 的型別從：

```nix
type = lib.types.listOf (lib.types.enum [ "python" "rust" "go" "nodejs" ]);
```

改成：

```nix
type = lib.types.attrsOf lib.types.bool;
```

讓使用者這樣設定：

```nix
my.devTools.languages = {
  python = true;
  rust   = false;
  go     = true;
  nodejs = false;
};
```

然後重新實作 `config` 中 `langPackages` 的邏輯，改用 `lib.optionals cfg.languages.python [ ... ]` 的形式。

比較這兩種設計的優缺點：哪種對使用者更直觀？哪種對模組作者更容易維護？

---

### 練習 4：撰寫一個全新的 homeServer 模組

建立 `/etc/nixos/modules/home-server.nix`，包含以下 options：

| option | 型別 | 預設值 | 說明 |
|---|---|---|---|
| `enable` | bool | `false` | 主開關 |
| `enableNginx` | bool | `false` | 是否啟用 Nginx |
| `enablePostgres` | bool | `false` | 是否啟用 PostgreSQL |
| `domain` | `nullOr str` | `null` | 伺服器主網域 |

加入以下 assertion：

- 若 `enableNginx = true` 但 `domain = null`，報錯提示「設定 Nginx 需要指定 domain」。

在 config 中，根據各 option 的值，適當啟用 `services.nginx.enable`、`services.postgresql.enable`，以及設定 `networking.domain`。

---

## 小結

本 Lab 完成了一個完整的 NixOS 自訂模組，涵蓋了：

- `options` 與 `config` 的分離架構
- 常用的 option 型別：`bool`、`enum`、`listOf`、`nullOr`、`package`
- `lib.mkIf`、`lib.optional`、`lib.optionals`、`lib.concatLists`、`lib.elem` 的實際應用
- `assertions` 的設計與使用

下一步是 Lab 4，將介紹如何使用 **Flakes** 改造整個 `/etc/nixos` 目錄結構，讓配置具備版本鎖定（lock file）與更嚴格的可重現性保證。
