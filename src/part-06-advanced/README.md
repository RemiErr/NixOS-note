# 第六篇：進階配置與最佳實踐

你已經能夠建立可運作的 NixOS 系統。

本篇進入「讓配置真正專業」的階段：

如何修改套件行為而不 fork 上游？如何安全管理密碼與金鑰？如何撰寫可供他人重用的 Module？如何自動化部署？如何讓 binary cache 讓建置速度大幅提升？

---

## 本篇章節

| 章節 | 主題 |
|---|---|
| 第21章 | Overlay 與 Package Override |
| 第22章 | Secrets 管理（agenix / sops-nix） |
| 第23章 | 自訂 NixOS Module 開發 |
| 第24章 | 建置與部署流程（deploy-rs / colmena） |
| 第25章 | 效能與儲存最佳化（binary cache / GC） |

---

## 本篇學習目標

完成本篇後，你將能夠：

1. 使用 overlay 修改套件版本或行為
2. 用 agenix 或 sops-nix 安全管理機密
3. 撰寫帶有完整 option schema 的 reusable module
4. 使用 deploy-rs 遠端部署多台機器
5. 設定 binary cache 加速建置，並管理 Nix Store 空間

---

## 前置要求

- 完成第五篇（Flakes 配置架構）
