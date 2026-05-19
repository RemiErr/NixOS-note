# 第七篇：除錯與維護

每個 NixOS 使用者都會遇到建置失敗。

Nix 的錯誤訊息有時很長、很嚇人，特別是 evaluation error 和 infinite recursion。

本篇的目標是讓你不再看到錯誤就慌——而是有系統地診斷並修復問題。

---

## 本篇章節

| 章節 | 主題 |
|---|---|
| 第26章 | NixOS 除錯技巧（`--show-trace`、nix repl、journalctl） |
| 第27章 | 升級策略（channel 更新、flake update、major release 遷移） |
| 第28章 | 常見問題與陷阱（infinite recursion、option conflict、broken package） |

---

## 本篇學習目標

完成本篇後，你將能夠：

1. 讀懂 Nix evaluation error 的 stack trace
2. 使用 `nix repl` 動態除錯配置
3. 安全地執行 NixOS 版本升級
4. 識別並修復最常見的配置錯誤
5. 制定升級失敗時的回滾策略

---

## 本篇對應 Lab

**Lab 7：除錯工作坊**

提供一份包含數個刻意錯誤的 NixOS 配置，帶你逐一診斷並修復。
