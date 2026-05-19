{ config, pkgs, lib, ... }:

{
  # ── X11 與 GNOME ──────────────────────────────────────────────
  services.xserver = {
    enable = true;
    # GNOME 顯示管理器（登入畫面）
    displayManager.gdm.enable = true;
    # GNOME 桌面環境
    desktopManager.gnome.enable = true;
  };

  # ── 音效系統 ──────────────────────────────────────────────────
  # PipeWire 是現代 Linux 音效伺服器，取代舊有的 PulseAudio
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ── 列印服務 ──────────────────────────────────────────────────
  services.printing.enable = true;

  # ── 字型 ──────────────────────────────────────────────────────
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      # 思源黑體：Google 與 Adobe 合作的開源中文字型
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      # 程式碼字型
      fira-code
      jetbrains-mono
    ];
    fontconfig.defaultFonts = {
      serif     = [ "Noto Serif CJK TC" "Noto Serif" ];
      sansSerif = [ "Noto Sans CJK TC" "Noto Sans" ];
      monospace = [ "JetBrains Mono" "Noto Sans Mono" ];
    };
  };

  # ── GNOME 排除不必要的預設應用程式 ───────────────────────────
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-music
    epiphany    # GNOME 預設瀏覽器，通常改用 Firefox
  ];

  # ── 瀏覽器 ────────────────────────────────────────────────────
  programs.firefox.enable = true;
}
