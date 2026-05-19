# 附錄A：Nix 語言速查表

本附錄為日常使用的快速參考，涵蓋 Nix 語言的語法、內建函數與 nixpkgs lib 常用工具。
每個項目均附有最小可用範例，供需要時隨時查閱。

---

## A.1 基本資料型別

### 型別總覽

| 型別 | 範例 | 說明 |
|---|---|---|
| 單行字串 | `"hello world"` | 雙引號包圍，支援插值 `${...}` |
| 多行字串 | `''line1\nline2''` | 雙單引號包圍，自動去除共同縮排 |
| 整數（Integer） | `42`、`-7` | 64 位元有號整數 |
| 浮點數（Float） | `3.14`、`1.0e10` | IEEE 754 雙精度 |
| 布林值（Boolean） | `true`、`false` | 全小寫 |
| Null | `null` | 代表無值 |
| 路徑（Path） | `./file.nix`、`/abs/path`、`<nixpkgs>` | 不需引號；相對路徑相對於目前檔案 |
| URI | `https://example.com` | 不含空格的 URI 可不加引號（不推薦） |

### 字串

```nix
# 單行字串
"這是一個字串"

# 字串插值（interpolation）
let name = "NixOS"; in "Hello, ${name}!"

# 路徑轉字串
"${./config.nix}"        # → "/path/to/config.nix"（絕對路徑）

# 多行字串（leading whitespace 自動去除）
''
  第一行
  第二行
    縮排更深的行
''
# 結果：
# "第一行\n第二行\n  縮排更深的行\n"

# 多行字串中的插值
let version = "25.05"; in
''
  system.stateVersion = "${version}";
''

# 多行字串中需要輸出 '' 本身：使用 '''
''
  this has ''${"''"}'' inside
''
```

### 路徑（Path）

| 語法 | 說明 |
|---|---|
| `./relative` | 相對路徑，評估時轉為絕對路徑 |
| `/absolute/path` | 絕對路徑 |
| `<nixpkgs>` | 在 `NIX_PATH` 中查找的 channel 路徑 |
| `<nixpkgs/lib>` | channel 路徑下的子路徑 |

---

## A.2 Attribute Set（屬性集）

### 基本語法

```nix
# 建立 attribute set
{ key = "value"; number = 42; flag = true; }

# 巢狀屬性（兩種寫法等價）
{ a = { b = { c = 1; }; }; }
{ a.b.c = 1; }

# 空 attribute set
{}
```

### 操作速查表

| 操作 | 語法 | 範例 | 說明 |
|---|---|---|---|
| 存取屬性 | `set.attr` | `cfg.enable` | 靜態存取 |
| 動態存取 | `set.${varname}` | `pkgs.${name}` | 以字串變數存取 |
| 屬性存在檢查 | `set ? attr` | `cfg ? port` | 回傳 `true`/`false` |
| 存取含預設值 | `set.attr or default` | `cfg.port or 80` | 屬性不存在時回傳預設值 |
| 合併（右側覆蓋） | `setA // setB` | `defaults // overrides` | setB 中的 key 會覆蓋 setA |
| 遞迴屬性集 | `rec { ... }` | `rec { x = 1; y = x + 1; }` | 允許屬性間互相引用 |

### inherit 語法

```nix
# 從當前 scope 引入變數（等同 name = name;）
let name = "nixos"; version = "25.05"; in
{ inherit name version; }
# → { name = "nixos"; version = "25.05"; }

# 從另一個 set 引入（等同 foo = set.foo;）
{ inherit (pkgs) git curl vim; }
# → { git = pkgs.git; curl = pkgs.curl; vim = pkgs.vim; }
```

### with 語法

```nix
# with 將 set 的屬性展開到 scope 中
with pkgs; [ git curl vim ]
# 等同 [ pkgs.git pkgs.curl pkgs.vim ]

# 注意：with 不影響 let 綁定，也不建議巢狀使用
# 巢狀 with 時，外層的同名屬性會被遮蔽（shadowing）
with foo; with bar; someAttr    # bar.someAttr 優先於 foo.someAttr
```

### // 合併運算子

```nix
{ a = 1; b = 2; } // { b = 99; c = 3; }
# → { a = 1; b = 99; c = 3; }    # b 被右側覆蓋

# 常見用途：模組預設值與使用者設定合併
defaultConfig // userConfig
```

---

## A.3 List（列表）

### 基本語法

```nix
# 元素以空格分隔，不用逗號
[ 1 2 3 ]
[ "a" "b" "c" ]
[ true false true ]

# 巢狀 list
[ [1 2] [3 4] ]

# 混合型別（合法但不推薦）
[ 1 "two" true ]

# 空 list
[]
```

### List 操作

| 操作 | 語法/函數 | 範例 | 說明 |
|---|---|---|---|
| 串接 | `listA ++ listB` | `[1 2] ++ [3 4]` → `[1 2 3 4]` | 合併兩個 list |
| 長度 | `builtins.length list` | `builtins.length [1 2 3]` → `3` | |
| 第一個元素 | `builtins.head list` | `builtins.head [1 2 3]` → `1` | |
| 其餘元素 | `builtins.tail list` | `builtins.tail [1 2 3]` → `[2 3]` | |
| 取第 n 個 | `builtins.elemAt list n` | `builtins.elemAt [10 20 30] 1` → `20` | 索引從 0 開始 |
| 檢查成員 | `builtins.elem x list` | `builtins.elem 2 [1 2 3]` → `true` | |
| 對映 | `map f list` | `map (x: x * 2) [1 2 3]` → `[2 4 6]` | |
| 過濾 | `builtins.filter f list` | `builtins.filter (x: x > 2) [1 2 3]` → `[3]` | |
| 摺疊 | `builtins.foldl' f init list` | `builtins.foldl' (a: b: a + b) 0 [1 2 3]` → `6` | 嚴格求值版本 |
| 合併列表 | `builtins.concatLists lists` | `builtins.concatLists [[1 2] [3 4]]` → `[1 2 3 4]` | |
| 產生列表 | `builtins.genList f n` | `builtins.genList (i: i * 2) 3` → `[0 2 4]` | |

```nix
# 實際範例：收集套件
let
  basePkgs = with pkgs; [ git curl vim ];
  devPkgs  = with pkgs; [ gcc gnumake ];
in basePkgs ++ devPkgs
```

---

## A.4 Function（函數）

### 函數 Pattern 速查表

| Pattern | 語法 | 範例 |
|---|---|---|
| 單一參數 | `arg: body` | `x: x + 1` |
| Currying（多參數） | `a: b: body` | `a: b: a + b` |
| Attribute set 解構 | `{ x, y }: body` | `{ name, age }: "Hi, ${name}"` |
| 帶預設值 | `{ x ? default }: body` | `{ port ? 80 }: port` |
| 允許其他屬性 | `{ x, ... }: body` | `{ enable, ... }: enable` |
| @ pattern（保留整體） | `args@{ x, ... }: body` | `cfg@{ x, ... }: cfg // { y = 1; }` |

### 語法範例

```nix
# 單一參數函數
double = x: x * 2;
double 5    # → 10

# 函數呼叫：空格即呼叫，不用括號（除非需要分組）
add = a: b: a + b;
add 3 4     # → 7

# Attribute set 解構
greet = { name, greeting ? "Hello" }:
  "${greeting}, ${name}!";
greet { name = "Alice"; }              # → "Hello, Alice!"
greet { name = "Bob"; greeting = "Hi"; }  # → "Hi, Bob!"

# @ pattern：同時使用解構和整體
withExtra = args@{ name, ... }:
  args // { fullName = "Mr. ${name}"; };

# 函數作為參數（高階函數）
applyTwice = f: x: f (f x);
applyTwice (x: x + 1) 5    # → 7

# let 中定義多個函數
let
  square = x: x * x;
  cube   = x: x * x * x;
in square 3 + cube 2    # → 9 + 8 = 17
```

---

## A.5 let / in 與 rec

### let / in

```nix
# 基本語法：在 let 中定義局部變數，在 in 後使用
let
  x = 10;
  y = x + 5;     # 可以引用前面定義的變數
  greet = name: "Hello, ${name}";
in
  greet "World" + " (x=${toString x}, y=${toString y})"

# let 可巢狀
let
  a = 1;
in let
  b = a + 1;
in a + b    # → 3
```

### rec（遞迴屬性集）

```nix
# rec 允許屬性集內的屬性互相引用
rec {
  x = 1;
  y = x + 1;     # 合法，引用同集合中的 x
  z = x + y;
}
# → { x = 1; y = 2; z = 3; }

# 常見用途：定義互相依賴的路徑
rec {
  prefix   = "/usr/local";
  binDir   = "${prefix}/bin";
  libDir   = "${prefix}/lib";
}
```

### let vs rec 使用情境

| 情境 | 建議使用 |
|---|---|
| 函數內的局部計算 | `let ... in` |
| 屬性集中屬性互相依賴 | `rec { }` |
| 模組定義（`config`、`options`） | `let ... in`（避免 `rec`） |
| 需要外部傳入變數 | `let ... in` |

---

## A.6 條件與型別判斷

### if / then / else

```nix
# Nix 的 if 是表達式，必須有 else 分支
if condition then valueA else valueB

# 範例
let
  x = 10;
  result = if x > 5 then "big" else "small";
in result    # → "big"

# 多層條件
if x > 100 then "huge"
else if x > 10 then "large"
else if x > 0  then "small"
else "zero or negative"

# 常見用途：條件引入套件
environment.systemPackages = with pkgs;
  [ git curl ]
  ++ (if config.services.xserver.enable then [ firefox ] else []);
```

### assert

```nix
# assert 條件不成立時，拋出錯誤並停止評估
assert condition; expression

# 範例
let
  port = 0;
in
  assert port > 0; "Port is valid: ${toString port}"
# 若 port = 0，評估失敗並顯示錯誤

# 帶自訂訊息（搭配 builtins.trace 或直接用 throw）
assert (port > 0) || throw "port must be positive, got ${toString port}";
```

### 型別判斷函數

| 函數 | 回傳 `true` 的條件 | 範例 |
|---|---|---|
| `builtins.isNull x` | `x == null` | `builtins.isNull null` → `true` |
| `builtins.isBool x` | x 是布林值 | `builtins.isBool true` → `true` |
| `builtins.isInt x` | x 是整數 | `builtins.isInt 42` → `true` |
| `builtins.isFloat x` | x 是浮點數 | `builtins.isFloat 3.14` → `true` |
| `builtins.isString x` | x 是字串 | `builtins.isString "hi"` → `true` |
| `builtins.isList x` | x 是 list | `builtins.isList [1 2]` → `true` |
| `builtins.isAttrs x` | x 是 attribute set | `builtins.isAttrs {}` → `true` |
| `builtins.isFunction x` | x 是函數 | `builtins.isFunction (x: x)` → `true` |
| `builtins.isPath x` | x 是路徑型別 | `builtins.isPath ./foo` → `true` |
| `builtins.typeOf x` | 回傳型別字串 | `builtins.typeOf 42` → `"int"` |

---

## A.7 字串操作

### 基本操作

```nix
# 串接
"Hello" + ", " + "World"    # → "Hello, World"

# 插值
let pkg = "git"; in "Installing ${pkg}"

# 字串轉路徑（不常用，通常直接用路徑型別）
builtins.toPath "/etc/nixos"
```

### 多行字串縮排規則

```nix
# '' 字串會移除所有行共同的前置空格
''
  line one
  line two
''
# → "line one\nline two\n"

# 結尾的換行會保留；開頭換行不保留
# 若某行比最小縮排少，整個表達式報錯
```

### 常用字串 builtins

| 函數 | 簽名 | 範例 |
|---|---|---|
| `builtins.stringLength` | `string → int` | `builtins.stringLength "hello"` → `5` |
| `builtins.substring` | `int → int → string → string` | `builtins.substring 0 3 "hello"` → `"hel"` |
| `builtins.toString` | `any → string` | `builtins.toString 42` → `"42"` |
| `builtins.toJSON` | `any → string` | `builtins.toJSON { a = 1; }` → `'{"a":1}'` |
| `builtins.fromJSON` | `string → any` | `builtins.fromJSON '{"x":1}'` → `{ x = 1; }` |
| `builtins.replaceStrings` | `[string] → [string] → string → string` | `builtins.replaceStrings ["a"] ["b"] "cat"` → `"cbt"` |
| `builtins.split` | `regex → string → list` | `builtins.split ":" "a:b:c"` → `["a" [":"] "b" [":"] "c"]` |
| `builtins.concatStringsSep` | `string → [string] → string` | `builtins.concatStringsSep "," ["a" "b"]` → `"a,b"` |
| `builtins.hasContext` | `string → bool` | 字串是否含有 store path context | |
| `lib.hasPrefix` | `string → string → bool` | `lib.hasPrefix "foo" "foobar"` → `true` |
| `lib.hasSuffix` | `string → string → bool` | `lib.hasSuffix "bar" "foobar"` → `true` |
| `lib.splitString` | `string → string → [string]` | `lib.splitString ":" "a:b"` → `["a" "b"]` |

---

## A.8 常用 builtins 速查表

Nix 內建函數以 `builtins.` 前綴呼叫（部分不需前綴，如 `import`、`map`、`toString`）。

### 匯入與系統

| 函數 | 說明 | 範例 |
|---|---|---|
| `import path` | 載入並評估 Nix 檔案 | `import ./config.nix` |
| `import path args` | 載入並傳入引數 | `import ./module.nix { inherit pkgs; }` |
| `builtins.fetchurl { url; sha256; }` | 下載 URL | `builtins.fetchurl { url = "https://..."; sha256 = "..."; }` |
| `builtins.fetchGit { url; rev; }` | 抓取 Git 倉庫 | `builtins.fetchGit { url = "https://github.com/..."; rev = "abc123"; }` |
| `builtins.fetchTarball { url; sha256; }` | 下載並解壓 tarball | `builtins.fetchTarball { url = "..."; sha256 = "..."; }` |
| `builtins.currentSystem` | 目前平台字串 | `"x86_64-linux"` |
| `builtins.storeDir` | Nix store 路徑 | `"/nix/store"` |
| `builtins.nixVersion` | Nix 版本字串 | `"2.18.1"` |

### 檔案系統

| 函數 | 說明 | 範例 |
|---|---|---|
| `builtins.readFile path` | 讀取檔案為字串 | `builtins.readFile ./secret.txt` |
| `builtins.readDir path` | 讀取目錄內容 | `builtins.readDir ./modules` → `{ "foo.nix" = "regular"; }` |
| `builtins.pathExists path` | 檢查路徑是否存在 | `builtins.pathExists ./optional.nix` |
| `builtins.toPath string` | 字串轉路徑型別 | `builtins.toPath "/etc/nixos"` |
| `builtins.toString path` | 路徑轉字串 | `builtins.toString ./foo` |

### Attribute Set 操作

| 函數 | 說明 | 範例 |
|---|---|---|
| `builtins.attrNames set` | 取得所有 key（排序後） | `builtins.attrNames { b=2; a=1; }` → `["a" "b"]` |
| `builtins.attrValues set` | 取得所有 value（key 排序後） | `builtins.attrValues { a=1; b=2; }` → `[1 2]` |
| `builtins.hasAttr "key" set` | 檢查 key 是否存在 | `builtins.hasAttr "port" cfg` |
| `builtins.getAttr "key" set` | 動態取得 value | `builtins.getAttr "port" cfg` |
| `builtins.removeAttrs set [keys]` | 移除指定 key | `builtins.removeAttrs cfg ["_internal"]` |
| `builtins.mapAttrs f set` | 對每個 value 套用函數 | `builtins.mapAttrs (k: v: v + 1) { a=1; b=2; }` |
| `builtins.filterAttrs f set` | 過濾 attribute | `builtins.filterAttrs (k: v: v > 1) { a=1; b=2; }` → `{ b=2; }` |
| `builtins.listToAttrs [{name;value}]` | List 轉 attribute set | `builtins.listToAttrs [{name="a";value=1;}]` → `{ a=1; }` |
| `builtins.intersectAttrs` | 取兩 set 的交集 key | `builtins.intersectAttrs { a=0; } { a=1; b=2; }` → `{ a=1; }` |

### List 操作

| 函數 | 說明 | 範例 |
|---|---|---|
| `map f list` | 對映 | `map (x: x*2) [1 2 3]` → `[2 4 6]` |
| `builtins.filter f list` | 過濾 | `builtins.filter (x: x>1) [1 2 3]` → `[2 3]` |
| `builtins.foldl' f init list` | 左摺疊（嚴格） | `builtins.foldl' (a: b: a+b) 0 [1 2 3]` → `6` |
| `builtins.concatLists lists` | 展平一層 | `builtins.concatLists [[1 2][3 4]]` → `[1 2 3 4]` |
| `builtins.concatMap f list` | 對映後展平 | `builtins.concatMap (x: [x x]) [1 2]` → `[1 1 2 2]` |
| `builtins.length list` | 長度 | `builtins.length [1 2 3]` → `3` |
| `builtins.head list` | 第一個元素 | `builtins.head [1 2 3]` → `1` |
| `builtins.tail list` | 去掉第一個元素 | `builtins.tail [1 2 3]` → `[2 3]` |
| `builtins.elem x list` | 成員檢查 | `builtins.elem 2 [1 2 3]` → `true` |
| `builtins.elemAt list n` | 取第 n 個（0-indexed） | `builtins.elemAt [10 20 30] 1` → `20` |
| `builtins.genList f n` | 產生長度 n 的 list | `builtins.genList (i: i*2) 3` → `[0 2 4]` |
| `builtins.sort f list` | 排序（f 為比較函數） | `builtins.sort (a: b: a < b) [3 1 2]` → `[1 2 3]` |
| `builtins.partition f list` | 依條件分割 | `builtins.partition (x: x>2) [1 2 3]` → `{ right=[3]; wrong=[1 2]; }` |

### 求值控制與除錯

| 函數 | 說明 | 範例 |
|---|---|---|
| `builtins.seq x y` | 先強制求值 x，再回傳 y | `builtins.seq (assert x>0; x) result` |
| `builtins.deepSeq x y` | 深度強制求值 x，再回傳 y | `builtins.deepSeq bigSet result` |
| `builtins.tryEval expr` | 捕獲求值錯誤 | `builtins.tryEval (1/0)` → `{ success=false; value=false; }` |
| `builtins.trace msg value` | 印出訊息並回傳 value（除錯用） | `builtins.trace "x = ${toString x}" x` |
| `builtins.traceVerbose msg value` | 僅在 `--trace-verbose` 時印出 | |
| `throw string` | 拋出錯誤，終止求值 | `throw "unsupported platform"` |
| `abort string` | 中止 Nix 評估（與 throw 類似） | `abort "fatal error"` |

### JSON / TOML

| 函數 | 說明 | 範例 |
|---|---|---|
| `builtins.toJSON value` | Nix value → JSON 字串 | `builtins.toJSON { a = [1 2]; }` |
| `builtins.fromJSON string` | JSON 字串 → Nix value | `builtins.fromJSON '{"x":1}'` |
| `builtins.fromTOML string` | TOML 字串 → Nix value | `builtins.fromTOML (builtins.readFile ./config.toml)` |
| `builtins.toXML value` | Nix value → XML 字串（除錯用） | |

---

## A.9 nixpkgs lib 常用函數

`lib` 通常透過 `{ lib, ... }:` 引入，或從 `pkgs.lib` 取得。

### 模組選項建構（lib.mk\*）

| 函數 | 說明 | 範例 |
|---|---|---|
| `lib.mkOption { }` | 定義模組選項 | 見下方範例 |
| `lib.mkEnableOption "desc"` | 建立 `enable` 布林選項（預設 false） | `lib.mkEnableOption "nginx web server"` |
| `lib.mkIf condition value` | 條件式設定（condition 為 false 時不套用） | `lib.mkIf config.services.nginx.enable { ... }` |
| `lib.mkMerge [sets]` | 合併多個模組設定（比 `//` 更安全） | `lib.mkMerge [ baseConfig extraConfig ]` |
| `lib.mkDefault value` | 設定優先度較低的預設值 | `lib.mkDefault "en_US.UTF-8"` |
| `lib.mkForce value` | 強制覆蓋其他設定（最高優先） | `lib.mkForce true` |
| `lib.mkOverride priority value` | 自訂優先度（1000=default, 50=force） | `lib.mkOverride 900 "custom"` |

```nix
# mkOption 完整範例
options.services.myApp = {
  enable = lib.mkEnableOption "my application";
  port = lib.mkOption {
    type    = lib.types.port;
    default = 8080;
    description = "Port to listen on";
  };
  settings = lib.mkOption {
    type    = lib.types.attrsOf lib.types.str;
    default = {};
    example = { key = "value"; };
  };
};
```

### lib.types 常用型別

| 型別 | 說明 |
|---|---|
| `lib.types.str` | 任意字串 |
| `lib.types.nonEmptyStr` | 非空字串 |
| `lib.types.int` | 整數 |
| `lib.types.port` | 1–65535 的整數 |
| `lib.types.bool` | 布林值 |
| `lib.types.float` | 浮點數 |
| `lib.types.path` | 路徑 |
| `lib.types.package` | Nix 套件 |
| `lib.types.listOf t` | 元素型別為 t 的 list |
| `lib.types.attrsOf t` | 值型別為 t 的 attribute set |
| `lib.types.nullOr t` | t 或 null |
| `lib.types.either t1 t2` | t1 或 t2 |
| `lib.types.enum [values]` | 列舉值 |
| `lib.types.lines` | 多行字串（各來源以換行合併） |
| `lib.types.commas` | 逗號分隔字串 |
| `lib.types.submodule { options; }` | 子模組（帶自己的 options） |

### 條件輔助函數

| 函數 | 說明 | 範例 |
|---|---|---|
| `lib.optional cond x` | cond 為 true 時回傳 `[x]`，否則 `[]` | `lib.optional cfg.enable pkgs.git` |
| `lib.optionals cond list` | cond 為 true 時回傳 list，否則 `[]` | `lib.optionals isLinux [ pkgs.iproute2 ]` |
| `lib.optionalString cond str` | cond 為 true 時回傳 str，否則 `""` | `lib.optionalString cfg.debug "-v"` |
| `lib.optionalAttrs cond attrs` | cond 為 true 時回傳 attrs，否則 `{}` | `lib.optionalAttrs isArm { ... }` |

### lib.strings 常用函數

| 函數 | 說明 | 範例 |
|---|---|---|
| `lib.concatStringsSep sep list` | 以 sep 串接字串 list | `lib.concatStringsSep "," ["a" "b"]` → `"a,b"` |
| `lib.concatMapStringsSep sep f list` | 對映後以 sep 串接 | `lib.concatMapStringsSep "\n" toString [1 2]` |
| `lib.splitString sep str` | 以 sep 分割字串 | `lib.splitString ":" "a:b"` → `["a" "b"]` |
| `lib.hasPrefix prefix str` | 檢查前綴 | `lib.hasPrefix "/nix" "/nix/store"` → `true` |
| `lib.hasSuffix suffix str` | 檢查後綴 | `lib.hasSuffix ".nix" "foo.nix"` → `true` |
| `lib.removePrefix prefix str` | 移除前綴 | `lib.removePrefix "/nix/" "/nix/store"` → `"store"` |
| `lib.escapeShellArg str` | Shell 引數安全跳脫 | `lib.escapeShellArg "hello world"` → `"'hello world'"` |
| `lib.escapeShellArgs list` | 多個引數跳脫後串接 | `lib.escapeShellArgs ["git" "log"]` |
| `lib.toUpper str` | 轉大寫 | `lib.toUpper "hello"` → `"HELLO"` |
| `lib.toLower str` | 轉小寫 | `lib.toLower "HELLO"` → `"hello"` |
| `lib.trim str` | 去除前後空白 | `lib.trim "  hi  "` → `"hi"` |

### lib.lists 常用函數

| 函數 | 說明 | 範例 |
|---|---|---|
| `lib.flatten list` | 遞迴展平巢狀 list | `lib.flatten [[1 [2 3]] 4]` → `[1 2 3 4]` |
| `lib.unique list` | 去除重複元素 | `lib.unique [1 2 1 3]` → `[1 2 3]` |
| `lib.subtractLists a b` | 從 b 中移除 a 的元素 | `lib.subtractLists [2] [1 2 3]` → `[1 3]` |
| `lib.intersectLists a b` | 取交集 | `lib.intersectLists [1 2] [2 3]` → `[2]` |
| `lib.zipListsWith f la lb` | 將兩 list 對映合併 | `lib.zipListsWith (a: b: a+b) [1 2] [10 20]` → `[11 22]` |
| `lib.take n list` | 取前 n 個元素 | `lib.take 2 [1 2 3 4]` → `[1 2]` |
| `lib.drop n list` | 捨棄前 n 個元素 | `lib.drop 2 [1 2 3 4]` → `[3 4]` |
| `lib.last list` | 最後一個元素 | `lib.last [1 2 3]` → `3` |
| `lib.init list` | 去除最後一個元素 | `lib.init [1 2 3]` → `[1 2]` |
| `lib.reverseList list` | 反轉 list | `lib.reverseList [1 2 3]` → `[3 2 1]` |

### lib.attrsets 常用函數

| 函數 | 說明 | 範例 |
|---|---|---|
| `lib.recursiveUpdate a b` | 深度合併（遞迴 `//`） | `lib.recursiveUpdate { a.x=1; } { a.y=2; }` → `{ a={x=1;y=2;}; }` |
| `lib.mapAttrsToList f set` | attribute set 轉 list | `lib.mapAttrsToList (k: v: "${k}=${v}") env` |
| `lib.nameValuePair name value` | 建立 `{name;value}` 記錄 | `lib.nameValuePair "port" 80` |
| `lib.filterAttrs f set` | 過濾 attribute set | `lib.filterAttrs (k: v: v != null) cfg` |
| `lib.mapAttrs f set` | 對映 attribute set 的值 | `lib.mapAttrs (_: v: v * 2) { a=1; b=2; }` |
| `lib.getAttrs keys set` | 只取指定 key | `lib.getAttrs ["a" "b"] { a=1; b=2; c=3; }` |
| `lib.setAttrByPath path value` | 以路徑設定巢狀屬性 | `lib.setAttrByPath ["a" "b"] 1` → `{ a.b=1; }` |
| `lib.getAttrFromPath path set` | 以路徑取得巢狀屬性 | `lib.getAttrFromPath ["a" "b"] { a.b=1; }` → `1` |

### lib.trivial 工具函數

| 函數 | 說明 | 範例 |
|---|---|---|
| `lib.id x` | 恆等函數 | `lib.id 42` → `42` |
| `lib.const x _` | 忽略第二引數 | `map (lib.const 0) [1 2 3]` → `[0 0 0]` |
| `lib.flip f a b` | 交換函數的兩個引數 | `lib.flip builtins.sub 3 10` → `7` |
| `lib.pipe value [fns]` | 將 value 依序傳入函數 list | `lib.pipe 5 [(x: x*2) (x: x+1)]` → `11` |
| `lib.warn msg value` | 印出警告並回傳 value | `lib.warn "deprecated" oldFn` |
| `lib.warnIf cond msg value` | 條件式警告 | `lib.warnIf (version < 3) "old API" fn` |
| `lib.throwIf cond msg` | 條件式拋出錯誤 | `lib.throwIf (port == 0) "port cannot be 0"` |
| `lib.toHexString n` | 整數轉十六進位字串 | `lib.toHexString 255` → `"FF"` |
| `lib.mod a b` | 取模 | `lib.mod 10 3` → `1` |

---

## A.10 Derivation 與 Package 語法

### stdenv.mkDerivation 基本結構

```nix
{ stdenv, lib, fetchurl, pkg-config, openssl }:

stdenv.mkDerivation rec {
  pname   = "myapp";
  version = "1.2.3";

  src = fetchurl {
    url    = "https://example.com/${pname}-${version}.tar.gz";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  # 建構時期依賴（編譯工具鏈等）
  nativeBuildInputs = [ pkg-config ];

  # 執行時期依賴（連結的函式庫等）
  buildInputs = [ openssl ];

  # 傳遞給 configure script 的旗標
  configureFlags = [
    "--disable-static"
    "--with-openssl=${openssl.dev}"
  ];

  # 傳遞給 make 的旗標
  makeFlags = [ "PREFIX=$(out)" ];

  meta = with lib; {
    description = "My application";
    license     = licenses.mit;
    maintainers = with maintainers; [ yourname ];
    platforms   = platforms.linux;
  };
}
```

### buildInputs vs nativeBuildInputs

| 屬性 | 用途 | 典型範例 |
|---|---|---|
| `nativeBuildInputs` | 建構時期工具（在 build machine 上執行） | `pkg-config`, `cmake`, `meson`, `autoreconfHook` |
| `buildInputs` | 執行時期依賴（在 host machine 上執行） | `openssl`, `zlib`, `glib` |
| `propagatedBuildInputs` | 執行時期依賴，且也傳遞給依賴此套件的其他套件 | Python 套件的 runtime 依賴 |
| `propagatedNativeBuildInputs` | 建構時期工具，向上傳遞 | 少見 |
| `checkInputs` | 僅 check phase 需要的依賴 | `gtest`, `pytest` |
| `depsBuildBuild` | 在 build machine 執行、用於 build machine 的工具 | 交叉編譯時的 bootstrap 工具 |

交叉編譯（cross-compilation）原則：
- 工具（跑在編譯機器上）→ `nativeBuildInputs`
- 函式庫（連結到目標程式）→ `buildInputs`

### 標準 Phases（建構階段）

| Phase | 說明 | 可覆蓋的變數 |
|---|---|---|
| `unpackPhase` | 解壓 `src` | `unpackCmd`、`dontUnpack` |
| `patchPhase` | 套用 `patches` | `patches`、`dontPatch` |
| `configurePhase` | 執行 `./configure` | `configureScript`、`configureFlags`、`dontConfigure` |
| `buildPhase` | 執行 `make` | `buildFlags`、`makeFlags`、`dontBuild` |
| `checkPhase` | 執行測試 | `checkFlags`、`doCheck`（預設不執行，需設為 true） |
| `installPhase` | 安裝到 `$out` | `installFlags`、`dontInstall` |
| `fixupPhase` | 修正 rpath、strip 等 | `dontFixup` |
| `distPhase` | 打包 tarball | `dontDist`（預設不執行） |

```nix
# 自訂建構 phase
buildPhase = ''
  make -j$NIX_BUILD_CORES CFLAGS="-O2"
'';

installPhase = ''
  mkdir -p $out/bin
  cp myapp $out/bin/
  chmod +x $out/bin/myapp
'';

# 在某個 phase 前後插入步驟
preBuildPhase = ''echo "Starting build..."'';
postInstallPhase = ''
  wrapProgram $out/bin/myapp \
    --prefix PATH : ${lib.makeBinPath [ pkgs.curl ]}
'';
```

### makeWrapper / wrapProgram

```nix
# 需要在 nativeBuildInputs 中加入 makeWrapper
nativeBuildInputs = [ makeWrapper ];

postInstall = ''
  # 包裝可執行檔，注入環境變數與 PATH
  wrapProgram $out/bin/myapp \
    --prefix PATH     : ${lib.makeBinPath [ pkgs.git pkgs.curl ]} \
    --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.openssl ]} \
    --set   MY_CONFIG "$out/share/myapp/config" \
    --add-flags "--verbose"
'';
```

### passthru

```nix
# passthru 讓套件暴露額外屬性，供其他套件或測試使用
passthru = {
  # 提供套件的測試
  tests = {
    version = testers.testVersion { package = finalAttrs.finalPackage; };
  };
  # 暴露設定檔路徑給其他套件引用
  configPath = "${finalAttrs.finalPackage}/share/myapp/config";
};
```

### 常用 Setup Hooks

| Hook | 功能 |
|---|---|
| `autoreconfHook` | 自動執行 `autoreconf -vfi` |
| `cmakeConfigureHook` | 使用 CMake 配置 |
| `mesonConfigureHook` | 使用 Meson 配置 |
| `pythonImportsCheck` | 驗證 Python 模組可匯入 |
| `installShellFiles` | 安裝 shell completion 檔案 |
| `copyDesktopItems` | 複製 `.desktop` 檔案 |
| `wrapGAppsHook` | 為 GTK app 包裝並注入 GSettings schema |

---

## 附錄A 速查索引

| 需要 | 前往 |
|---|---|
| 字串插值、多行字串 | A.1、A.7 |
| Attribute set 合併、存取 | A.2 |
| List 操作函數 | A.3 |
| 函數定義與解構 pattern | A.4 |
| let/in、rec 局部變數 | A.5 |
| 條件判斷、型別檢查 | A.6 |
| 字串處理函數 | A.7 |
| 內建函數（builtins） | A.8 |
| 模組選項、lib.mkXxx | A.9 |
| 套件 derivation 撰寫 | A.10 |
