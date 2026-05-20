# Lab 6 標準答案：profiles/desktop.nix

{ config, pkgs, ... }:

{
  services.xserver = {
    enable                       = true;
    displayManager.gdm.enable    = true;
    desktopManager.gnome.enable  = true;
  };

  services.pipewire = {
    enable       = true;
    alsa.enable  = true;
    pulse.enable = true;
  };

  environment.systemPackages = with pkgs; [
    firefox
    gnome-terminal
    nautilus
  ];
}
