# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

# 專案任務

根據 `design/` 目錄中的資料，撰寫一本由淺入深、面向 NixOS 初學者的教學書籍：**《NixOS 系統配置文件結構完全指南》**。

目標讀者：Linux 新手到 NixOS 初學者，對聲明式建構系統有疑惑者。

---

# 書籍工具鏈

| 用途 | 工具 |
|---|---|
| 書籍生成 | mdBook |
| PDF 輸出 | pandoc |
| 圖表 | Mermaid / PlantUML |
| 格式檢查 | markdownlint |
| CI/CD | GitHub Actions |

## 常用指令（建立 toolchain 後使用）

```bash
# 本機即時預覽
mdbook serve

# 建構輸出
mdbook build

# Markdown 格式檢查
markdownlint src/

# 連結檢查
./scripts/check-links.sh

# PDF 輸出（需 pandoc）
./scripts/build-book.sh pdf
```

---

# 專案架構

## 目錄結構

```
src/                    # 書籍主要內容（mdBook 格式）
├── SUMMARY.md          # mdBook 目錄索引（必須維護）
├── part-01-foundation/ # 第一篇：理解 NixOS 與 Nix 生態（第1-3章）
├── part-02-core-configuration/ # 第二篇：configuration.nix 深入（第4-7章）
├── part-03-system-practice/    # 第三篇：系統配置實務（第8-12章）
├── part-04-services/           # 第四篇：服務配置架構（第13-16章）
├── part-05-flakes/             # 第五篇：Flakes 與現代架構（第17-20章）
├── part-06-advanced/           # 第六篇：進階配置（第21-25章）
├── part-07-debugging/          # 第七篇：除錯與維護（第26-28章）
├── part-08-enterprise/         # 第八篇：企業與基礎設施（第29-32章）
└── appendices/                 # 附錄：速查表、指令參考、錯誤速查

examples/               # 完整可用的 NixOS 設定檔範例
labs/                   # 各章節配套的實作 Lab
design/                 # 書籍設計文件（唯讀參考，不修改）
```

## 每章內部結構

每個章節目錄的標準檔案配置：
```
chapter-xx-topic/
├── overview.md         # 本章概覽與學習目標
├── theory.md           # 概念解說
├── configuration-examples.md  # 配置範例
├── walkthrough.md      # 步驟演練
├── troubleshooting.md  # 常見問題
└── summary.md          # 本章小結與練習
```

---

# 書寫風格規範

參照 `design/nixos_teaching_book_beginner_to_advanced_draft_example.md` 的範本風格：

## 文字節奏
- 短句為主，一個概念一行或一小段
- 中文說明搭配英文術語，術語首次出現需加括號解釋
- 避免長段落；複雜說明用條列或流程圖替代

## 程式碼區塊
- 所有 Nix 配置必須有完整語境（含函式簽名 `{ config, pkgs, ... }:`）
- 範例優先使用 NixOS 25.05 語法（`system.stateVersion = "25.05"`）
- 每個程式碼區塊前後都要有文字說明其「為什麼」

## Lab 格式
每個 Lab 固定包含：
1. **目標**：說明本 Lab 完成後達成什麼
2. **建議環境**：以表格列出需求
3. **Step N**：逐步操作，每步一個指令或設定
4. **驗證**：如何確認結果正確

## 漸進原則
- 先用最簡單可運行的範例，再逐步加入複雜度
- 每章新概念建立在前章基礎上，不跳步
- 模組化示範從「單一大檔」→「拆分小模組」演進

---

# 設計理念（不可偏離）

1. **先建立思維模型**，再進入語法語法與配置細節
2. **每個階段都要有**：可操作 Lab、漸進式範例、配置拆分實戰、真實工程案例
3. **不只是指令手冊**：著重解釋「為什麼這樣設計」與「如何維護大型配置」
4. 書籍內容語言：**繁體中文**，程式碼與技術術語保留英文原文

---

# 設計文件索引

| 檔案 | 用途 |
|---|---|
| `design/nixos_book_index_structure_design.md` | 完整書籍目錄（32章）與各章節主題 |
| `design/nixos_book_project_directory_structure_design.md` | 檔案目錄規劃、範例專案結構、頁數預估 |
| `design/nixos_teaching_book_beginner_to_advanced_draft_example.md` | 書寫風格範本（章節節奏、程式碼用法） |
| `design/Nixos Teaching Book Beginner To Advanced Draft.pdf` | 預期電子書排版風格 |
