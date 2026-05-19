# 第八篇：企業與基礎設施場景

本書的最後一篇，是關於「規模」。

當你從管理一台機器，進化到管理一個機房、一個雲端環境、或一個工程團隊的基礎設施時，NixOS 的優勢才真正完全展現。

本篇展示真實世界的 NixOS 部署模式，以及如何讓團隊高效協作。

---

## 本篇章節

| 章節 | 主題 |
|---|---|
| 第29章 | 伺服器配置模式（web server、database、backup） |
| 第30章 | 雲端與虛擬化（Proxmox、AWS、OCI image、cloud-init） |
| 第31章 | CI/CD 與 GitOps（GitHub Actions、Cachix、Hydra） |
| 第32章 | NixOS 團隊協作架構（repository 策略、code review、文件） |

---

## 本篇學習目標

完成本篇後，你將能夠：

1. 建立標準化的伺服器配置 profile
2. 在 AWS 或 Proxmox 上部署 NixOS
3. 建立 CI/CD pipeline 自動驗證並部署 NixOS 配置
4. 設計可供多人協作的配置 repository 結構
5. 實作完整的 GitOps 工作流程

---

## 最終專案

本篇結束後，你將具備建立完整 Homelab 的能力：

Router、NAS、Kubernetes Node、Monitoring、Git Server、CI/CD——全部用 Flakes + deploy-rs + sops-nix 統一管理。
