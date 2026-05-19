# 第四篇：服務配置架構

NixOS 的服務管理方式，是它最強大的特性之一。

在傳統 Linux 中，你需要：手動安裝、手動配置設定檔、手動啟用 systemd unit。

在 NixOS 中，一行配置可以做到所有這些——而且是可重現、可回滾的。

本篇將帶你掌握 systemd 整合、常見服務、桌面環境，以及開發環境管理。

---

## 本篇章節

| 章節 | 主題 |
|---|---|
| 第13章 | systemd 與服務管理 |
| 第14章 | 常見服務模組（SSH、Docker、Nginx、PostgreSQL 等） |
| 第15章 | 桌面環境配置（GNOME、KDE、Hyprland） |
| 第16章 | 開發環境管理（devShell、語言工具鏈） |

---

## 本篇學習目標

完成本篇後，你將能夠：

1. 定義自訂 systemd service unit
2. 啟用並配置 OpenSSH、Docker、Nginx、PostgreSQL
3. 建立完整的 GNOME 或 KDE Plasma 桌面環境
4. 使用 `nix develop` 建立可重現的開發環境
5. 設定 PipeWire 音效系統與輸入法

---

## 前置要求

- 完成第三篇（系統配置實務）

---

## 本篇對應 Lab

**Lab 5：建立含服務的伺服器配置**

建立一台含 OpenSSH、Nginx、PostgreSQL、Docker 的伺服器 NixOS 配置，並驗證所有服務正常運作。
