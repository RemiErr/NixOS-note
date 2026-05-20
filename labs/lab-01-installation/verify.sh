#!/usr/bin/env bash
#
# Lab 1 驗證腳本
#
# 用途：自動檢查 Lab 1 各 Step 是否成功完成。
# 執行：在 NixOS VM 內，切到此 Lab 目錄後執行
#       bash verify.sh
#
# 退出碼：0 = 全部通過；非 0 = 有檢查未通過
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

echo "=== Lab 1 驗證 ==="
echo

echo "Step 5：configuration.nix 結構檢查"
check "configuration.nix 存在" "test -f /etc/nixos/configuration.nix"
check "hardware-configuration.nix 存在" "test -f /etc/nixos/hardware-configuration.nix"
check "包含 system.stateVersion" "grep -q 'system.stateVersion' /etc/nixos/configuration.nix"
check "stateVersion 為 25.05" "grep -q 'system.stateVersion *= *\"25.05\"' /etc/nixos/configuration.nix"
echo

echo "Step 6：configuration.nix 已加入 htop 與 tree"
check "configuration.nix 包含 htop" "grep -q '\\bhtop\\b' /etc/nixos/configuration.nix"
check "configuration.nix 包含 tree" "grep -q '\\btree\\b' /etc/nixos/configuration.nix"
echo

echo "Step 7–8：套件已實際安裝"
check "htop 可執行" "command -v htop"
check "tree 可執行" "command -v tree"
echo

echo "Step 8：世代（Generation）已增加"
gen_count=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system 2>/dev/null | wc -l)
if [ "${gen_count:-0}" -ge 2 ]; then
  echo "  [PASS] 至少有 2 個世代（目前 $gen_count 個）"
  pass=$((pass + 1))
else
  echo "  [FAIL] 世代數不足 2（目前 ${gen_count:-0} 個）"
  echo "         請執行 sudo nixos-rebuild switch 後再試"
  fail=$((fail + 1))
fi

check "wheel 群組包含使用者" "groups | grep -q '\\bwheel\\b'"
check "alice 帳號存在" "id alice"
echo

echo "=== 結果 ==="
echo "通過：$pass"
echo "失敗：$fail"

if [ "$fail" -eq 0 ]; then
  echo
  echo "Lab 1 已通過所有驗證。可以前往 Lab 2。"
  exit 0
else
  echo
  echo "尚有 $fail 項未通過，請回到對應 Step 確認。"
  exit 1
fi
