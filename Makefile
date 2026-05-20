.PHONY: serve build pdf lint check-links clean mermaid-assets

# mdbook-mermaid 需要以下檔案在書籍根目錄才能在瀏覽器渲染並縮放圖：
#   - mermaid.min.js      （由 mdbook-mermaid install 產生）
#   - mermaid-init.js     （install 產生 + 我們自訂版本覆蓋：指定 dagre layout）
#   - mermaid-zoom.js     （自訂：點擊圖開啟縮放 modal）
#   - mermaid-zoom.css    （自訂：modal 樣式）
# 來源放在 assets/，本 target 把它們複製到根目錄。根目錄版本在 .gitignore。
mermaid-assets:
	@if [ ! -f mermaid.min.js ] || [ ! -f mermaid-init.js ]; then \
		mdbook-mermaid install .; \
	fi
	cp assets/mermaid-init.js mermaid-init.js
	cp assets/mermaid-zoom.js mermaid-zoom.js
	cp assets/mermaid-zoom.css mermaid-zoom.css

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
	rm -f mermaid.min.js mermaid-init.js mermaid-zoom.js mermaid-zoom.css
