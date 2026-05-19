# 附錄F：延伸學習資源

本附錄整理了學習 NixOS 過程中最值得參考的資源，依類型與難度分類，並說明每個資源的適用場景。無論你是剛安裝好 NixOS 的新手，還是準備為 nixpkgs 貢獻套件的進階使用者，都能從這裡找到下一步的方向。

---

## F.1 官方文件（必讀）

官方文件是最權威、最完整的參考來源。遇到任何問題，建議先從這裡查起。

### NixOS Manual（官方手冊）

**連結**：[https://nixos.org/manual/nixos/stable/](https://nixos.org/manual/nixos/stable/)

**適合誰**：所有 NixOS 使用者，從安裝到進階配置都涵蓋。

這是 NixOS 系統配置的主要參考手冊，涵蓋安裝流程、硬體配置、模組系統架構、常用服務的配置方式，以及升級指引。書中許多範例的寫法都遵循這份手冊的慣例。建議將它加入書籤，遇到不熟悉的 option 時優先查這裡。

本手冊也提供 unstable 版本（`/manual/nixos/unstable/`），如果你跟 nixpkgs 的 unstable channel，可以切換到對應版本查閱。

---

### Nix Reference Manual（Nix 語言參考）

**連結**：[https://nixos.org/manual/nix/stable/](https://nixos.org/manual/nix/stable/)

**適合誰**：想深入理解 Nix 語言語義、內建函數、CLI 工具（`nix build`、`nix run`、`nix develop` 等）的使用者。

這份文件定義了 Nix 語言的求值行為與所有內建函數（builtins）。與 NixOS Manual 不同，它聚焦在 Nix 語言本身，而不是系統配置。特別是使用 Flakes 時，會大量用到這裡說明的 `nix` CLI 指令格式與 Flake schema 定義。

---

### nixpkgs Manual（nixpkgs 套件手冊）

**連結**：[https://nixos.org/manual/nixpkgs/stable/](https://nixos.org/manual/nixpkgs/stable/)

**適合誰**：想自行打包軟體、使用 overlays、或針對特定語言（Python、Rust、Go、Node.js 等）使用工具鏈的使用者。

nixpkgs 的 stdenv、`mkDerivation`、各語言的 builder（如 `buildPythonPackage`、`buildRustPackage`）都在這裡有完整說明。如果你需要自己打包一個 nixpkgs 還沒有的軟體，這份文件是不可缺少的起點。

---

### NixOS Options Search（Options 搜尋）

**連結**：[https://search.nixos.org/options](https://search.nixos.org/options)

**適合誰**：所有 NixOS 使用者，日常配置時的必備工具。

這個搜尋介面讓你快速找到任何 NixOS option 的型別、預設值、說明，以及它在 nixpkgs 原始碼中的定義位置。寫 `configuration.nix` 時不確定某個 option 叫什麼名字、接受什麼值，都可以在這裡搜尋。

使用技巧：可以用模糊關鍵字搜尋，例如搜尋 `nginx` 會列出所有和 nginx 相關的 options；搜尋 `users.users` 可以看到使用者管理相關的完整 option 樹。

---

### NixOS Packages Search（套件搜尋）

**連結**：[https://search.nixos.org/packages](https://search.nixos.org/packages)

**適合誰**：想確認某個軟體是否在 nixpkgs 中、套件的確切名稱是什麼。

在 `environment.systemPackages` 或 `home.packages` 加入套件之前，先在這裡確認套件名稱。介面也支援篩選 channel（stable/unstable），可以確認某個特定版本的套件是否可用。

---

### Nix Pills（深入理解 Nix）

**連結**：[https://nixos.org/guides/nix-pills/](https://nixos.org/guides/nix-pills/)

**適合誰**：希望真正理解 Nix 為什麼這樣設計、`derivation`、`store path`、`stdenv` 背後機制的進階學習者。

Nix Pills 是一系列深度文章，從最基礎的 `nix-store`、`derivation` 概念開始，逐步解釋 nixpkgs 整個 stdenv 的建構過程。這不是操作手冊，而是「原理解說」。如果你在使用 NixOS 一段時間後，開始想知道「這背後到底是怎麼運作的」，Nix Pills 是最佳選擇。

---

## F.2 社群資源

Nix 社群相對小眾但技術水準高，社群資源是學習過程中不可或缺的一部分。

### NixOS Discourse（官方論壇）

**連結**：[https://discourse.nixos.org/](https://discourse.nixos.org/)

**適合誰**：有問題想發問，或想追蹤 NixOS 開發動態的使用者。

這是 NixOS 官方的社群論壇，分類包含「Help」（提問）、「Development」（開發討論）、「Announcements」（版本發布公告）等。發問前建議先搜尋，很多常見問題都已有詳細討論串。

論壇的搜尋功能比 Google 更能找到特定的 NixOS 問題，因為很多 NixOS 特有的錯誤訊息直接貼上去就能找到相關討論。

---

### NixOS Wiki（社群 Wiki）

**連結**：[https://wiki.nixos.org/](https://wiki.nixos.org/)

**適合誰**：想找特定硬體、常用軟體配置方式的使用者。

社群維護的 Wiki，涵蓋各種常見應用場景，例如 NVIDIA 驅動配置、Bluetooth 設定、特定桌面環境（GNOME、KDE、Hyprland）的基礎配置等。這裡的內容通常比官方文件更貼近「實際操作」，但品質參差不齊，建議交叉驗證。

**注意**：舊版 NixOS Wiki 在 `nixos.wiki` 域名下，新版官方 Wiki 遷移至 `wiki.nixos.org`，內容持續更新中，建議優先使用新版。

---

### r/NixOS（Reddit 社群）

**連結**：[https://www.reddit.com/r/NixOS/](https://www.reddit.com/r/NixOS/)

**適合誰**：想快速提問，或看看其他人的配置心得與問題。

英文社群，氣氛友善。適合問一些相對簡單、快問快答的問題。也有不少人分享自己的配置截圖和心得文章。不適合深度技術討論，那類問題建議去 Discourse。

---

### NixOS Matrix Chat（即時聊天）

**連結**：請加入 `#nixos:nixos.org`（請自行搜尋最新連結或透過 Matrix 客戶端搜尋）

**適合誰**：想即時得到回答，或參與日常技術討論的使用者。

NixOS 社群的即時聊天在 Matrix 平台上，有多個頻道，主要頻道為 `#nixos:nixos.org`。可以用 Element（[https://element.io/](https://element.io/)）或其他 Matrix 客戶端加入。回應速度比論壇快，但問題要夠具體才容易得到幫助。

---

### Nix Community GitHub（社群工具集中地）

**連結**：[https://github.com/nix-community](https://github.com/nix-community)

**適合誰**：想探索 NixOS 生態工具的使用者。

這個 GitHub 組織聚集了許多社群維護的重要工具，包括 home-manager、agenix、disko、nixos-anywhere 等本書多處提到的工具都在這裡。如果你想找某個功能的 NixOS 社群解法，先到這裡找找。

---

## F.3 學習資源（入門到進階）

### 入門資源

#### Zero to Nix

**連結**：[https://zero-to-nix.com/](https://zero-to-nix.com/)

**難度**：初學者

**適合誰**：完全沒有接觸過 Nix 的新手。

由 Determinate Systems 製作的互動式 Nix 入門教學，設計得非常友善，可以直接在瀏覽器中執行範例。從「Nix 是什麼」到「如何用 Flakes 建立開發環境」，步驟清晰。是目前最推薦的英文入門資源之一。

---

#### nix.dev（教學合集）

**連結**：[https://nix.dev/](https://nix.dev/)

**難度**：初學者到中階

**適合誰**：想系統性學習 Nix/NixOS 的使用者。

社群整理的 Nix 教學網站，涵蓋 Nix 語言基礎、Flakes 入門、開發環境建置、套件打包入門等主題。內容品質整體高於隨機搜尋到的部落格文章，且持續維護更新。特別推薦其中的「Nix language basics」和「Getting started with Flakes」兩篇。

---

#### YouTube 教學影片

NixOS 相關的影片教學以英文為主，以下是幾個品質較高的創作者（請自行在 YouTube 搜尋最新影片）：

- **Vimjoyer**：NixOS 配置教學為主，影片節奏快，適合已有 Linux 基礎的初學者。搜尋「Vimjoyer NixOS」可找到系列影片。
- **LibrePhoenix**：有從安裝開始的完整系列，適合真正的零基礎新手。
- **teu5us**（（請自行搜尋最新連結））：Flakes 與 home-manager 配置深入介紹。

**建議做法**：先看安裝流程影片建立直覺，再回到文字文件深入理解概念，影片和文件互補效果最好。

---

### 中階資源

#### nix.dev Tutorials

**連結**：[https://nix.dev/tutorials/](https://nix.dev/tutorials/)

**難度**：中階

已在上面介紹 nix.dev 整體，這裡特別指出其 Tutorials 子目錄包含較深入的主題，例如「Package parameters and overrides」和「Callpackage design pattern」，適合在基礎打穩後進一步閱讀。

---

#### Home Manager Options 文件

**連結**：[https://nix-community.github.io/home-manager/options.xhtml](https://nix-community.github.io/home-manager/options.xhtml)

**難度**：中階（需先了解 Home Manager 基本概念）

**適合誰**：使用 Home Manager 管理使用者環境的人。

這份文件列出所有 Home Manager options，格式與 NixOS options 文件類似。在配置 Git、Shell、編輯器、GTK 主題等使用者層級設定時，這是最重要的參考文件。建議同時開著 [https://search.nixos.org/options](https://search.nixos.org/options)（NixOS 系統層）和這份文件（使用者層），兩者互相對照。

---

#### Nixpkgs Contributing Guide

**連結**：[https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md](https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md)

**難度**：中階到進階

**適合誰**：想為 nixpkgs 貢獻新套件或修復現有套件的使用者。

說明如何在本地測試套件、Pull Request 的流程、code review 的標準等。如果你打算把自己打包的軟體提交到 nixpkgs，從這裡開始。

---

### 進階資源

#### nixpkgs 原始碼的 `nixos/modules/` 目錄

**連結**：[https://github.com/NixOS/nixpkgs/tree/master/nixos/modules](https://github.com/NixOS/nixpkgs/tree/master/nixos/modules)

**難度**：進階

**適合誰**：想學習如何撰寫自己的 NixOS 模組，或理解現有模組是如何實作的。

直接閱讀 nixpkgs 裡的模組原始碼，是理解 NixOS 模組系統最直接的方式。建議從自己熟悉的服務（例如 `services/nginx/`、`services/postgresql.nix`）開始看，觀察 `options`、`config`、`imports` 是如何組織的。這比任何教學文章都來得具體且真實。

---

#### Nix 求值器原始碼

**連結**：[https://github.com/NixOS/nix](https://github.com/NixOS/nix)

**難度**：非常進階（需要 C++ 閱讀能力）

**適合誰**：對 Nix 求值機制有深度興趣，或正在研究 Nix 相關工具開發的人。

Nix 求值器以 C++ 實作，這個 repo 也包含所有 `nix` CLI 工具的原始碼。一般使用者不需要讀這份程式碼，但如果你遇到了「為什麼 lazy evaluation 在這裡的行為很奇怪」這類問題，有時候直接看求值器實作能找到答案。

---

## F.4 重要生態工具

以下工具是 NixOS 生態中廣泛使用的補充工具，本書各章節都有提及。這裡集中整理，說明各工具的定位與適用場景。

### 使用者環境管理

#### home-manager

**GitHub**：[https://github.com/nix-community/home-manager](https://github.com/nix-community/home-manager)

**文件**：[https://nix-community.github.io/home-manager/](https://nix-community.github.io/home-manager/)

**用途**：使用者層級的宣告式配置管理。

home-manager 讓你用 Nix 宣告式管理家目錄下的 dotfiles、使用者套件、Shell 環境、各種應用程式的設定檔（Git、Vim、VSCode、Alacritty 等）。可以作為 NixOS 模組整合（`home-manager.users.<username>`），也可以在非 NixOS 的 Linux 或 macOS 上獨立使用。

**何時使用**：當你想讓使用者層級的設定也能「重建」，而不只是系統層級，就需要 home-manager。特別是在多使用者或多主機環境中，home-manager 能大幅減少手動設定的工作量。

---

### Secrets 管理

#### agenix

**GitHub**：[https://github.com/ryantm/agenix](https://github.com/ryantm/agenix)

**用途**：使用 age 加密在 Git repo 中儲存 NixOS secrets。

agenix 讓你把加密後的 secrets（如資料庫密碼、API 金鑰）直接放進版本控制，並在系統啟動時自動解密，放到指定路徑。加密使用 SSH public key 或 age public key，設定相對簡單。

**何時使用**：如果你的 NixOS 配置是放在 Git repo 中管理，並且有需要保密的設定值（大多數情況都有），就需要一個 secrets 管理工具。agenix 是入門門檻較低的選項。

---

#### sops-nix

**GitHub**：[https://github.com/Mic92/sops-nix](https://github.com/Mic92/sops-nix)

**用途**：整合 SOPS（Secrets OPerationS）的 NixOS secrets 管理。

sops-nix 支援多種金鑰後端（age、GPG、AWS KMS、GCP KMS、Azure Key Vault、HashiCorp Vault），適合有更複雜需求的企業或團隊環境。設定比 agenix 複雜，但彈性更高。

**何時使用**：如果你的基礎設施已經使用 SOPS，或需要支援多種金鑰類型（例如同時支援個人 age key 和 AWS KMS），sops-nix 是更好的選擇。

---

### 磁碟與安裝

#### disko

**GitHub**：[https://github.com/nix-community/disko](https://github.com/nix-community/disko)

**用途**：宣告式磁碟分區與格式化管理。

disko 讓你用 Nix 設定檔宣告磁碟分區方案（分區表、檔案系統類型、掛載點、LUKS 加密等），然後自動執行分區操作。這讓你的整個系統配置——包含磁碟佈局——都可以版本控制並重現。

**何時使用**：準備進行全新 NixOS 安裝，或想讓磁碟配置也納入宣告式管理時。disko 與 nixos-anywhere 搭配使用效果最好。

---

#### nixos-anywhere

**GitHub**：[https://github.com/nix-community/nixos-anywhere](https://github.com/nix-community/nixos-anywhere)

**用途**：透過 SSH 遠端自動安裝 NixOS 到任何 Linux 機器或裸機。

nixos-anywhere 可以把任何已有 SSH 存取的 Linux 機器（或 VPS）自動安裝成 NixOS，只要提供你的 NixOS 配置和 disko 磁碟定義即可。整個安裝過程完全自動化，不需要手動插 USB 或操作安裝程式。

**何時使用**：部署雲端 VPS、遠端伺服器，或需要批量安裝 NixOS 的場景。配合 disko 和 sops-nix/agenix，可以實現完全自動化的系統部署。

---

### 多主機部署

#### deploy-rs

**GitHub**：[https://github.com/serokell/deploy-rs](https://github.com/serokell/deploy-rs)

**用途**：NixOS 多主機宣告式部署工具。

deploy-rs 讓你在本機建置好 NixOS 系統設定，然後推送到遠端主機並啟動。支援 profile 管理（系統層與使用者層分離部署），以及自動 rollback（如果新配置導致 SSH 連線中斷，可自動回滾）。

**何時使用**：管理多台 NixOS 伺服器，需要從單一 Flake repo 統一部署的場景。

---

#### colmena

**GitHub**：[https://github.com/zhaofengli/colmena](https://github.com/zhaofengli/colmena)

**用途**：另一個 NixOS 多主機部署工具，配置風格類似 NixOps。

colmena 的配置方式是在一個 Nix 檔案中定義所有主機的配置，語法上更接近早期的 NixOps。支援平行部署、tag 篩選部署特定主機群組。

**何時使用**：如果你喜歡「所有主機配置在一個地方」的集中式風格，colmena 的配置方式可能比 deploy-rs 更直覺。兩者功能類似，選擇上依個人偏好為主。

---

### Flake 開發輔助

#### flake-utils

**GitHub**：[https://github.com/numtide/flake-utils](https://github.com/numtide/flake-utils)

**用途**：Flake 開發中常用的輔助函數，主要解決多平台（`x86_64-linux`、`aarch64-linux`、`x86_64-darwin` 等）的重複程式碼問題。

`flake-utils.lib.eachDefaultSystem` 是最常用的函數，讓你不需要手動為每個支援的平台寫重複的 `packages`、`devShells` 定義。

**何時使用**：撰寫需要支援多平台的 Flake，特別是開發環境或函式庫型的 Flake。

---

#### flake-parts

**GitHub**：[https://github.com/hercules-ci/flake-parts](https://github.com/hercules-ci/flake-parts)

**用途**：模組化的 Flake 框架，讓 Flake 本身也能用模組系統組織。

flake-parts 把 NixOS 模組系統的概念搬到 Flake 層級，讓大型專案可以把 Flake 的各部分拆分到不同檔案，並透過 `imports` 組合。

**何時使用**：當你的 `flake.nix` 變得很長、難以維護時，flake-parts 能讓結構更清晰。對於小型個人設定，flake-utils 已經足夠；大型多人協作的 Flake repo 則適合考慮 flake-parts。

---

### 開發環境

#### devenv

**GitHub**：[https://github.com/cachix/devenv](https://github.com/cachix/devenv)

**文件**：[https://devenv.sh/](https://devenv.sh/)

**用途**：基於 Nix 的開發環境管理工具，提供比 `nix develop` 更友善的介面與功能。

devenv 在 `nix develop` 的基礎上增加了程序管理（可以用 `devenv up` 同時啟動資料庫、開發伺服器等多個程序）、測試整合、容器輸出等功能。設定檔 `devenv.nix` 比直接寫 `devShell` 更高階易讀。

**何時使用**：建立需要多個服務（如 PostgreSQL + Redis + 應用伺服器）的開發環境。對於不熟悉 Nix 的團隊成員，devenv 的學習曲線也比直接使用 Flake 開發環境低。

---

### Binary Cache 服務

#### Cachix

**連結**：[https://cachix.org/](https://cachix.org/)

**用途**：第三方 Nix binary cache 託管服務，加速 Nix 建置。

Cachix 讓你把自己建置的 Nix 套件上傳到公開或私有的 binary cache，其他人（或 CI）就能直接下載預建置的結果，不需要重新編譯。很多社群工具（如 devenv、nix-community 的工具）都有對應的 Cachix cache，加入後能大幅減少等待時間。

**何時使用**：CI/CD 環境中加速建置、在多台機器間共享自訂套件的建置結果、或使用社群工具時加入對應 cache。

免費方案支援公開 cache，適合開源專案；私有 cache 需要付費訂閱。

---

## F.5 值得參考的 NixOS 配置倉庫

閱讀他人的真實配置是學習 NixOS 最有效的方式之一。以下是幾個廣受社群參考的公開 repo。

### 官方範本

#### Misterio77/nix-starter-configs

**GitHub**：[https://github.com/Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs)

**適合誰**：想從一個結構良好的範本開始，建立自己的 NixOS Flake 配置。

提供「minimal」和「standard」兩個範本，後者整合了 home-manager。目錄結構清晰，是目前社群最常推薦的起點範本之一。如果你不確定自己的 Flake repo 該怎麼組織，從這個範本開始改是很好的選擇。

---

#### nixos-hardware

**GitHub**：[https://github.com/nix-community/nixos-hardware](https://github.com/nix-community/nixos-hardware)

**適合誰**：使用特定硬體（ThinkPad、Framework、Raspberry Pi、Steam Deck 等）的 NixOS 使用者。

這個 repo 收集了各種硬體平台的 NixOS 模組，處理好了各種硬體相容性問題（驅動、韌體、省電設定等）。使用方式是在你的 Flake `inputs` 中加入 nixos-hardware，然後在 `imports` 引用對應的模組。

---

### 尋找更多社群配置的方法

網路上有大量 NixOS 使用者公開自己的 dotfiles/NixOS config，稱為「nixos configuration」或「nix dotfiles」。尋找方法：

1. **GitHub 搜尋**：在 GitHub 搜尋 `nixos flake configuration` 或 `home-manager flake`，用 Star 數排序，可以找到很多高品質的公開配置。

2. **r/NixOS 的 showoff 文章**：Reddit 上常有人分享自己的配置截圖和 repo 連結。

3. **直接看 nixpkgs 的 `nixos/modules/`**：這是最「正式」的模組寫法範例，[https://github.com/NixOS/nixpkgs/tree/master/nixos/modules/services](https://github.com/NixOS/nixpkgs/tree/master/nixos/modules/services) 這個目錄有數百個服務模組的真實實作，是學習自訂模組最好的材料。

---

## F.6 中文資源

坦白說，目前高品質的繁體中文 NixOS 學習資源相當有限。以下列出目前可以找到的資源，但建議學習 NixOS 時仍以英文官方文件為主。

### 現有中文資源

- **本書**（你正在閱讀的這本）是目前最完整的繁體中文 NixOS 入門到進階教材。

- **簡體中文 NixOS 資源**：中國社群有一些部落格文章和 Gitbook，搜尋「NixOS 教程」或「NixOS 配置指南」可以找到，但品質與時效性差異大，建議謹慎參考並交叉驗證。

- **CSDN / 知乎**：有零散的 NixOS 入門文章，但內容往往已過時（NixOS 更新快，2-3 年前的文章可能有顯著差異），閱讀時注意文章日期。

### 關於直接閱讀英文文件

NixOS 的英文文件寫得相對清晰，且使用的詞彙重複性高（`derivation`、`option`、`module`、`overlay` 這幾個關鍵概念理解後，大部分文件都能讀懂）。建議：

1. 先用本書建立概念框架
2. 查詢具體 option 或工具用法時直接看英文官方文件
3. 遇到問題去 Discourse 搜尋，大多數情況下能找到英文解答

中文 NixOS 社群仍在成長中，如果你有能力，歡迎為中文社群貢獻翻譯或原創文章。

---

## F.7 持續更新的管道

NixOS 生態發展快速，以下管道可以幫助你持續追蹤新發展。

### NixOS Monthly Newsletter

**連結**：[https://monthly.nixos.org/](https://monthly.nixos.org/)

每月一期，整理當月 nixpkgs 的重要變更、社群工具更新、值得閱讀的文章等。訂閱後能以很低的時間成本掌握生態動態。

---

### NixCon 歷年演講

NixCon 是 Nix/NixOS 社群的年度會議，演講影片公開在 YouTube 和 media.ccc.de 上。搜尋「NixCon 2023」、「NixCon 2024」可以找到歷年影片。

這些演講通常涵蓋：新的語言特性、工具設計、大規模部署實務、安全性改進等主題，是了解 NixOS 發展方向的好管道。對進階使用者來說，比一般教學影片更有深度。

---

### GitHub 關注 nixpkgs 的 Releases

在 GitHub 上 Watch [https://github.com/NixOS/nixpkgs](https://github.com/NixOS/nixpkgs) 的 Releases，可以在新版本（如 25.05、25.11）發布時收到通知，提前了解破壞性變更。

---

### Discourse 的 Announcements 分類

[https://discourse.nixos.org/c/announcements/](https://discourse.nixos.org/c/announcements/) 是官方公告的集中地，重要的 security advisory、channel 更新、RFC 通過等都會在這裡公告。

---

## F.8 本書使用的技術版本對照

為了讓讀者在查詢資源時能對應正確版本，以下列出本書撰寫時的主要版本資訊：

| 元件 | 版本 |
|---|---|
| NixOS | 25.05 |
| nixpkgs channel | `nixos-25.05` |
| Home Manager | 對應 release-25.05 branch |
| Nix（求值器）| 2.24.x |
| Flake schema | 穩定版（實驗性標記已移除） |

查閱官方文件時，請確認切換到對應版本（URL 中的 `stable` 通常對應最新穩定版，如有需要可手動指定版本號）。

---

> **最後的建議**：NixOS 的學習曲線在最初幾週會比較陡，但一旦建立了宣告式思維模型，後續的學習速度會顯著加快。遇到問題時不要灰心——NixOS Discourse 和 Matrix 社群非常樂於幫助新手，提問時附上你的配置片段和錯誤訊息，通常能很快得到有用的回應。
