{ config, pkgs, lib, ... }:

{
  # ── 系統層使用者定義 ──────────────────────────────────────────
  users.users.alice = {
    isNormalUser = true;
    description  = "Alice";
    extraGroups  = [ "wheel" "networkmanager" "audio" "video" ];
    # 使用 SSH 金鑰登入（推薦）
    # openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA..." ];
    initialPassword = "changeme";
    shell = pkgs.zsh;
  };

  # 啟用 zsh 作為系統 shell
  programs.zsh.enable = true;

  # ── Home Manager 使用者配置 ───────────────────────────────────
  # 此區塊由 Home Manager NixOS 模組處理
  home-manager.users.alice = { pkgs, ... }: {
    home.username    = "alice";
    home.homeDirectory = "/home/alice";

    # ── Shell 環境 ────────────────────────────────────────────
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        ll  = "ls -la";
        la  = "ls -A";
        ".." = "cd ..";
        # NixOS 常用別名
        rebuild = "sudo nixos-rebuild switch --flake .#workstation";
        update  = "nix flake update";
      };
    };

    programs.starship = {
      enable = true;
      settings = {
        add_newline = true;
        character = {
          success_symbol = "[❯](bold green)";
          error_symbol   = "[❯](bold red)";
        };
      };
    };

    programs.git = {
      enable    = true;
      userName  = "Alice";
      userEmail = "alice@example.com";
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase        = true;
      };
    };

    # Home Manager 版本標記，與系統版本保持一致
    home.stateVersion = "25.05";
  };
}
