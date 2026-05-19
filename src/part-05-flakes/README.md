# 第五篇：Flakes 與新世代配置架構

Flakes 是 NixOS 工程化的關鍵一步。

如果說前四篇讓你學會「管理一台機器」，本篇將讓你學會「管理一個系統」。

透過 Flakes，你的 NixOS 配置將成為一個真正的工程專案：有明確的依賴版本、可在任何機器上精確重現、可以管理多台主機、可以被 CI/CD 系統驗證。

---

## 本篇章節

| 章節 | 主題 |
|---|---|
| 第17章 | Flakes 基礎（flake.nix 結構、inputs/outputs、lock file） |
| 第18章 | 使用 Flakes 管理 NixOS（多主機、遠端建置） |
| 第19章 | Home Manager 整合（使用者環境宣告式管理） |
| 第20章 | 大型配置專案架構（monorepo、hosts/modules/profiles） |

---

## 本篇學習目標

完成本篇後，你將能夠：

1. 建立完整的 `flake.nix` 並遷移既有配置
2. 用 `nixosConfigurations` 管理多台主機
3. 整合 Home Manager 管理 dotfiles 與使用者工具
4. 設計 `hosts/`、`modules/`、`profiles/` 的大型配置架構
5. 使用 `nix flake update` 管理依賴版本

---

## 前置要求

- 完成第二篇（Module System 基礎）
- 建議完成第三、四篇

---

## 注意：本篇是整本書的分水嶺

第六至八篇的所有範例都以 Flakes 為基礎。

確保你在本篇結束時，已能獨立建立並操作 `flake.nix`。

---

## 本篇對應 Lab

**Lab 6：多主機 Flakes 配置管理**

建立管理 laptop、desktop、server 三台主機的 Flakes 配置 repository，實作共用模組與主機特定配置的分離。
