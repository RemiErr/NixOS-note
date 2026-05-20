# Lab 6 標準答案：hosts/laptop/hardware.nix
#
# 範本：實際使用時，請複製 nixos-generate-config 自動產生的內容。
# 此處只是路徑佔位，避免 import 失敗。

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # 由實際安裝環境填入：
  # boot.initrd.availableKernelModules = [ ... ];
  # fileSystems."/" = { ... };
  # swapDevices = [ ... ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableRedistributableFirmware = true;
}
