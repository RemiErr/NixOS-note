# {{範例名稱}}

{{一段話說明這個範例展示了什麼。例如：「示範如何以 Flakes 管理單主機 NixOS 配置，並把設定拆分為 4 個功能模組。」}}

---

## 適用情境

- {{何時應該採用這個架構，例如：個人單機開發環境}}
- {{適合多大規模的配置，例如：1–3 台機器}}
- {{不適合的情境，例如：超過 5 台機器建議改用 modular-layout}}

---

## 目錄結構

```text
{{範例目錄名}}/
├── README.md                    # 本檔
├── flake.nix                    # 入口：定義 nixosConfigurations
├── flake.lock                   # 鎖定 inputs 版本（第一次 build 後生成）
├── hosts/
│   └── {{主機名}}/
│       └── configuration.nix    # 主機配置入口
└── modules/
    ├── {{模組 1}}.nix            # {{說明用途}}
    └── {{模組 2}}.nix            # {{說明用途}}
```

---

## 使用方式

### 1. 建構（不套用）

```bash
nix build .#nixosConfigurations.{{主機名}}.config.system.build.toplevel
```

### 2. 在現有 NixOS 機器上套用

```bash
sudo nixos-rebuild switch --flake .#{{主機名}}
```

### 3. 檢查 flake 結構

```bash
nix flake check
nix flake show
```

---

## 對應書籍章節

- 第 {{章節編號}} 章：{{章節主題}}
- Lab {{Lab 編號}}：{{Lab 主題}}

---

## 延伸修改建議

- {{修改建議 1：例如「將 services 拆出獨立模組」}}
- {{修改建議 2：例如「加入 Home Manager 整合」}}
- {{修改建議 3：例如「改為多主機架構，參考 examples/homelab」}}
