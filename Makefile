.PHONY: serve build pdf lint check-links clean

serve:
	mdbook serve --open

build:
	mdbook build

pdf:
	./scripts/build-book.sh pdf

lint:
	./scripts/lint-markdown.sh

check-links:
	./scripts/check-links.sh

clean:
	rm -rf build/
