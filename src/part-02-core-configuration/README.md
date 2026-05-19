# 第二篇：configuration.nix 深入解析

你已經理解了 NixOS 的設計理念。

現在，我們進入核心。

本篇將深入解析 `configuration.nix` 的每個部分，讓你不再只是「照著範例貼上」，而是真正理解每一行的用途與背後的機制。

---

## 本篇章節

| 章節 | 主題 |
|---|---|
| 第4章 | configuration.nix 基本結構 |
| 第5章 | imports 機制與模組化設計 |
| 第6章 | Option 系統與 mkOption |
| 第7章 | NixOS Module System |

---

## 本篇學習目標

完成本篇後，你將能夠：

1. 解讀 `configuration.nix` 的每個頂層區塊
2. 使用 `imports` 將配置拆分為多個模組
3. 查閱 NixOS option 文件並正確使用 option
4. 理解 `mkEnableOption`、`mkIf`、`mkMerge` 的用法
5. 理解 NixOS module 評估的完整流程

---

## 前置要求

- 完成第一篇（理解宣告式系統與 Nix 語言基礎）
- 有可操作的 NixOS 環境

---

## 本篇對應 Lab

**Lab 2：建立模組化桌面配置**

從單一 `configuration.nix` 開始，逐步拆分為 `desktop.nix`、`packages.nix`、`services.nix`、`users.nix` 的模組化結構。
