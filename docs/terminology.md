# 術語統一表

本表規範書中中英文術語的標準寫法，所有章節必須一致使用。

| 英文術語 | 中文譯名 | 首次出現寫法 | 後續寫法 |
|---|---|---|---|
| Declarative Configuration | 宣告式配置 | 宣告式配置（Declarative Configuration） | 宣告式配置 |
| Immutable Infrastructure | 不可變基礎設施 | 不可變基礎設施（Immutable Infrastructure） | 不可變基礎設施 |
| Reproducible Build | 可重現建置 | 可重現建置（Reproducible Build） | 可重現建置 |
| Generation | 世代 | 世代（Generation） | 世代 |
| Derivation | 建構描述 | 建構描述（Derivation） | derivation |
| Nix Store | Nix 儲存庫 | Nix 儲存庫（Nix Store） | Nix Store |
| System Closure | 系統閉包 | 系統閉包（System Closure） | 閉包 |
| Module | 模組 | 模組（Module） | 模組 |
| Option | 選項 | 選項（Option） | option |
| Overlay | 覆蓋層 | 覆蓋層（Overlay） | overlay |
| Flake | Flake | Flake | Flake |
| Attribute Set | 屬性集 | 屬性集（Attribute Set） | attribute set |
| Lazy Evaluation | 惰性求值 | 惰性求值（Lazy Evaluation） | 惰性求值 |
| Configuration Drift | 配置漂移 | 配置漂移（Configuration Drift） | 配置漂移 |
| Home Manager | Home Manager | Home Manager | Home Manager |
| Garbage Collection | 垃圾回收 | 垃圾回收（Garbage Collection） | 垃圾回收 |
| Binary Cache | 二進制快取 | 二進制快取（Binary Cache） | binary cache |
| Rollback | 回滾 | 回滾（Rollback） | 回滾 |
| GitOps | GitOps | GitOps | GitOps |
| Secret | 密鑰 / 機密 | 機密（Secret） | 機密 |

---

## 指令寫法規範

| 指令 | 標準寫法 |
|---|---|
| nixos-rebuild switch | `sudo nixos-rebuild switch` |
| nixos-rebuild with flake | `sudo nixos-rebuild switch --flake .#主機名稱` |
| nix develop | `nix develop` |
| nix build | `nix build` |
| nix repl | `nix repl` |

---

## 路徑寫法規範

| 路徑 | 書中寫法 |
|---|---|
| /etc/nixos/configuration.nix | `` `/etc/nixos/configuration.nix` `` |
| /nix/store | `` `/nix/store` `` |
| ~/.config/home-manager | `` `~/.config/home-manager` `` |

---

## 版本號規範

書中所有範例統一使用 **NixOS 25.05**：

```nix
system.stateVersion = "25.05";
```

```nix
nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
```
