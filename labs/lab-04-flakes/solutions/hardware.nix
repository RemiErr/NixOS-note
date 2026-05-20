# Lab 4 標準答案：hardware.nix
# 額外硬體設定，不修改 hardware-configuration.nix（由 nixos-generate-config 維護）

{ config, pkgs, ... }:

{
  hardware.graphics = {
    enable      = true;
    enable32Bit = true;
  };

  services.pipewire = {
    enable = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
  };

  # NVIDIA 範本（如需取消註解）
  # hardware.nvidia = {
  #   modesetting.enable = true;
  #   open               = false;
  #   nvidiaSettings     = true;
  # };
  # services.xserver.videoDrivers = [ "nvidia" ];
}
