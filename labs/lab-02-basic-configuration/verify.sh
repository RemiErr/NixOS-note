#!/usr/bin/env bash
#
# Lab 2 驗證腳本
#
# 用途：自動檢查 Lab 2 的模組化拆分是否成功、套用是否生效。
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

echo "=== Lab 2 驗證 ==="
echo

echo "Step 2–5：四個功能模組已建立"
check "users.nix 存在" "test -f /etc/nixos/users.nix"
check "packages.nix 存在" "test -f /etc/nixos/packages.nix"
check "services.nix 存在" "test -f /etc/nixos/services.nix"
check "desktop.nix 存在" "test -f /etc/nixos/desktop.nix"
echo

echo "Step 6：configuration.nix 已重構為入口檔"
check "configuration.nix 引入 users.nix" "grep -q '\\./users\\.nix' /etc/nixos/configuration.nix"
check "configuration.nix 引入 packages.nix" "grep -q '\\./packages\\.nix' /etc/nixos/configuration.nix"
check "configuration.nix 引入 services.nix" "grep -q '\\./services\\.nix' /etc/nixos/configuration.nix"
check "configuration.nix 引入 desktop.nix" "grep -q '\\./desktop\\.nix' /etc/nixos/configuration.nix"
check "configuration.nix 不再包含 users.users.alice 定義" \
  "! grep -q 'users\\.users\\.alice *=' /etc/nixos/configuration.nix"
echo

echo "Step 7：配置可成功建構"
if sudo nixos-rebuild dry-run >/tmp/lab02-dryrun.log 2>&1; then
  echo "  [PASS] nixos-rebuild dry-run 成功"
  pass=$((pass + 1))
else
  echo "  [FAIL] nixos-rebuild dry-run 失敗"
  echo "         請查看 /tmp/lab02-dryrun.log"
  fail=$((fail + 1))
fi

check "套件 git 已安裝" "command -v git"
check "套件 tree 已安裝" "command -v tree"
check "套件 unzip 已安裝" "command -v unzip"
check "SSH 服務啟用" "systemctl is-enabled sshd"
check "alice 屬於 wheel 群組" "id alice | grep -q '\\bwheel\\b'"
echo

echo "Step 8：security.nix 已建立並啟用"
if [ -f /etc/nixos/security.nix ]; then
  check "security.nix 存在" "true"
  check "configuration.nix 引入 security.nix" "grep -q '\\./security\\.nix' /etc/nixos/configuration.nix"
  check "防火牆已啟用" "systemctl is-active firewall || sudo nft list ruleset | grep -q 'tcp dport 22'"
else
  echo "  [SKIP] security.nix 尚未建立（Step 8 為選用）"
fi
echo

echo "世代（Generation）已增加"
gen_count=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system 2>/dev/null | wc -l)
if [ "${gen_count:-0}" -ge 2 ]; then
  echo "  [PASS] 至少有 2 個世代（目前 $gen_count 個）"
  pass=$((pass + 1))
else
  echo "  [FAIL] 世代數不足 2（目前 ${gen_count:-0} 個）"
  echo "         請執行 sudo nixos-rebuild switch 後再試"
  fail=$((fail + 1))
fi
echo

echo "=== 結果 ==="
echo "通過：$pass"
echo "失敗：$fail"

if [ "$fail" -eq 0 ]; then
  echo
  echo "Lab 2 已通過所有驗證。可以前往 Lab 3。"
  exit 0
else
  echo
  echo "尚有 $fail 項未通過，請對照 solutions/ 內的標準答案檢查。"
  echo "差異對照：diff /etc/nixos/<檔名>.nix solutions/<檔名>.nix"
  exit 1
fi
