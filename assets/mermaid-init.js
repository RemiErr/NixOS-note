// Custom mermaid-init.js
//
// 用途：在 mdbook-mermaid install 之後覆蓋預設 init，
// 套用 Mermaid 11+ 的 layout 設定（layout: 'dagre'）。
// 參考：https://mermaid.ai/open-source/config/layouts.html
//
// 同時保留 mdbook 深色 / 淺色主題的偵測。

(() => {
  const darkThemes = ['ayu', 'navy', 'coal'];

  function currentIsDark() {
    const cls = document.documentElement.classList;
    for (const c of cls) {
      if (darkThemes.includes(c)) return true;
    }
    return false;
  }

  function buildConfig(isDark) {
    return {
      startOnLoad: true,
      theme: isDark ? 'dark' : 'default',
      // Mermaid 11+ 的 layouts 設定，明確指定 dagre。
      // 若日後想試 elk，改為 'elk' 即可（需確認 mdbook-mermaid
      // 打包的 mermaid 版本有註冊 elk layout loader）。
      layout: 'dagre',
      flowchart: {
        useMaxWidth: true,
      },
    };
  }

  mermaid.initialize(buildConfig(currentIsDark()));

  // 監聽 mdbook 主題切換：<html> class 變動時重新初始化，
  // 讓接下來新繪製的圖採用對應主題色。
  // （已渲染的 SVG 需重新整理頁面才會套用新主題。）
  let lastDark = currentIsDark();
  const observer = new MutationObserver(() => {
    const nowDark = currentIsDark();
    if (nowDark !== lastDark) {
      lastDark = nowDark;
      mermaid.initialize(buildConfig(nowDark));
    }
  });
  observer.observe(document.documentElement, {
    attributes: true,
    attributeFilter: ['class'],
  });
})();
