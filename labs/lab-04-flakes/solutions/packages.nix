# Lab 4 標準答案：packages.nix

{ config, pkgs, ... }:

{
  nixpkgs.config = {
    allowUnfree = true;
  };

  environment.systemPackages = with pkgs; [
    # 基本工具
    git vim neovim htop btop curl wget tree unzip ripgrep fd jq

    # 開發工具
    gnumake gcc python3

    # 系統工具
    pciutils usbutils lsof

    # 網路工具
    nmap tcpdump inetutils

    # Unfree
    vscode
  ];

  programs.zsh = {
    enable                = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    interactiveShellInit  = ''
      eval "$(starship init zsh)"
    '';
  };

  programs.starship = {
    enable   = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol   = "[✗](bold red)";
      };
    };
  };

  programs.direnv = {
    enable           = true;
    nix-direnv.enable = true;
  };

  fonts.packages = with pkgs.nerd-fonts; [
    fira-code
    jetbrains-mono
  ];
}
