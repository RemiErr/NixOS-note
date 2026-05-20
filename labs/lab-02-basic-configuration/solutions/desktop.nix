# 桌面環境模組
#
# 集中管理桌面相關設定：顯示系統、桌面環境、音效、字型。
# 若是無頭伺服器（Headless Server），只需從 configuration.nix 的
# imports 移除這個模組即可變成純文字介面系統。

{ config, pkgs, ... }:

{
  # X11 顯示系統
  services.xserver.enable = true;

  # GNOME 桌面環境
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # PipeWire 音效（取代舊的 PulseAudio）
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # 字型
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
  ];
}
