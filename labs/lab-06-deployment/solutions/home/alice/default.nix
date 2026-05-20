# Lab 6 標準答案：home/alice/default.nix（Home Manager 配置）

{ config, pkgs, lib, ... }:

{
  home.username      = "alice";
  home.homeDirectory = "/home/alice";

  home.packages = with pkgs; [
    ripgrep fd bat eza
  ];

  programs.git = {
    enable    = true;
    userName  = "Alice";
    userEmail = "alice@example.com";

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase        = false;
      core.pager         = "bat --style=plain";
    };
  };

  programs.zsh = {
    enable                    = true;
    autosuggestion.enable     = true;
    syntaxHighlighting.enable = true;
    historySize               = 10000;

    shellAliases = {
      ls  = "eza --icons";
      ll  = "eza -l --icons --git";
      la  = "eza -la --icons --git";
      cat = "bat --style=plain";
    };
  };

  programs.starship = {
    enable   = true;
    settings = {
      add_newline = true;

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol   = "[❯](bold red)";
      };

      git_branch.symbol = " ";

      nix_shell = {
        symbol = " ";
        format = "[$symbol$state]($style) ";
      };
    };
  };

  home.stateVersion = "25.05";
}
