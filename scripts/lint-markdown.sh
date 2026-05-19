#!/usr/bin/env bash
set -euo pipefail

echo "執行 Markdown 格式檢查..."
markdownlint src/ --config .markdownlint.json
echo "格式檢查通過"
