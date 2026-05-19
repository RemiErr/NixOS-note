{ config, pkgs, lib, ... }:

{
  # ── 版本控制 ──────────────────────────────────────────────────
  programs.git = {
    enable = true;
    # 全域設定提示（使用者需自行設定 user.name 與 user.email）
  };

  # ── 容器工具 ──────────────────────────────────────────────────
  # Docker：廣泛使用的容器執行環境
  virtualisation.docker = {
    enable = true;
    # 系統啟動時自動啟動 Docker daemon
    enableOnBoot = true;
  };

  # ── 開發套件 ──────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # 編輯器
    neovim
    vscode

    # 終端工具
    tmux
    fzf          # 模糊搜尋
    ripgrep      # 快速文字搜尋（grep 替代品）
    jq           # JSON 處理工具
    tree         # 目錄樹狀顯示

    # 語言執行環境
    nodejs_22    # Node.js
    python313    # Python 3.13
    go           # Go 語言

    # 建構工具
    gnumake
    gcc

    # 網路除錯
    nmap
    httpie       # HTTP 客戶端（curl 替代品）
  ];

  # ── 允許 alice 使用 Docker（不需要 sudo）────────────────────
  # 注意：docker 群組成員等同於 root 權限，請謹慎使用
  users.users.alice.extraGroups = [ "docker" ];
}
