#!/usr/bin/env bash
#
# Lab 4 驗證腳本
set -u

pass=0
fail=0

check() {
  local label="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "  [PASS] $label"
    pass=$((pass + 1))
  else
    echo "  [FAIL] $label"
    echo "         指令：$cmd"
    fail=$((fail + 1))
  fi
}

echo "=== Lab 4 驗證 ==="
echo

echo "Step 1–5：六個模組已建立"
for f in hardware.nix boot.nix networking.nix users.nix packages.nix; do
  check "$f 存在" "test -f /etc/nixos/$f"
done
check "hardware-configuration.nix 存在" "test -f /etc/nixos/hardware-configuration.nix"
echo

echo "Step 6：configuration.nix 為純入口"
for f in hardware boot networking users packages; do
  check "已 import $f.nix" "grep -q '\\./$f\\.nix' /etc/nixos/configuration.nix"
done
echo

echo "Step 2：systemd-boot 啟用"
check "boot.nix 啟用 systemd-boot" "grep -q 'systemd-boot.enable *= *true' /etc/nixos/boot.nix"
check "EFI 變數可寫" "grep -q 'canTouchEfiVariables *= *true' /etc/nixos/boot.nix"
echo

echo "Step 3：網路與防火牆"
check "防火牆開放 22" "grep -q 'allowedTCPPorts.*22' /etc/nixos/networking.nix"
check "OpenSSH 啟用" "grep -q 'services\\.openssh.*enable *= *true' /etc/nixos/networking.nix || systemctl is-enabled sshd"
check "PermitRootLogin 設為 no" "grep -q 'PermitRootLogin *= *\"no\"' /etc/nixos/networking.nix"
echo

echo "Step 4：alice 帳號與群組"
check "alice 存在" "id alice"
check "alice 在 wheel" "id alice | grep -q '\\bwheel\\b'"
check "alice 在 networkmanager" "id alice | grep -q networkmanager"
echo

echo "Step 5：套件與 shell"
check "git 已安裝" "command -v git"
check "ripgrep 已安裝" "command -v rg"
check "zsh 已安裝" "command -v zsh || test -e /run/current-system/sw/bin/zsh"
check "allowUnfree 已啟用" "grep -q 'allowUnfree *= *true' /etc/nixos/packages.nix"
echo

echo "Step 7：系統狀態"
check "system is running" "systemctl is-system-running --quiet || systemctl is-system-running | grep -E '(running|degraded)'"
gen_count=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system 2>/dev/null | wc -l)
if [ "${gen_count:-0}" -ge 2 ]; then
  echo "  [PASS] 至少有 2 個世代（目前 $gen_count）"
  pass=$((pass + 1))
else
  echo "  [FAIL] 世代數不足 2"
  fail=$((fail + 1))
fi
echo

echo "=== 結果 ==="
echo "通過：$pass"
echo "失敗：$fail"

if [ "$fail" -eq 0 ]; then
  echo
  echo "Lab 4 已通過所有驗證。可以前往 Lab 5。"
  exit 0
else
  echo
  echo "尚有 $fail 項未通過，可對照 solutions/ 內各模組檔案差異。"
  exit 1
fi
