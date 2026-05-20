# 模板使用說明

本目錄提供四種模板，用於新增章節、Lab、範例專案、Nix 模組時保持結構一致。

| 模板 | 用途 | 用法 |
|---|---|---|
| `chapter-template.md` | 新增書籍章節 | 複製到 `src/part-XX-.../chapter-YY-topic/overview.md` |
| `lab-template.md` | 新增實作 Lab | 複製到 `labs/lab-XX-topic/README.md` |
| `example-template/` | 新增 `examples/` 範例專案 | 複製整個目錄到 `examples/your-name/` |
| `module-template.nix` | 撰寫可重用 NixOS 模組 | 複製為 `modules/your-module.nix` 或範例專案內模組 |

---

## 設計原則

1. **章節採單檔策略**：每章一個 `overview.md`，內含完整內容（目標 / 理論 / 範例 / 演練 / 排錯 / 練習 / 小結）。不再拆成 `theory.md`、`walkthrough.md` 等多檔，避免過度切碎。
2. **Lab 必須可驗證**：每個 Step 結尾要有可執行的驗證指令，不可只寫操作不寫如何確認成功。
3. **範例必須可建構**：`example-template/` 內附 `flake.nix`，讀者 clone 後執行 `nix flake check` 必須通過。
4. **模組必須有完整函式簽名**：`{ config, lib, pkgs, ... }:` 不可省略，即使 `lib` 或 `pkgs` 在該檔內未使用。

---

## 與 `docs/style-guide.md` 的關係

- 本目錄只規範**結構骨架**（有哪些段落、依什麼順序排）。
- `docs/style-guide.md` 規範**文字風格**（短句、術語括號、Mermaid 用法）。
- 兩者並用：複製模板 → 依風格指南填寫。

---

## 占位符約定

模板中所有需要替換的位置使用 `{{ ... }}` 包起來，例如：

- `{{章節編號}}` → `5`
- `{{章節主題}}` → `imports 機制與模組化設計`
- `{{對應章節}}` → `第 4–5 章`

複製模板後，請**全文搜尋 `{{` 確認沒有遺漏的占位符**。
