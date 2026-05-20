#!/usr/bin/env bash
#
# Lab 5 驗證腳本（伺服器服務配置）
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

echo "=== Lab 5 驗證 ==="
echo

echo "Step 1：modules/ 目錄與四個服務模組存在"
check "modules/ 目錄存在" "test -d /etc/nixos/modules"
for f in ssh postgresql webapp nginx; do
  check "modules/$f.nix 存在" "test -f /etc/nixos/modules/$f.nix"
  check "configuration.nix 引入 $f.nix" "grep -q 'modules/$f\\.nix' /etc/nixos/configuration.nix"
done
echo

echo "Step 2：OpenSSH 安全配置"
check "sshd 服務啟用" "systemctl is-active sshd"
check "禁止密碼登入" "grep -q 'PasswordAuthentication *= *false' /etc/nixos/modules/ssh.nix"
check "禁止 root 登入" "grep -q 'PermitRootLogin *= *\"no\"' /etc/nixos/modules/ssh.nix"
echo

echo "Step 3：PostgreSQL 服務"
check "postgresql 服務啟用" "systemctl is-active postgresql"
check "myapp 資料庫存在" "sudo -u postgres psql -lqt | cut -d '|' -f 1 | grep -qw myapp"
check "PostgreSQL 不對外開放" "! sudo iptables -L INPUT -n 2>/dev/null | grep -q ':5432'"
echo

echo "Step 4：自訂 myapp 服務"
check "myapp.service 啟用" "systemctl is-active myapp"
check "myapp 監聽 8080" "ss -tlnp 2>/dev/null | grep -q ':8080'"
check "HTTP 回應正確" "curl -s http://127.0.0.1:8080 | grep -q 'Hello from NixOS'"
echo

echo "Step 5：Nginx 反向代理"
check "nginx 服務啟用" "systemctl is-active nginx"
check "外部 80 port 可達" "curl -s http://localhost | grep -q 'Hello from NixOS'"
echo

echo "Step 6：防火牆"
check "防火牆開放 22" "sudo iptables -L INPUT -n 2>/dev/null | grep -q 'dpt:22'"
check "防火牆開放 80" "sudo iptables -L INPUT -n 2>/dev/null | grep -q 'dpt:80'"
echo

echo "=== 結果 ==="
echo "通過：$pass"
echo "失敗：$fail"

if [ "$fail" -eq 0 ]; then
  echo
  echo "Lab 5 已通過所有驗證。可以前往 Lab 6。"
  exit 0
else
  echo
  echo "尚有 $fail 項未通過，可對照 solutions/modules/ 內各服務模組。"
  exit 1
fi
