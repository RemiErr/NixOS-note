# Lab 3 標準答案：完整的 dev-tools 自訂模組
#
# 對應 Lab 3 README 的 Step 4 + Step 7 + Step 8 全部完成版本。
# 路徑（建議）：/etc/nixos/modules/dev-tools.nix

{ config, pkgs, lib, ... }:

{
  options.my.devTools = {

    enable = lib.mkEnableOption "development tools";

    enableGui = lib.mkOption {
      type        = lib.types.bool;
      default     = false;
      description = "Whether to install GUI editors (VS Code).";
    };

    editor = lib.mkOption {
      type        = lib.types.enum [ "vim" "neovim" "nano" ];
      default     = "neovim";
      description = "The terminal editor to install.";
    };

    languages = lib.mkOption {
      type        = lib.types.listOf (lib.types.enum [ "python" "rust" "go" "nodejs" ]);
      default     = [];
      description = "Programming language toolchains to install.";
      example     = [ "python" "rust" ];
    };

    extraPackages = lib.mkOption {
      type        = lib.types.listOf lib.types.package;
      default     = [];
      description = "Additional packages to install in the dev environment.";
      example     = lib.literalExpression "[ pkgs.jq pkgs.httpie ]";
    };

    # Step 7：可選的 git 使用者名稱
    gitUserName = lib.mkOption {
      type        = lib.types.nullOr lib.types.str;
      default     = null;
      description = "Git global user.name to configure. Set to null to skip.";
    };
  };

  config = lib.mkIf config.my.devTools.enable (
    let
      cfg = config.my.devTools;

      editorPkg = {
        vim    = pkgs.vim;
        neovim = pkgs.neovim;
        nano   = pkgs.nano;
      }.${cfg.editor};

      langPackages = lib.concatLists [
        (lib.optional (lib.elem "python" cfg.languages)
          (with pkgs; [ python3 python3Packages.pip ]))
        (lib.optional (lib.elem "rust"   cfg.languages)
          (with pkgs; [ rustup cargo ]))
        (lib.optional (lib.elem "go"     cfg.languages)
          [ pkgs.go ])
        (lib.optional (lib.elem "nodejs" cfg.languages)
          (with pkgs; [ nodejs nodePackages.npm ]))
      ];

      guiPackages = lib.optionals cfg.enableGui [ pkgs.vscode ];
    in
    {
      # Step 8：assertions 在 evaluation 階段就攔截不合理配置
      assertions = [
        {
          assertion = !(cfg.enableGui && !config.services.xserver.enable);
          message   = ''
            my.devTools.enableGui = true 需要桌面環境支援。
            請加入 services.xserver.enable = true，
            或將 my.devTools.enableGui 改為 false。
          '';
        }
      ];

      environment.systemPackages =
        [ editorPkg pkgs.git pkgs.curl pkgs.ripgrep ]
        ++ langPackages
        ++ guiPackages
        ++ cfg.extraPackages;

      programs.git = {
        enable = true;
        config = lib.mkIf (cfg.gitUserName != null) {
          user.name = cfg.gitUserName;
        };
      };
    }
  );
}
