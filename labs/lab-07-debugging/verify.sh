#!/usr/bin/env bash
#
# Lab 7 驗證腳本
#
# 用途：檢查任務一到任務四的修復配置是否語法正確、服務是否成功啟動。
# 預期執行目錄：~/lab07-debugging（依 README 環境準備建立）
set -u

pass=0
fail=0
ROOT="${1:-$HOME/lab07-debugging}"
cd "$ROOT" || { echo "找不到目錄：$ROOT"; exit 1; }

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

echo "=== Lab 7 驗證（根目錄：$ROOT）==="
echo

echo "環境準備"
check "工作目錄存在" "test -d $ROOT"
check "git repo 已初始化" "test -d .git"
check "flake.nix 存在" "test -f flake.nix"
echo

echo "任務一：修復 evaluation error"
if [ -f fixed-config-1.nix ]; then
  check "fixed-config-1.nix 已使用 hostName（非 hostNamme）" \
    "grep -q 'networking\\.hostName *=' fixed-config-1.nix && ! grep -q 'hostNamme' fixed-config-1.nix"
  check "fixed-config-1.nix 使用 settings.PermitRootLogin" \
    "grep -q 'PermitRootLogin' fixed-config-1.nix && ! grep -q 'openssh\\.permitRootLogin' fixed-config-1.nix"
else
  echo "  [SKIP] fixed-config-1.nix 未建立"
fi
echo

echo "任務二：option conflict 已解決"
if grep -q 'fixed-config-1\\|fixed-service\\|conflict-resolved' flake.nix 2>/dev/null; then
  if sudo nixos-rebuild dry-run --flake "$ROOT#nixos" 2>&1 | grep -q 'conflicting definition values'; then
    echo "  [FAIL] 仍有 option conflict 錯誤"
    fail=$((fail + 1))
  else
    echo "  [PASS] dry-run 沒有 conflict 錯誤"
    pass=$((pass + 1))
  fi
else
  echo "  [SKIP] flake.nix 未指向任務配置"
fi
echo

echo "任務三：服務啟動失敗已修復"
if systemctl list-unit-files 2>/dev/null | grep -q fixed-webapp-v2; then
  check "fixed-webapp-v2 服務 active" "systemctl is-active fixed-webapp-v2"
  check "服務監聽 8080" "ss -tlnp 2>/dev/null | grep -q ':8080'"
  check "HTTP 回應正常" "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080 | grep -q '200'"
else
  echo "  [SKIP] 尚未部署 fixed-webapp-v2 服務"
fi
echo

echo "任務四：nix repl 環境檢查"
check "nix repl 可用" "command -v nix"
check "nix flake show 可解析 flake" "nix flake show $ROOT"
echo

echo "=== 結果 ==="
echo "通過：$pass"
echo "失敗：$fail"

if [ "$fail" -eq 0 ]; then
  echo
  echo "Lab 7 已通過所有驗證。本書 Lab 系列已完成。"
  exit 0
else
  echo
  echo "尚有 $fail 項未通過，可對照 solutions/ 內各 fixed-*.nix。"
  exit 1
fi
