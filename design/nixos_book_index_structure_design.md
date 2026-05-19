# 《NixOS 系統配置文件結構完全指南》目錄草案

## 前言

* 為什麼選擇 NixOS
* 宣告式系統的核心思想
* 本書適合的讀者
* 建議閱讀方式
* 範例環境與版本說明

---

# 第一篇：理解 NixOS 與 Nix 生態

## 第1章：NixOS 的設計哲學

* 不可變基礎設施（Immutable Infrastructure）
* 宣告式配置（Declarative Configuration）
* 可重現建置（Reproducible Builds）
* Rollback 與世代（Generations）
* 與傳統 Linux 發行版的差異

## 第2章：Nix 語言基礎

* Nix Expression 語法
* Attribute Set
* List 與 Function
* let / in
* import 與 inherit
* lazy evaluation
* derivation 概念
* REPL 使用方式

## 第3章：NixOS 配置系統概覽

* `/etc/nixos/`
* `configuration.nix`
* `hardware-configuration.nix`
* modules 系統
* option tree
* evaluation 流程
* system closure

---

# 第二篇：configuration.nix 深入解析

## 第4章：configuration.nix 基本結構

* 檔案骨架
* imports 區塊
* boot 區塊
* networking 區塊
* users 區塊
* services 區塊
* environment 區塊
* system.stateVersion

## 第5章：imports 機制與模組化設計

* import 的工作方式
* 多檔案拆分策略
* 目錄結構規劃
* 共用模組設計
* 主機角色分離
* 避免循環依賴

## 第6章：Option 系統與 mkOption

* option 的定義方式
* type system
* default 與 example
* mkEnableOption
* mkIf / mkMerge
* priority 機制
* override 與 force

## 第7章：NixOS Module System

* module evaluation
* config 與 options
* specialArgs
* imports chain
* module arguments
* 自訂 module 開發
* reusable module 設計

---

# 第三篇：系統配置實務

## 第8章：硬體配置文件

* `hardware-configuration.nix`
* fileSystems
* swapDevices
* initrd 設定
* kernel modules
* GPU 驅動配置
* ZFS / Btrfs 支援

## 第9章：Boot 與 Kernel 配置

* GRUB
* systemd-boot
* EFI 設定
* kernelPackages
* kernelParams
* initrd hooks
* secure boot

## 第10章：網路配置

* NetworkManager
* systemd-networkd
* 靜態 IP
* VLAN
* Bridge
* DNS 管理
* firewall 配置
* WireGuard

## 第11章：使用者與權限管理

* users.users
* groups.groups
* sudo 規則
* SSH keys
* PAM
* secrets 管理
* LDAP / AD 整合

## 第12章：套件與環境管理

* environment.systemPackages
* overlays
* package override
* unfree packages
* fonts
* shell configuration
* direnv 與 nix-direnv

---

# 第四篇：服務配置架構

## 第13章：systemd 與服務管理

* systemd 在 NixOS 中的角色
* service unit 定義
* timers
* targets
* socket activation
* service override
* journald

## 第14章：常見服務模組

* OpenSSH
* Docker
* Podman
* PostgreSQL
* Nginx
* Redis
* Tailscale
* Samba

## 第15章：桌面環境配置

* X11
* Wayland
* GNOME
* KDE Plasma
* Hyprland
* display manager
* input method
* 音效系統（PipeWire）

## 第16章：開發環境管理

* devShell
* flakes devShell
* language toolchain
* Python
* Rust
* Go
* Node.js
* reproducible development environment

---

# 第五篇：Flakes 與新世代配置架構

## 第17章：Flakes 基礎

* flakes 的問題背景
* flake.nix 結構
* inputs / outputs
* lock file
* flake registry
* nix command 新介面

## 第18章：使用 Flakes 管理 NixOS

* `nixosConfigurations`
* 多主機管理
* deploy workflow
* remote build
* shared modules
* cross-platform 配置

## 第19章：Home Manager 整合

* Home Manager 架構
* standalone 模式
* NixOS module 模式
* user profile 管理
* dotfiles 管理
* desktop personalization

## 第20章：大型配置專案架構

* monorepo 設計
* hosts/
* modules/
* profiles/
* pkgs/
* lib/
* secrets/
* deployment/
* configuration layering

---

# 第六篇：進階配置與最佳實踐

## 第21章：Overlay 與 Package Override

* overlay 基本概念
* self / super
* package patching
* custom derivation
* local package repository

## 第22章：Secrets 管理

* agenix
* sops-nix
* age
* GPG
* secrets deployment
* CI/CD secrets

## 第23章：自訂 NixOS Module 開發

* 撰寫 reusable modules
* option schema 設計
* module testing
* assertions
* warnings
* documentation generation

## 第24章：建置與部署流程

* nixos-rebuild
* switch / boot / test
* rollback
* remote deployment
* deploy-rs
* colmena
* CI integration

## 第25章：效能與儲存最佳化

* binary cache
* substituters
* garbage collection
* store optimization
* deduplication
* closure analysis

---

# 第七篇：除錯與維護

## 第26章：NixOS 除錯技巧

* evaluation error 分析
* stack trace 閱讀
* `--show-trace`
* nix repl
* option 查詢
* journalctl

## 第27章：升級策略

* channel 更新
* flake update
* major release migration
* stateVersion
* rollback strategy

## 第28章：常見問題與陷阱

* infinite recursion
* attribute missing
* option conflict
* broken package
* impurity 問題
* flakes 相容性問題

---

# 第八篇：企業與基礎設施場景

## 第29章：伺服器配置模式

* web server profile
* database server
* virtualization host
* container host
* backup server

## 第30章：雲端與虛擬化

* Proxmox
* KVM
* LXC
* AWS
* OCI image
* cloud-init

## 第31章：CI/CD 與 GitOps

* GitHub Actions
* Cachix
* Hydra
* GitOps workflow
* deployment automation

## 第32章：NixOS 團隊協作架構

* repository policy
* code review
* configuration convention
* module ownership
* documentation strategy

---

# 附錄

## 附錄A：Nix 語言速查表

## 附錄B：常用 Option 索引

## 附錄C：常用指令整理

## 附錄D：錯誤訊息速查

## 附錄E：推薦專案結構模板

## 附錄F：社群資源與文件導航

---

# 索引

* Option Index
* Module Index
* Command Index
* Service Index

---

# 補充：建議的實戰案例章節（可插入各篇）

若要讓這本書更有「工程實戰感」，建議加入以下完整案例：

1. 單機桌面 NixOS 配置演進
2. 多主機 Homelab 架構
3. 公司內部標準化工作站
4. Kubernetes Node 的 NixOS 化
5. 用 Flakes 管理跨平台（NixOS + macOS）
6. 從 Arch Linux 遷移到 NixOS
7. 用 GitOps 管理整個家庭伺服器

這樣會讓內容從「配置文件介紹」提升到「架構設計與維運方法論」。
