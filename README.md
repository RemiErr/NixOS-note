# NixOS 系統配置文件結構完全指南

從入門開始的實戰教學

## 快速上手

```bash
# 進入 Nix 開發環境（需安裝 Nix + Flakes）
nix develop

# 本機即時預覽（首次執行會自動產生 mermaid.min.js / mermaid-init.js）
make serve

# 建構 HTML
make build

# Markdown 格式檢查
make lint
```

> **Mermaid 圖表的瀏覽器資源**
>
> `mermaid.min.js` 與 `mermaid-init.js` 由 `mdbook-mermaid install .` 產生，
> 已加入 `.gitignore`，不會提交到 repo。`make serve` / `make build` 與 CI 都會
> 自動處理。若手動執行 `mdbook serve`，請先跑一次 `mdbook-mermaid install .`。

## 書籍結構

| 篇     | 主題                       | 章節        |
| ------ | -------------------------- | ----------- |
| 第一篇 | 理解 NixOS 與 Nix 生態     | 第 1–3 章   |
| 第二篇 | configuration.nix 深入解析 | 第 4–7 章   |
| 第三篇 | 系統配置實務               | 第 8–12 章  |
| 第四篇 | 服務配置架構               | 第 13–16 章 |
| 第五篇 | Flakes 與新世代配置架構    | 第 17–20 章 |
| 第六篇 | 進階配置與最佳實踐         | 第 21–25 章 |
| 第七篇 | 除錯與維護                 | 第 26–28 章 |
| 第八篇 | 企業與基礎設施場景         | 第 29–32 章 |

## 撰寫規範

請參閱 `docs/style-guide.md` 與 `docs/terminology.md`。
