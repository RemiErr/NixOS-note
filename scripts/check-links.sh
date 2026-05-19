#!/usr/bin/env bash
set -euo pipefail

# 先建構再檢查連結
mdbook build

echo "檢查連結中..."
find build/html -name "*.html" | while read -r file; do
  grep -oP 'href="\K[^"]+' "$file" | grep -v "^http" | grep -v "^#" | while read -r link; do
    target="$(dirname "$file")/$link"
    if [ ! -e "$target" ]; then
      echo "斷裂連結：$file → $link"
    fi
  done
done

echo "連結檢查完成"
