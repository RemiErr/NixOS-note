{
  description = "NixOS 系統配置文件結構完全指南 - 書籍建置環境";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            mdbook
            mdbook-mermaid
            pandoc
            nodePackages.markdownlint-cli
          ];

          shellHook = ''
            echo "NixOS Book 開發環境已啟動"
            echo "  make serve      - 本機即時預覽"
            echo "  make build      - 建構 HTML"
            echo "  make lint       - Markdown 格式檢查"
          '';
        };

        packages.default = pkgs.stdenv.mkDerivation {
          name = "nixos-book-html";
          src = ./.;

          nativeBuildInputs = with pkgs; [
            mdbook
            mdbook-mermaid
          ];

          buildPhase = ''
            # 產生 mermaid.min.js 與 mermaid-init.js，否則瀏覽器無法渲染圖
            mdbook-mermaid install .
            mdbook build
          '';

          installPhase = ''
            cp -r build/html $out
          '';
        };
      });
}
