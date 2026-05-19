#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-html}"

case "$MODE" in
  html)
    echo "建構 HTML..."
    mdbook build
    echo "完成：build/html/"
    ;;
  pdf)
    echo "建構 PDF..."
    mdbook build
    pandoc \
      --from markdown \
      --to pdf \
      --output build/pdf/nixos-book.pdf \
      --pdf-engine=xelatex \
      --toc \
      --toc-depth=2 \
      $(find src -name "*.md" | sort | grep -v SUMMARY.md)
    echo "完成：build/pdf/nixos-book.pdf"
    ;;
  *)
    echo "用法：$0 [html|pdf]"
    exit 1
    ;;
esac
