#!/usr/bin/env bash
#
# Lab 3 驗證腳本
#
# 用途：檢查 dev-tools 模組是否正確建立、options 是否生效、套件是否安裝。
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

echo "=== Lab 3 驗證 ==="
echo

echo "Step 2–4：dev-tools 模組已建立"
check "dev-tools.nix 存在" "test -f /etc/nixos/modules/dev-tools.nix"
check "宣告 options.my.devTools" "grep -q 'options\\.my\\.devTools' /etc/nixos/modules/dev-tools.nix"
check "包含 mkEnableOption" "grep -q 'mkEnableOption' /etc/nixos/modules/dev-tools.nix"
check "editor 使用 enum 限制" "grep -q 'types\\.enum' /etc/nixos/modules/dev-tools.nix"
echo

echo "Step 5：configuration.nix 引入並啟用模組"
check "已 import dev-tools.nix" "grep -q 'dev-tools\\.nix' /etc/nixos/configuration.nix"
check "已啟用 my.devTools" "grep -q 'my\\.devTools\\.enable *= *true' /etc/nixos/configuration.nix"
echo

echo "Step 6：套件已實際安裝"
check "git 可執行" "command -v git"
check "ripgrep 可執行" "command -v rg"
echo

echo "Step 6-4：nixos-option 可查詢 option 值"
if command -v nixos-option >/dev/null 2>&1; then
  if nixos-option my.devTools.enable 2>/dev/null | grep -q 'true'; then
    echo "  [PASS] my.devTools.enable = true"
    pass=$((pass + 1))
  else
    echo "  [FAIL] my.devTools.enable 未顯示為 true"
    fail=$((fail + 1))
  fi
else
  echo "  [SKIP] nixos-option 不在 PATH 中"
fi
echo

echo "Step 8：模組包含 assertions"
check "dev-tools.nix 包含 assertions" "grep -q 'assertions' /etc/nixos/modules/dev-tools.nix"
echo

echo "Step 7：gitUserName option（選用）"
if grep -q 'gitUserName' /etc/nixos/modules/dev-tools.nix; then
  check "git user.name 已設定" "git config --global user.name | grep -v '^$'"
else
  echo "  [SKIP] 尚未實作 gitUserName option"
fi
echo

echo "=== 結果 ==="
echo "通過：$pass"
echo "失敗：$fail"

if [ "$fail" -eq 0 ]; then
  echo
  echo "Lab 3 已通過所有驗證。可以前往 Lab 4。"
  exit 0
else
  echo
  echo "尚有 $fail 項未通過，請對照 solutions/dev-tools.nix 檢查。"
  exit 1
fi
