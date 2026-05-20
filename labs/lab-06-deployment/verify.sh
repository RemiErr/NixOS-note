#!/usr/bin/env bash
#
# Lab 6 驗證腳本（Flakes 多主機 + Home Manager）
#
# 注意：此腳本預期在 /etc/nixos（或你的 flake 根目錄）下執行。
set -u

pass=0
fail=0
ROOT="${1:-/etc/nixos}"
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

echo "=== Lab 6 驗證（根目錄：$ROOT）==="
echo

echo "Step 1–2：Flakes 啟用 + git repo 初始化"
check "Flakes 子指令可用" "nix flake --help | head -1"
check "git repo 存在" "test -d .git"
check "flake.nix 存在" "test -f flake.nix"
check "flake.nix 已被 git 追蹤" "git ls-files --error-unmatch flake.nix"
check "flake.lock 存在且已 commit" "test -f flake.lock && git ls-files --error-unmatch flake.lock"
echo

echo "Step 4–6：目錄結構"
for d in hosts/laptop hosts/server modules/common profiles home/alice; do
  check "$d 存在" "test -d $d"
done
check "modules/common/nix.nix 存在" "test -f modules/common/nix.nix"
check "profiles/desktop.nix 存在" "test -f profiles/desktop.nix"
check "profiles/server.nix 存在" "test -f profiles/server.nix"
echo

echo "flake 結構驗證"
if nix flake show 2>/dev/null | grep -q 'laptop'; then
  echo "  [PASS] nixosConfigurations.laptop 存在"
  pass=$((pass + 1))
else
  echo "  [FAIL] nix flake show 未顯示 laptop"
  fail=$((fail + 1))
fi
if nix flake show 2>/dev/null | grep -q 'server'; then
  echo "  [PASS] nixosConfigurations.server 存在"
  pass=$((pass + 1))
else
  echo "  [FAIL] nix flake show 未顯示 server"
  fail=$((fail + 1))
fi
echo

echo "Step 6：server 配置可建構（dry-run）"
if nix build .#nixosConfigurations.server.config.system.build.toplevel --dry-run 2>/dev/null; then
  echo "  [PASS] server dry-run 成功"
  pass=$((pass + 1))
else
  echo "  [FAIL] server dry-run 失敗"
  fail=$((fail + 1))
fi
echo

echo "Step 7–8：Home Manager 套件（在 laptop 上）"
if [ "$(hostname)" = "laptop" ]; then
  check "bat 可執行" "command -v bat"
  check "eza 可執行" "command -v eza"
  check "fd 可執行" "command -v fd"
  check "git user.email 由 home-manager 設定" "git config --global user.email | grep -qv '^$'"
else
  echo "  [SKIP] 當前主機名非 laptop，跳過 Home Manager 檢查"
fi
echo

echo "=== 結果 ==="
echo "通過：$pass"
echo "失敗：$fail"

if [ "$fail" -eq 0 ]; then
  echo
  echo "Lab 6 已通過所有驗證。可以前往 Lab 7。"
  exit 0
else
  echo
  echo "尚有 $fail 項未通過，可對照 solutions/ 內各檔案。"
  exit 1
fi
