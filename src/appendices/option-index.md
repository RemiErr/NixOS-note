# 附錄B：常用 NixOS Option 索引

本附錄收錄書中出現頻率最高的 NixOS options，依模組分類排列，適合日常配置時快速查閱。
每個 option 標示型別、預設值（若有）與簡要說明。

完整選項清單請參考：

- 線上搜尋：<https://search.nixos.org/options>
- 本機查詢：`man configuration.nix`
- nixos-option 工具：`nixos-option <option.path>`

---

## B.1 Boot（開機）

### B.1.1 systemd-boot

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `boot.loader.systemd-boot.enable` | bool | `false` | 啟用 systemd-boot EFI 開機管理員 |
| `boot.loader.systemd-boot.configurationLimit` | int | `null` | 選單保留世代數量，null 為不限 |
| `boot.loader.systemd-boot.consoleMode` | str | `"keep"` | 主控台解析度模式（keep / max / auto） |
| `boot.loader.systemd-boot.editor` | bool | `true` | 是否允許在選單中編輯核心參數 |
| `boot.loader.systemd-boot.memtest86.enable` | bool | `false` | 在開機選單中加入 Memtest86+ 項目 |
| `boot.loader.systemd-boot.graceful` | bool | `false` | 安裝失敗時不中止，改為警告 |
| `boot.loader.efi.canTouchEfiVariables` | bool | `false` | 允許 NixOS 修改 EFI NVRAM 變數 |
| `boot.loader.efi.efiSysMountPoint` | str | `"/boot"` | EFI 系統分割區掛載點 |

### B.1.2 GRUB

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `boot.loader.grub.enable` | bool | `false` | 啟用 GRUB 開機管理員 |
| `boot.loader.grub.device` | str | `"nodev"` | GRUB 安裝目標裝置（BIOS 模式用） |
| `boot.loader.grub.efiSupport` | bool | `false` | 啟用 GRUB EFI 模式 |
| `boot.loader.grub.efiInstallAsRemovable` | bool | `false` | 安裝至 EFI 可移除路徑（部分主機板相容） |
| `boot.loader.grub.useOSProber` | bool | `false` | 偵測其他作業系統（雙開機） |
| `boot.loader.grub.configurationLimit` | int | `null` | GRUB 選單保留世代數量 |
| `boot.loader.grub.theme` | path | `null` | GRUB 主題路徑 |
| `boot.loader.grub.fontSize` | int | `null` | GRUB 字型大小（HiDPI 使用） |
| `boot.loader.grub.splashImage` | path | `null` | GRUB 背景圖片路徑 |
| `boot.loader.grub.default` | str | `"0"` | 預設開機項目索引或 ID |
| `boot.loader.grub.timeout` | int | `5` | GRUB 等待時間（秒） |

### B.1.3 Kernel

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `boot.kernelPackages` | pkgs | `pkgs.linuxPackages` | 核心版本套件集（linuxPackages_latest 等） |
| `boot.kernelModules` | \[str\] | `[]` | 開機後額外載入的核心模組 |
| `boot.kernelParams` | \[str\] | `[]` | 傳遞給核心的開機參數 |
| `boot.extraModulePackages` | \[pkg\] | `[]` | 額外核心模組套件（樹外模組） |
| `boot.blacklistedKernelModules` | \[str\] | `[]` | 禁止載入的核心模組清單 |
| `boot.kernel.sysctl` | attrs | `{}` | 核心參數調整（sysctl key-value 對） |
| `boot.kernelPatches` | \[attrs\] | `[]` | 額外核心修補程式 |

### B.1.4 initrd 與 LUKS

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `boot.initrd.availableKernelModules` | \[str\] | `[]` | initrd 中必須包含的核心模組 |
| `boot.initrd.kernelModules` | \[str\] | `[]` | 強制在 initrd 中載入的模組 |
| `boot.initrd.luks.devices.<name>.device` | str | — | LUKS 加密裝置路徑 |
| `boot.initrd.luks.devices.<name>.allowDiscards` | bool | `false` | 允許 SSD TRIM 穿透 LUKS 層 |
| `boot.initrd.luks.devices.<name>.keyFile` | path | `null` | LUKS 金鑰檔案路徑 |
| `boot.initrd.luks.devices.<name>.header` | path | `null` | 分離式 LUKS header 路徑 |
| `boot.initrd.systemd.enable` | bool | `false` | 在 initrd 中使用 systemd（替代 busybox） |

### B.1.5 /tmp 與其他

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `boot.tmp.useTmpfs` | bool | `false` | 以 tmpfs 掛載 /tmp |
| `boot.tmp.tmpfsSize` | str | `"50%"` | tmpfs 容量上限（百分比或位元組） |
| `boot.tmp.cleanOnBoot` | bool | `false` | 開機時清除 /tmp 目錄內容 |
| `boot.supportedFilesystems` | \[str\] | `[...]` | 需要支援的檔案系統清單 |
| `boot.swraid.enable` | bool | `false` | 啟用 mdadm 軟體 RAID 支援 |

---

## B.2 Networking（網路）

### B.2.1 基本網路設定

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `networking.hostName` | str | `"nixos"` | 系統主機名稱 |
| `networking.domain` | str | `null` | DNS 網域名稱 |
| `networking.useDHCP` | bool | `true` | 全域 DHCP 開關（建議設 false 後個別設定） |
| `networking.interfaces.<if>.useDHCP` | bool | `false` | 單一網路介面啟用 DHCP |
| `networking.interfaces.<if>.ipv4.addresses` | \[attrs\] | `[]` | 靜態 IPv4 位址（address/prefixLength） |
| `networking.interfaces.<if>.ipv6.addresses` | \[attrs\] | `[]` | 靜態 IPv6 位址設定 |
| `networking.interfaces.<if>.mtu` | int | `null` | 網路介面 MTU 大小 |
| `networking.interfaces.<if>.macAddress` | str | `null` | 強制設定 MAC 位址 |
| `networking.defaultGateway` | str/attrs | `null` | IPv4 預設閘道 |
| `networking.defaultGateway6` | str/attrs | `null` | IPv6 預設閘道 |
| `networking.nameservers` | \[str\] | `[]` | DNS 伺服器位址清單 |
| `networking.search` | \[str\] | `[]` | DNS 搜尋網域清單 |
| `networking.hosts` | attrs | `{}` | 額外的 /etc/hosts 靜態對應 |
| `networking.enableIPv6` | bool | `true` | 全域 IPv6 支援開關 |
| `networking.proxy.default` | str | `null` | 系統 HTTP/HTTPS proxy |
| `networking.proxy.noProxy` | str | `null` | 不經過 proxy 的位址（逗號分隔） |

### B.2.2 NetworkManager 與無線

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `networking.networkmanager.enable` | bool | `false` | 啟用 NetworkManager |
| `networking.networkmanager.dns` | str | `"default"` | NetworkManager DNS 模式 |
| `networking.networkmanager.wifi.backend` | str | `"wpa_supplicant"` | Wi-Fi 後端（wpa_supplicant/iwd） |
| `networking.networkmanager.wifi.powersave` | bool | `null` | Wi-Fi 省電模式 |
| `networking.wireless.enable` | bool | `false` | 啟用 wpa_supplicant 無線管理 |
| `networking.wireless.networks` | attrs | `{}` | 宣告式 Wi-Fi 網路設定 |
| `networking.wireless.userControlled.enable` | bool | `false` | 允許一般使用者控制 wpa_supplicant |

### B.2.3 防火牆

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `networking.firewall.enable` | bool | `true` | 啟用 NixOS 內建防火牆 |
| `networking.firewall.allowedTCPPorts` | \[int\] | `[]` | 允許通過的 TCP 埠清單 |
| `networking.firewall.allowedUDPPorts` | \[int\] | `[]` | 允許通過的 UDP 埠清單 |
| `networking.firewall.allowedTCPPortRanges` | \[attrs\] | `[]` | 允許的 TCP 埠範圍（from/to） |
| `networking.firewall.allowedUDPPortRanges` | \[attrs\] | `[]` | 允許的 UDP 埠範圍（from/to） |
| `networking.firewall.allowPing` | bool | `true` | 允許 ICMP ping |
| `networking.firewall.logRefusedConnections` | bool | `true` | 記錄被拒絕的連線 |
| `networking.firewall.trustedInterfaces` | \[str\] | `[]` | 完全信任（不過濾）的網路介面 |
| `networking.firewall.extraCommands` | str | `""` | 額外的 iptables 規則（shell 腳本） |
| `networking.nftables.enable` | bool | `false` | 使用 nftables 替代 iptables |

---

## B.3 Users（使用者）

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `users.mutableUsers` | bool | `true` | 允許在執行期以 useradd 等指令修改使用者 |
| `users.users.<name>.isNormalUser` | bool | `false` | 建立一般使用者（uid≥1000、建立家目錄） |
| `users.users.<name>.isSystemUser` | bool | `false` | 建立系統使用者（uid<1000，無登入 shell） |
| `users.users.<name>.uid` | int | — | 指定使用者 UID |
| `users.users.<name>.group` | str | `"users"` | 主要群組名稱 |
| `users.users.<name>.extraGroups` | \[str\] | `[]` | 附加群組（如 wheel、docker、video） |
| `users.users.<name>.home` | str | `"/home/<name>"` | 家目錄路徑 |
| `users.users.<name>.createHome` | bool | `true` | 是否自動建立家目錄 |
| `users.users.<name>.homeMode` | str | `"700"` | 家目錄權限 |
| `users.users.<name>.shell` | pkg | `pkgs.bash` | 登入 shell 套件 |
| `users.users.<name>.hashedPassword` | str | `null` | 以雜湊值設定密碼 |
| `users.users.<name>.hashedPasswordFile` | path | `null` | 含密碼雜湊的檔案路徑（適合 secrets） |
| `users.users.<name>.initialPassword` | str | `null` | 初始密碼（明文，僅建議測試用） |
| `users.users.<name>.description` | str | `""` | 使用者全名 / GECOS 欄位 |
| `users.users.<name>.openssh.authorizedKeys.keys` | \[str\] | `[]` | SSH 授權公鑰清單 |
| `users.users.<name>.openssh.authorizedKeys.keyFiles` | \[path\] | `[]` | SSH 授權公鑰檔案路徑 |
| `users.users.<name>.packages` | \[pkg\] | `[]` | 僅為該使用者安裝的套件 |
| `users.users.<name>.linger` | bool | `false` | 允許使用者 systemd 服務在未登入時執行 |
| `users.groups.<name>.gid` | int | — | 指定群組 GID |
| `users.groups.<name>.members` | \[str\] | `[]` | 群組成員使用者名稱清單 |

---

## B.4 Services — 系統服務

### B.4.1 SSH

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `services.openssh.enable` | bool | `false` | 啟用 OpenSSH 伺服器 |
| `services.openssh.ports` | \[int\] | `[22]` | SSH 監聽埠清單 |
| `services.openssh.listenAddresses` | \[attrs\] | `[]` | 監聽的位址與埠（addr/port） |
| `services.openssh.settings.PermitRootLogin` | str | `"prohibit-password"` | 允許 root 登入方式 |
| `services.openssh.settings.PasswordAuthentication` | bool | `true` | 允許密碼登入 |
| `services.openssh.settings.PubkeyAuthentication` | bool | `true` | 允許公鑰登入 |
| `services.openssh.settings.X11Forwarding` | bool | `false` | 啟用 X11 轉送 |
| `services.openssh.settings.KbdInteractiveAuthentication` | bool | `true` | 允許鍵盤互動認證 |
| `services.openssh.settings.ClientAliveInterval` | int | `0` | 客戶端存活檢查間隔（秒） |
| `services.openssh.settings.ClientAliveCountMax` | int | `3` | 存活檢查失敗上限次數 |
| `services.openssh.settings.LogLevel` | str | `"INFO"` | SSH 日誌等級 |
| `services.openssh.authorizedKeysFiles` | \[str\] | `[...]` | 全域授權金鑰檔案路徑 |
| `services.openssh.hostKeys` | \[attrs\] | `[...]` | SSH 主機金鑰設定 |

### B.4.2 fail2ban、時間、排程

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `services.fail2ban.enable` | bool | `false` | 啟用 fail2ban 防暴力破解服務 |
| `services.fail2ban.maxretry` | int | `3` | 觸發封鎖的失敗登入次數 |
| `services.fail2ban.bantime` | str | `"10m"` | 封鎖持續時間 |
| `services.fail2ban.ignoreIP` | \[str\] | `[]` | 白名單 IP 或 CIDR |
| `services.fail2ban.jails` | attrs | `{}` | 各服務的 jail 設定 |
| `services.timesyncd.enable` | bool | `true` | 啟用 systemd-timesyncd NTP 同步 |
| `services.timesyncd.servers` | \[str\] | `[...]` | NTP 伺服器清單 |
| `services.timesyncd.fallbackServers` | \[str\] | `[...]` | 備援 NTP 伺服器清單 |
| `services.cron.enable` | bool | `false` | 啟用 cron 排程服務 |
| `services.cron.systemCronJobs` | \[str\] | `[]` | 系統 crontab 條目（含使用者欄位） |
| `services.logrotate.enable` | bool | `true` | 啟用 logrotate 日誌輪轉 |
| `services.logrotate.settings` | attrs | `{}` | logrotate 設定（各路徑的輪轉規則） |

### B.4.3 DNS 解析

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `services.resolved.enable` | bool | `false` | 啟用 systemd-resolved 解析服務 |
| `services.resolved.dns` | \[str\] | `[]` | 自訂 DNS 伺服器 |
| `services.resolved.fallbackDns` | \[str\] | `[...]` | 備援 DNS 伺服器 |
| `services.resolved.dnssec` | str | `"allow-downgrade"` | DNSSEC 驗證模式 |
| `services.resolved.llmnr` | str | `"true"` | LLMNR 多播 DNS 模式 |
| `services.dnsmasq.enable` | bool | `false` | 啟用 dnsmasq DNS/DHCP 服務 |
| `services.dnsmasq.settings` | attrs | `{}` | dnsmasq 設定屬性集 |
| `services.avahi.enable` | bool | `false` | 啟用 Avahi mDNS / DNS-SD 服務 |
| `services.avahi.nssmdns4` | bool | `false` | 啟用 IPv4 mDNS NSS 解析 |
| `services.avahi.nssmdns6` | bool | `false` | 啟用 IPv6 mDNS NSS 解析 |

---

## B.5 Services — Web / 資料庫

### B.5.1 Nginx

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `services.nginx.enable` | bool | `false` | 啟用 Nginx HTTP 伺服器 |
| `services.nginx.package` | pkg | `pkgs.nginx` | Nginx 套件版本 |
| `services.nginx.recommendedGzipSettings` | bool | `false` | 套用建議的 gzip 壓縮設定 |
| `services.nginx.recommendedOptimisation` | bool | `false` | 套用建議的效能最佳化設定 |
| `services.nginx.recommendedProxySettings` | bool | `false` | 套用建議的反向代理 header |
| `services.nginx.recommendedTlsSettings` | bool | `false` | 套用建議的 TLS 安全設定 |
| `services.nginx.statusPage` | bool | `false` | 啟用 Nginx stub_status 狀態頁 |
| `services.nginx.clientMaxBodySize` | str | `"10m"` | 客戶端請求體大小上限 |
| `services.nginx.virtualHosts.<name>.serverName` | str | — | 虛擬主機 Server Name |
| `services.nginx.virtualHosts.<name>.serverAliases` | \[str\] | `[]` | 伺服器別名清單 |
| `services.nginx.virtualHosts.<name>.root` | path | — | 靜態檔案根目錄 |
| `services.nginx.virtualHosts.<name>.enableACME` | bool | `false` | 為此主機啟用 ACME TLS 憑證 |
| `services.nginx.virtualHosts.<name>.forceSSL` | bool | `false` | 強制 HTTPS 重導向 |
| `services.nginx.virtualHosts.<name>.onlySSL` | bool | `false` | 僅監聽 HTTPS（不設 HTTP） |
| `services.nginx.virtualHosts.<name>.addSSL` | bool | `false` | 同時監聽 HTTP 與 HTTPS |
| `services.nginx.virtualHosts.<name>.locations` | attrs | `{}` | location 區塊設定 |
| `services.nginx.virtualHosts.<name>.extraConfig` | str | `""` | 額外的 server 區塊設定 |

### B.5.2 PostgreSQL

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `services.postgresql.enable` | bool | `false` | 啟用 PostgreSQL 資料庫伺服器 |
| `services.postgresql.package` | pkg | `pkgs.postgresql` | PostgreSQL 版本套件 |
| `services.postgresql.port` | int | `5432` | 監聽埠 |
| `services.postgresql.dataDir` | path | `"/var/lib/postgresql/<ver>"` | 資料庫儲存目錄 |
| `services.postgresql.initdbArgs` | \[str\] | `[]` | initdb 初始化參數 |
| `services.postgresql.authentication` | str | — | pg_hba.conf 內容 |
| `services.postgresql.settings` | attrs | `{}` | postgresql.conf 設定 |
| `services.postgresql.ensureDatabases` | \[str\] | `[]` | 啟動時確保存在的資料庫 |
| `services.postgresql.ensureUsers` | \[attrs\] | `[]` | 啟動時確保存在的資料庫使用者 |

### B.5.3 MySQL / MariaDB

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `services.mysql.enable` | bool | `false` | 啟用 MySQL / MariaDB 資料庫 |
| `services.mysql.package` | pkg | `pkgs.mariadb` | MySQL 版本套件 |
| `services.mysql.dataDir` | path | `"/var/lib/mysql"` | 資料庫儲存目錄 |
| `services.mysql.settings` | attrs | `{}` | my.cnf 設定（section → key-value） |
| `services.mysql.ensureDatabases` | \[str\] | `[]` | 啟動時確保存在的資料庫 |
| `services.mysql.ensureUsers` | \[attrs\] | `[]` | 啟動時確保存在的資料庫使用者 |
| `services.mysql.initialScript` | path | `null` | 初始化執行的 SQL 腳本 |

### B.5.4 Redis 與 ACME

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `services.redis.servers.<name>.enable` | bool | `false` | 啟用具名 Redis 實例 |
| `services.redis.servers.<name>.port` | int | `6379` | 監聽埠（0 表示僅 Unix socket） |
| `services.redis.servers.<name>.bind` | str | `"127.0.0.1"` | 綁定位址 |
| `services.redis.servers.<name>.unixSocket` | path | `null` | Unix socket 路徑 |
| `services.redis.servers.<name>.maxmemory` | int | `0` | 最大記憶體用量（0 為不限） |
| `services.redis.servers.<name>.settings` | attrs | `{}` | 額外 Redis 設定 |
| `security.acme.acceptTerms` | bool | `false` | 接受 Let's Encrypt 服務條款（必填） |
| `security.acme.defaults.email` | str | — | ACME 帳號聯絡 Email |
| `security.acme.defaults.server` | str | — | ACME CA 伺服器 URL |
| `security.acme.certs.<name>.domain` | str | — | 申請憑證的主網域 |
| `security.acme.certs.<name>.extraDomainNames` | \[str\] | `[]` | SAN 附加網域名稱 |
| `security.acme.certs.<name>.group` | str | `"acme"` | 憑證檔案群組（Nginx 需加入此群組） |
| `security.acme.certs.<name>.renewInterval` | str | `"daily"` | 憑證更新排程 |

---

## B.6 Services — 監控（Observability）

### B.6.1 Prometheus

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `services.prometheus.enable` | bool | `false` | 啟用 Prometheus 監控伺服器 |
| `services.prometheus.port` | int | `9090` | Prometheus Web UI / API 埠 |
| `services.prometheus.listenAddress` | str | `"0.0.0.0"` | 監聽位址 |
| `services.prometheus.retentionTime` | str | `"15d"` | 時序資料保留時間 |
| `services.prometheus.scrapeConfigs` | \[attrs\] | `[]` | 抓取目標（scrape_configs）設定清單 |
| `services.prometheus.rules` | \[str\] | `[]` | 告警規則檔案內容（YAML 字串） |
| `services.prometheus.alertmanager.enable` | bool | `false` | 啟用 Alertmanager 告警管理 |
| `services.prometheus.alertmanager.port` | int | `9093` | Alertmanager 監聽埠 |
| `services.prometheus.alertmanager.configuration` | attrs | — | Alertmanager 設定 |
| `services.prometheus.exporters.node.enable` | bool | `false` | 啟用 Node Exporter 主機指標 |
| `services.prometheus.exporters.node.port` | int | `9100` | Node Exporter 監聽埠 |
| `services.prometheus.exporters.node.enabledCollectors` | \[str\] | `[...]` | 啟用的 collector 清單 |
| `services.prometheus.exporters.nginx.enable` | bool | `false` | 啟用 Nginx Exporter |
| `services.prometheus.exporters.postgres.enable` | bool | `false` | 啟用 PostgreSQL Exporter |
| `services.prometheus.exporters.blackbox.enable` | bool | `false` | 啟用 Blackbox Exporter |
| `services.prometheus.exporters.systemd.enable` | bool | `false` | 啟用 Systemd Exporter |
| `services.prometheus.exporters.process.enable` | bool | `false` | 啟用 Process Exporter |

### B.6.2 Grafana 與 Loki

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `services.grafana.enable` | bool | `false` | 啟用 Grafana 儀表板服務 |
| `services.grafana.settings.server.http_port` | int | `3000` | Grafana 監聽埠 |
| `services.grafana.settings.server.domain` | str | `"localhost"` | Grafana 公開網域 |
| `services.grafana.settings.server.root_url` | str | — | Grafana 完整存取 URL |
| `services.grafana.settings.analytics.reporting_enabled` | bool | `true` | 是否傳送匿名使用統計 |
| `services.grafana.settings.security.admin_user` | str | `"admin"` | 管理員帳號名稱 |
| `services.grafana.settings.security.admin_password` | str | `"admin"` | 管理員初始密碼（建議改用 Secret） |
| `services.grafana.provision.datasources.settings` | attrs | — | 宣告式資料來源設定 |
| `services.grafana.provision.dashboards.settings` | attrs | — | 宣告式儀表板設定 |
| `services.loki.enable` | bool | `false` | 啟用 Grafana Loki 日誌聚合 |
| `services.loki.configuration` | attrs | — | Loki 完整設定（YAML 格式 attrs） |
| `services.promtail.enable` | bool | `false` | 啟用 Promtail 日誌收集代理 |
| `services.promtail.configuration` | attrs | — | Promtail 設定（含 clients/scrape_configs） |

---

## B.7 Virtualisation（虛擬化）

### B.7.1 Docker 與 Podman

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `virtualisation.docker.enable` | bool | `false` | 啟用 Docker 容器引擎 |
| `virtualisation.docker.daemon.settings` | attrs | `{}` | Docker daemon.json 設定 |
| `virtualisation.docker.enableOnBoot` | bool | `true` | 系統啟動時自動啟動 Docker |
| `virtualisation.docker.autoPrune.enable` | bool | `false` | 定期自動清理無用映像檔 |
| `virtualisation.docker.autoPrune.dates` | str | `"weekly"` | 自動清理排程（systemd 時間格式） |
| `virtualisation.docker.autoPrune.flags` | \[str\] | `[]` | 傳給 docker system prune 的旗標 |
| `virtualisation.podman.enable` | bool | `false` | 啟用 Podman 容器引擎 |
| `virtualisation.podman.dockerCompat` | bool | `false` | 提供 docker 指令相容層 |
| `virtualisation.podman.dockerSocket.enable` | bool | `false` | 啟用 Docker socket 相容層 |
| `virtualisation.podman.defaultNetwork.settings.dns_enabled` | bool | `false` | 預設網路啟用 DNS 解析 |

### B.7.2 libvirtd 與 OCI Containers

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `virtualisation.libvirtd.enable` | bool | `false` | 啟用 libvirtd KVM/QEMU 虛擬化 |
| `virtualisation.libvirtd.qemu.package` | pkg | `pkgs.qemu_kvm` | QEMU 套件版本 |
| `virtualisation.libvirtd.qemu.ovmf.enable` | bool | `false` | 啟用 OVMF UEFI 韌體（Windows VM 需要） |
| `virtualisation.libvirtd.qemu.swtpm.enable` | bool | `false` | 啟用 swtpm 虛擬 TPM |
| `virtualisation.libvirtd.allowedBridges` | \[str\] | `["virbr0"]` | 允許的橋接網路清單 |
| `virtualisation.oci-containers.backend` | str | `"podman"` | OCI 容器後端（docker/podman） |
| `virtualisation.oci-containers.containers.<name>.image` | str | — | 容器映像名稱與標籤 |
| `virtualisation.oci-containers.containers.<name>.imageFile` | path | `null` | 離線映像 tar 檔路徑 |
| `virtualisation.oci-containers.containers.<name>.ports` | \[str\] | `[]` | 埠映射（"host:container"） |
| `virtualisation.oci-containers.containers.<name>.volumes` | \[str\] | `[]` | 磁碟區映射（"host:container"） |
| `virtualisation.oci-containers.containers.<name>.environment` | attrs | `{}` | 容器環境變數 |
| `virtualisation.oci-containers.containers.<name>.environmentFiles` | \[path\] | `[]` | 從檔案載入環境變數（適合 secrets） |
| `virtualisation.oci-containers.containers.<name>.cmd` | \[str\] | `[]` | 覆寫容器啟動命令 |
| `virtualisation.oci-containers.containers.<name>.autoStart` | bool | `true` | 系統啟動時自動啟動容器 |
| `virtualisation.oci-containers.containers.<name>.dependsOn` | \[str\] | `[]` | 依賴的其他容器名稱 |
| `virtualisation.oci-containers.containers.<name>.labels` | attrs | `{}` | 容器 label 設定 |

---

## B.8 Environment（系統環境）

### B.8.1 套件與變數

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `environment.systemPackages` | \[pkg\] | `[]` | 全系統安裝的套件清單 |
| `environment.defaultPackages` | \[pkg\] | `[...]` | 預設安裝的基本套件集合 |
| `environment.variables` | attrs | `{}` | 全域環境變數（所有使用者） |
| `environment.sessionVariables` | attrs | `{}` | 登入 session 環境變數 |
| `environment.shellAliases` | attrs | `{}` | 全域 shell alias |
| `environment.pathsToLink` | \[str\] | `[]` | 連結到 /run/current-system/sw 的路徑 |
| `environment.homeBinInPath` | bool | `false` | 將 ~/bin 加入 PATH |
| `environment.localBinInPath` | bool | `false` | 將 ~/.local/bin 加入 PATH |

### B.8.2 /etc 檔案管理

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `environment.etc.<name>.text` | str | — | 以文字內容建立 /etc 檔案 |
| `environment.etc.<name>.source` | path | — | 以檔案路徑建立 /etc 符號連結 |
| `environment.etc.<name>.mode` | str | `"444"` | /etc 檔案權限（八進位字串） |
| `environment.etc.<name>.uid` | int | `0` | /etc 檔案擁有者 UID |
| `environment.etc.<name>.gid` | int | `0` | /etc 檔案擁有群組 GID |

### B.8.3 常用程式設定（programs.*）

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `programs.bash.enableCompletion` | bool | `true` | 啟用 bash tab 補全 |
| `programs.bash.interactiveShellInit` | str | `""` | 互動式 bash 初始化腳本 |
| `programs.zsh.enable` | bool | `false` | 啟用 zsh 支援（安裝並設定 /etc/zshrc） |
| `programs.zsh.enableCompletion` | bool | `true` | 啟用 zsh tab 補全 |
| `programs.zsh.autosuggestions.enable` | bool | `false` | 啟用 zsh 歷史建議 |
| `programs.zsh.syntaxHighlighting.enable` | bool | `false` | 啟用 zsh 語法高亮 |
| `programs.fish.enable` | bool | `false` | 啟用 fish shell 支援 |
| `programs.git.enable` | bool | `false` | 全系統安裝並設定 git |
| `programs.git.config` | attrs | `{}` | 全域 git 設定 |
| `programs.vim.defaultEditor` | bool | `false` | 設定 vim 為預設 EDITOR |
| `programs.neovim.enable` | bool | `false` | 啟用 Neovim |
| `programs.neovim.defaultEditor` | bool | `false` | 設定 Neovim 為預設 EDITOR |
| `programs.tmux.enable` | bool | `false` | 啟用 tmux 並寫入 /etc/tmux.conf |
| `programs.tmux.extraConfig` | str | `""` | 額外的 tmux.conf 內容 |
| `programs.htop.enable` | bool | `false` | 安裝 htop 並寫入設定 |
| `programs.iotop.enable` | bool | `false` | 安裝 iotop I/O 監控工具 |
| `programs.mtr.enable` | bool | `false` | 安裝 mtr 網路診斷工具 |

---

## B.9 Security（安全性）

### B.9.1 sudo 與 Polkit

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `security.sudo.enable` | bool | `true` | 啟用 sudo |
| `security.sudo.wheelNeedsPassword` | bool | `true` | wheel 群組使用 sudo 需要密碼 |
| `security.sudo.execWheelOnly` | bool | `false` | 僅允許 wheel 群組執行 sudo |
| `security.sudo.extraRules` | \[attrs\] | `[]` | 額外 sudoers 規則 |
| `security.sudo.extraConfig` | str | `""` | 附加到 sudoers 的原始設定文字 |
| `security.sudo-rs.enable` | bool | `false` | 以 Rust 實作的 sudo-rs 替代 sudo |
| `security.polkit.enable` | bool | `true` | 啟用 Polkit 權限管理框架 |
| `security.polkit.extraConfig` | str | `""` | 額外的 Polkit 規則 |

### B.9.2 PAM 與其他

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `security.pam.services.<name>.enableGnomeKeyring` | bool | `false` | 登入時自動解鎖 GNOME Keyring |
| `security.pam.services.<name>.u2fAuth` | bool | `false` | 啟用 FIDO2/U2F 認證 |
| `security.pam.loginLimits` | \[attrs\] | `[]` | PAM 資源限制（limits.conf 規則） |
| `security.rtkit.enable` | bool | `false` | 啟用 RealtimeKit（PipeWire 需要） |
| `security.apparmor.enable` | bool | `false` | 啟用 AppArmor 強制存取控制 |
| `security.apparmor.killUnconfinedConfinables` | bool | `false` | 終止不符合 AppArmor profile 的程序 |
| `security.auditd.enable` | bool | `false` | 啟用 Linux Audit 稽核子系統 |
| `security.tpm2.enable` | bool | `false` | 啟用 TPM 2.0 支援 |
| `security.tpm2.abrmd.enable` | bool | `false` | 啟用 TPM 2.0 存取代理守護行程 |
| `security.lockKernelModules` | bool | `false` | 開機後禁止動態載入核心模組 |

---

## B.10 Hardware（硬體）

### B.10.1 CPU 與韌體

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `hardware.cpu.intel.updateMicrocode` | bool | `false` | 啟用 Intel CPU microcode 更新 |
| `hardware.cpu.amd.updateMicrocode` | bool | `false` | 啟用 AMD CPU microcode 更新 |
| `hardware.enableRedistributableFirmware` | bool | `false` | 安裝可再發佈的韌體（含無線網卡驅動） |
| `hardware.enableAllFirmware` | bool | `false` | 安裝所有韌體（含非自由授權韌體） |

### B.10.2 圖形與 NVIDIA

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `hardware.graphics.enable` | bool | `false` | 啟用圖形硬體加速支援 |
| `hardware.graphics.enable32Bit` | bool | `false` | 啟用 32 位元 OpenGL（Steam 需要） |
| `hardware.graphics.extraPackages` | \[pkg\] | `[]` | 額外 GPU 驅動套件（如 vaapi） |
| `hardware.nvidia.modesetting.enable` | bool | `false` | 啟用 NVIDIA KMS modesetting |
| `hardware.nvidia.open` | bool | `false` | 使用 NVIDIA 開源核心模組（Turing 以後） |
| `hardware.nvidia.nvidiaSettings` | bool | `true` | 安裝 nvidia-settings GUI 工具 |
| `hardware.nvidia.powerManagement.enable` | bool | `false` | 啟用 NVIDIA 電源管理 |
| `hardware.nvidia.package` | pkg | — | NVIDIA 驅動版本（config.boot.kernelPackages.nvidiaPackages.stable） |

### B.10.3 藍牙與聲音

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `hardware.bluetooth.enable` | bool | `false` | 啟用藍牙支援 |
| `hardware.bluetooth.powerOnBoot` | bool | `true` | 開機時自動啟動藍牙 |
| `hardware.bluetooth.settings` | attrs | `{}` | /etc/bluetooth/main.conf 設定 |
| `sound.enable` | bool | `false` | 啟用 ALSA 聲音系統（舊式，逐漸棄用） |
| `hardware.pulseaudio.enable` | bool | `false` | 啟用 PulseAudio 聲音伺服器 |
| `hardware.pulseaudio.support32Bit` | bool | `false` | 啟用 PulseAudio 32 位元支援 |
| `services.pipewire.enable` | bool | `false` | 啟用 PipeWire 多媒體伺服器 |
| `services.pipewire.alsa.enable` | bool | `false` | 啟用 PipeWire 的 ALSA 相容層 |
| `services.pipewire.alsa.support32Bit` | bool | `false` | 啟用 32 位元 ALSA 相容 |
| `services.pipewire.pulse.enable` | bool | `false` | 啟用 PipeWire 的 PulseAudio 相容層 |
| `services.pipewire.jack.enable` | bool | `false` | 啟用 PipeWire 的 JACK 相容層 |

---

## B.11 Nix（Nix 本身）

### B.11.1 Nix Daemon 設定

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `nix.settings.trusted-users` | \[str\] | `["root"]` | 可信任使用者（可設定 substituter 等） |
| `nix.settings.allowed-users` | \[str\] | `["@users"]` | 允許使用 Nix daemon 的使用者或群組 |
| `nix.settings.substituters` | \[str\] | `["https://cache.nixos.org"]` | Binary cache 伺服器 URL 清單 |
| `nix.settings.trusted-public-keys` | \[str\] | `[...]` | 信任的 binary cache 公鑰 |
| `nix.settings.trusted-substituters` | \[str\] | `[]` | 受信任使用者可用的額外 substituter |
| `nix.settings.auto-optimise-store` | bool | `false` | 每次建構後自動硬連結最佳化 Store |
| `nix.settings.experimental-features` | \[str\] | `[]` | 啟用實驗性功能（nix-command、flakes 等） |
| `nix.settings.max-jobs` | int/str | `"auto"` | 最大並行建構任務數量 |
| `nix.settings.cores` | int | `0` | 每個任務使用的 CPU 核心數（0 為全部） |
| `nix.settings.sandbox` | bool | `true` | 啟用建構沙箱隔離 |
| `nix.settings.sandbox-fallback` | bool | `true` | 沙箱不可用時是否允許降級 |
| `nix.settings.keep-outputs` | bool | `false` | 保留建構輸出（除錯或開發用） |
| `nix.settings.keep-derivations` | bool | `false` | 保留 .drv 推導檔案 |
| `nix.settings.connect-timeout` | int | `5` | 下載連線逾時秒數 |
| `nix.settings.download-buffer-size` | int | `33554432` | 下載緩衝區大小（位元組） |
| `nix.settings.narinfo-cache-negative-ttl` | int | `3600` | 快取 miss 的 TTL 秒數 |

### B.11.2 垃圾回收與最佳化

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `nix.gc.automatic` | bool | `false` | 啟用定期自動垃圾回收 |
| `nix.gc.dates` | str | `"weekly"` | 垃圾回收排程（systemd 時間格式） |
| `nix.gc.options` | str | `"--delete-older-than 30d"` | 傳遞給 nix-collect-garbage 的參數 |
| `nix.gc.persistent` | bool | `true` | 系統關機時補執行錯過的 GC 任務 |
| `nix.gc.randomizedDelaySec` | str | `"0"` | GC 任務的隨機延遲（分散負載） |
| `nix.optimise.automatic` | bool | `false` | 定期執行 nix store --optimise |
| `nix.optimise.dates` | \[str\] | `["03:45"]` | 最佳化排程時間清單 |

### B.11.3 Nixpkgs 設定

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `nix.channel.enable` | bool | `true` | 是否啟用傳統 channel 支援 |
| `nix.nixPath` | \[str\] | `[...]` | NIX_PATH 清單（channel 路徑） |
| `nix.registry` | attrs | `{}` | Flake registry 設定（flakes 使用） |
| `nixpkgs.config.allowUnfree` | bool | `false` | 允許安裝非自由授權軟體 |
| `nixpkgs.config.allowBroken` | bool | `false` | 允許安裝標記為 broken 的套件 |
| `nixpkgs.config.allowInsecure` | bool | `false` | 允許安裝標記為不安全的套件 |
| `nixpkgs.config.permittedInsecurePackages` | \[str\] | `[]` | 明確允許的不安全套件清單 |
| `nixpkgs.overlays` | \[fn\] | `[]` | Nixpkgs overlay 函式清單 |
| `nixpkgs.hostPlatform` | str | — | 目標平台（如 "x86_64-linux"） |

---

## B.12 System（系統）

### B.12.1 版本與自動升級

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `system.stateVersion` | str | — | NixOS 狀態版本（初始化後不應更改） |
| `system.autoUpgrade.enable` | bool | `false` | 啟用自動系統升級 |
| `system.autoUpgrade.allowReboot` | bool | `false` | 升級後允許自動重開機 |
| `system.autoUpgrade.channel` | str | — | 升級來源 channel URL |
| `system.autoUpgrade.flake` | str | — | 升級來源 Flake 路徑（Flakes 用） |
| `system.autoUpgrade.dates` | str | `"04:40"` | 自動升級排程時間 |
| `system.autoUpgrade.randomizedDelaySec` | str | `"0"` | 升級任務的隨機延遲 |
| `system.autoUpgrade.persistent` | bool | `true` | 系統關機時補執行錯過的升級 |

### B.12.2 語系與時區

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `i18n.defaultLocale` | str | `"en_US.UTF-8"` | 系統預設語系 |
| `i18n.extraLocaleSettings` | attrs | `{}` | 細部語系設定（LC_TIME、LC_MESSAGES 等） |
| `i18n.supportedLocales` | \[str\] | `[...]` | 系統產生的 locale 清單 |
| `time.timeZone` | str | `null` | 系統時區（如 "Asia/Taipei"） |
| `time.hardwareClockInLocalTime` | bool | `false` | 硬體時鐘使用本地時間（雙開機 Windows 用） |
| `console.keyMap` | str | `"us"` | 主控台鍵盤配置 |
| `console.font` | str | `"Lat2-Terminus16"` | 主控台字型 |
| `console.colors` | \[str\] | `[]` | 主控台 16 色調色板 |

### B.12.3 systemd 服務與 tmpfiles

| Option | 型別 | 預設值 | 說明 |
|--------|------|--------|------|
| `systemd.services.<name>.enable` | bool | `true` | 啟用或停用服務 unit |
| `systemd.services.<name>.description` | str | — | 服務描述文字 |
| `systemd.services.<name>.after` | \[str\] | `[]` | 在指定 unit 啟動後才啟動 |
| `systemd.services.<name>.before` | \[str\] | `[]` | 在指定 unit 啟動前先啟動 |
| `systemd.services.<name>.requires` | \[str\] | `[]` | 強依賴的 unit（失敗則一起失敗） |
| `systemd.services.<name>.wants` | \[str\] | `[]` | 軟依賴的 unit（失敗不影響本服務） |
| `systemd.services.<name>.wantedBy` | \[str\] | `[]` | 加入指定 target 的依賴 |
| `systemd.services.<name>.environment` | attrs | `{}` | 服務的環境變數 |
| `systemd.services.<name>.serviceConfig` | attrs | `{}` | systemd [Service] 區塊設定 |
| `systemd.services.<name>.startLimitIntervalSec` | int | — | 啟動頻率限制計時窗口 |
| `systemd.services.<name>.startLimitBurst` | int | — | 計時窗口內允許的最大重啟次數 |
| `systemd.timers.<name>.timerConfig` | attrs | — | systemd [Timer] 區塊設定 |
| `systemd.timers.<name>.wantedBy` | \[str\] | `[]` | Timer 所屬的 target |
| `systemd.tmpfiles.rules` | \[str\] | `[]` | systemd-tmpfiles 規則（建立/清理路徑） |
| `systemd.network.enable` | bool | `false` | 啟用 systemd-networkd 網路管理 |

---

## 快速查詢：Option 型別說明

| 型別符號 | 意義 | 範例 |
|----------|------|------|
| `bool` | 布林值 | `true` / `false` |
| `int` | 整數 | `22`, `8080` |
| `str` | 字串 | `"nginx"`, `"Asia/Taipei"` |
| `path` | 檔案路徑 | `/var/lib/data` |
| `pkg` | Nixpkgs 套件 | `pkgs.nginx` |
| `pkgs` | Nixpkgs 套件集 | `pkgs.linuxPackages_latest` |
| `\[str\]` | 字串清單 | `[ "a" "b" ]` |
| `\[pkg\]` | 套件清單 | `[ pkgs.vim pkgs.git ]` |
| `\[int\]` | 整數清單 | `[ 80 443 ]` |
| `\[path\]` | 路徑清單 | `[ /etc/key ]` |
| `\[attrs\]` | 屬性集清單 | `[ { address = "..."; } ]` |
| `attrs` | 屬性集 | `{ key = "value"; }` |
| `\[fn\]` | 函式清單 | overlay 函式 |

---

## 快速查詢：常用指令

```bash
# 查詢 option 目前生效值
nixos-option services.openssh.enable

# 查詢 option 完整說明、型別與預設值
nixos-option --verbose services.openssh

# 在 Nix REPL 中查詢（需 Flakes）
nix repl --expr 'import <nixpkgs/nixos> {}'
# 進入 REPL 後：
# config.services.openssh.enable

# 線上搜尋特定 option
# https://search.nixos.org/options?query=services.nginx

# 列出系統所有已啟用服務
systemctl list-units --type=service --state=running

# 找出 option 所屬的模組定義檔
grep -r "services.nginx.enable" /run/current-system/
```

---

## 快速查詢：常見 extraGroups 對照表

| 群組名稱 | 授予權限 | 典型使用情境 |
|----------|----------|--------------|
| `wheel` | 使用 sudo | 系統管理員帳號 |
| `docker` | 存取 Docker socket | 執行 docker 指令 |
| `podman` | 存取 Podman socket | 執行 podman 指令 |
| `libvirtd` | 管理 KVM 虛擬機器 | virt-manager 使用 |
| `networkmanager` | 控制網路設定 | 桌面環境使用者 |
| `audio` | 直接存取音訊裝置 | 僅 ALSA 需要，PipeWire 不需要 |
| `video` | 存取影像裝置 | 桌面環境、webcam |
| `input` | 存取輸入裝置 | 遊戲、觸控板設定 |
| `lp` | 列印機存取 | 使用列印功能 |
| `scanner` | 掃描器存取 | SANE 掃描器 |
| `dialout` | 序列埠存取 | Arduino、序列通訊 |
| `adbusers` | Android Debug Bridge | Android 開發 |
| `wireshark` | 封包擷取 | 網路診斷 |
| `tss` | TPM 裝置存取 | TPM 相關工具 |

---

*本附錄依 NixOS 25.05 版本整理。部分 option 路徑可能因版本升級而有所調整，
以 <https://search.nixos.org/options> 的最新文件為準。*
