# {{模組名稱}}
#
# 用途：{{一句話說明此模組的目的}}
# 依賴：{{列出依賴的其他模組或 option，若無寫「無」}}
# 對應章節：{{第 N 章，方便讀者交叉參照}}

{ config, lib, pkgs, ... }:

let
  cfg = config.{{模組 option 路徑，例如 myModules.example}};
in
{
  ###########################################################################
  # Options：對外暴露的設定介面
  ###########################################################################

  options.{{模組 option 路徑}} = {
    enable = lib.mkEnableOption "{{模組功能的一句話描述}}";

    {{選項 1 名稱}} = lib.mkOption {
      type = lib.types.{{型別，例如 str / int / bool / listOf str}};
      default = {{預設值}};
      example = {{範例值}};
      description = ''
        {{多行描述：解釋這個選項的作用、何時需要調整、與其他選項的關係}}
      '';
    };

    {{選項 2 名稱}} = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "value-a" "value-b" ];
      description = ''
        {{描述}}
      '';
    };
  };

  ###########################################################################
  # Config：實際生效的系統設定（只在 enable = true 時套用）
  ###########################################################################

  config = lib.mkIf cfg.enable {
    # 斷言：確認必要前提成立，否則在 evaluation 階段就報錯
    assertions = [
      {
        assertion = {{布林條件，例如 cfg.someOption != ""}};
        message = "{{使用者能理解的錯誤訊息，包含解法提示}}";
      }
    ];

    # 警告：不阻擋建構，但提醒使用者
    warnings = lib.optional ({{條件}}) ''
      {{警告訊息，告知使用者潛在風險或建議}}
    '';

    # 實際設定
    {{設定路徑 1}} = {{使用 cfg.選項組合出最終值}};

    {{設定路徑 2}} = lib.mkDefault {{值}};  # mkDefault：允許使用者覆寫

    {{設定路徑 3}} = lib.mkForce {{值}};    # mkForce：強制覆蓋，謹慎使用
  };

  ###########################################################################
  # Meta：模組元資料（可選，撰寫 documentation 時有用）
  ###########################################################################

  meta = {
    maintainers = [ "{{維護者 GitHub handle 或 email}}" ];
    doc = ./README.md;
  };
}
