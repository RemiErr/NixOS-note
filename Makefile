.PHONY: serve build pdf lint check-links clean mermaid-assets

# mdbook-mermaid 需要 mermaid.min.js / mermaid-init.js 才能在瀏覽器渲染圖。
# 這兩個檔在 .gitignore 內，由本 target 產生（idempotent，已存在不會重複寫）。
mermaid-assets:
	@if [ ! -f mermaid.min.js ] || [ ! -f mermaid-init.js ]; then \
		mdbook-mermaid install .; \
	fi

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
