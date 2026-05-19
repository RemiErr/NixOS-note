# 為何選擇 NixOS

在開始之前，先回答一個問題：

NixOS 解決了什麼問題，而其他 Linux 發行版沒有解決？

---

## 傳統 Linux 的配置方式

在大多數 Linux 發行版中，你可能這樣做：

```bash
sudo apt install nginx
sudo vim /etc/nginx/nginx.conf
sudo systemctl restart nginx
```

表面上沒有問題。

但隨著時間推移：

```text
一週後   →  同事改了 nginx.conf，但沒有記錄
一個月後 →  系統更新，某個套件版本衝突
三個月後 →  有人跑了一個 shell script，不知道改了什麼
半年後   →  你要在新機器上重建環境，發現哪裡都不對
```

這就是配置漂移（Configuration Drift）。

每一台機器，都在悄悄變成「只有原作者才知道怎麼運作」的狀態。

---

## NixOS 的不同之處

NixOS 要求你用一種截然不同的方式思考系統：

不是「對系統做什麼操作」。

而是「描述系統應該是什麼狀態」。

```nix
{ config, pkgs, ... }:

{
  services.nginx.enable = true;

  services.nginx.virtualHosts."example.com" = {
    root = "/var/www/example";
  };

  users.users.alice = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  system.stateVersion = "25.05";
}
```

這個檔案就是你的整個系統定義。

執行：

```bash
sudo nixos-rebuild switch
```

NixOS 會：

1. 讀取你的配置
2. 計算出系統應有的狀態
3. 建構出新的系統世代（Generation）
4. 原子化切換到新狀態
5. 保留舊世代，讓你隨時可以回滾

---

## 核心差異對比

| | 傳統 Linux | NixOS |
|---|---|---|
| 配置方式 | 命令式（做什麼） | 宣告式（是什麼） |
| 配置位置 | 散落各處 | 集中在配置檔 |
| 版本追蹤 | 手動記錄 | Git 版本控制 |
| 回滾能力 | 困難或不可能 | 一個指令完成 |
| 環境重現 | 容易出錯 | 精確可重現 |
| 多機管理 | 手動同步 | 統一配置庫 |

---

## NixOS 不是「更難的 Linux」

很多人第一眼看到 NixOS 會覺得：

「這也太複雜了吧？」

這個感覺是真實的——初期學習曲線確實存在。

但有一個重要的認知轉換：

**你在 NixOS 上花的時間，是在建立可重用的基礎設施。**

傳統 Linux 的操作時間，會在每次重裝或重建環境時歸零。

NixOS 的配置，可以無限複用。

---

## 什麼時候 NixOS 特別有價值

- 你管理超過一台機器
- 你需要「這台機器可以在別處完整重現」
- 你的系統需要精確的套件版本控制
- 你曾經因為「不知道系統狀態」而失去信心
- 你想把系統管理納入 Git 工作流程

---

接下來，我們從第一章開始，建立真正理解 NixOS 所需的思維模型。
