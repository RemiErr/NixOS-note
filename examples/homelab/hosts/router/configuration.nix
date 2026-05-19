{ config, pkgs, lib, ... }:
{
  networking.hostName = "router";

  # ── 開機設定 ──────────────────────────────────────────────────
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── 核心轉送設定 ──────────────────────────────────────────────
  # 啟用 IP 轉送，讓封包可以在介面間路由
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward"            = 1;
    "net.ipv6.conf.all.forwarding"   = 1;
  };

  # ── NAT 路由 ──────────────────────────────────────────────────
  # eth0：上行介面（WAN，連接數據機）
  # eth1：下行介面（LAN，連接家庭交換器）
  networking.nat = {
    enable             = true;
    externalInterface  = "eth0";   # WAN 介面，請依實際調整
    internalInterfaces = [ "eth1" ];  # LAN 介面，請依實際調整
  };

  # ── WireGuard VPN ──────────────────────────────────────────────
  # 路由器作為 WireGuard Server，所有遠端裝置透過此 VPN 連回家庭網路
  networking.wireguard.interfaces.wg0 = {
    # VPN 子網路，路由器取得 .1 地址
    ips         = [ "10.100.0.1/24" ];
    listenPort  = 51820;

    # 私鑰檔案：在路由器上執行以下指令產生
    # sudo mkdir -p /etc/wireguard
    # wg genkey | sudo tee /etc/wireguard/private.key
    # sudo chmod 600 /etc/wireguard/private.key
    privateKeyFile = "/etc/wireguard/private.key";

    # Peer 設定：為每台遠端裝置新增一筆
    peers = [
      # 範例：手機
      # {
      #   publicKey  = "手機的 WireGuard 公鑰（wg pubkey < phone.key）";
      #   allowedIPs = [ "10.100.0.2/32" ];
      # }
      # 範例：筆電
      # {
      #   publicKey  = "筆電的 WireGuard 公鑰";
      #   allowedIPs = [ "10.100.0.3/32" ];
      # }
    ];
  };

  # ── DNS（家庭網路內部解析）────────────────────────────────────
  # dnsmasq 為家庭網路提供 DNS 解析與 DHCP 服務
  services.dnsmasq = {
    enable = true;
    settings = {
      # 監聽 LAN 介面
      interface      = "eth1";
      # 防止非完整域名查詢洩漏到上游
      domain-needed  = true;
      # 防止私有位址反向查詢洩漏
      bogus-priv     = true;
      # 上游 DNS 伺服器（可改為 1.1.1.1 或家庭 Pi-hole）
      server         = [ "8.8.8.8" "8.8.4.4" ];
      # DHCP 範圍（為家庭裝置分配 IP）
      # dhcp-range   = "192.168.1.100,192.168.1.200,24h";
    };
  };

  # ── 防火牆設定 ────────────────────────────────────────────────
  networking.firewall = {
    enable = true;
    # 開放 WireGuard UDP 連接埠
    allowedUDPPorts = [ 51820 ];
    # 開放 SSH 管理（可限制只允許 LAN 來源）
    allowedTCPPorts = [ 22 ];
  };

  # ── SSH 管理 ──────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin        = "no";
    };
  };

  # ── 時區 ──────────────────────────────────────────────────────
  time.timeZone = "Asia/Taipei";

  # ── 基礎工具 ──────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    wireguard-tools   # wg、wg-quick 指令
    tcpdump           # 封包分析
    nmap              # 網路掃描
    iptables          # 防火牆規則除錯
    curl
    vim
  ];

  # ── Nix 設定 ──────────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.05";
}
