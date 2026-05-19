# 第一篇：理解 NixOS 與 Nix 生態

在動手寫任何配置之前，我們需要先建立正確的思維模型。

本篇的目標不是讓你記住語法，而是讓你理解：

「NixOS 為什麼這樣設計，以及這樣設計帶來了什麼。」

---

## 本篇章節

| 章節 | 主題 |
|---|---|
| 第1章 | NixOS 的設計哲學 |
| 第2章 | Nix 語言基礎 |
| 第3章 | NixOS 配置系統概覽 |

---

## 本篇學習目標

完成本篇後，你將能夠：

1. 用自己的話解釋什麼是「宣告式配置」
2. 理解 `/nix/store` 與不可變系統的關係
3. 讀懂基本的 Nix 表達式（attribute set、function、let/in）
4. 說明 `configuration.nix` 到底控制了什麼
5. 執行 `nixos-rebuild switch` 並理解背後發生了什麼

---

## 前置要求

- 熟悉基本 Linux 終端操作（ls、cd、cat、sudo）
- 安裝好 NixOS，或準備好一個 NixOS VM（參見 Lab 1）

---

## 本篇對應 Lab

**Lab 1：安裝你的第一個 NixOS VM**

建立虛擬機、完成安裝、第一次修改 `configuration.nix`、第一次執行 `nixos-rebuild switch`。
