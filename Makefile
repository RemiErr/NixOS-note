.PHONY: serve build pdf lint check-links clean mermaid-assets

# mdbook-mermaid 需要 mermaid.min.js / mermaid-init.js 才能在瀏覽器渲染圖。
# 兩個檔在 .gitignore 內：
#   - mermaid.min.js 由 mdbook-mermaid install 產生
#   - mermaid-init.js 也由 install 產生，但我們會用 assets/mermaid-init.js
#     覆蓋它（自訂版本指定 dagre layout、保留主題切換偵測）
mermaid-assets:
	@if [ ! -f mermaid.min.js ] || [ ! -f mermaid-init.js ]; then \
		mdbook-mermaid install .; \
	fi
	cp assets/mermaid-init.js mermaid-init.js

serve: mermaid-assets
	mdbook serve --open

build: mermaid-assets
	mdbook build

pdf:
	./scripts/build-book.sh pdf

lint:
	./scripts/lint-markdown.sh

check-links:
	./scripts/check-links.sh

clean:
	rm -rf build/
	rm -f mermaid.min.js mermaid-init.js
