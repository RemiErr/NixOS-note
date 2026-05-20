// Mermaid zoom modal
//
// 點擊任何 Mermaid 圖會開啟全螢幕浮層，支援：
//   - 滾輪縮放
//   - 拖曳平移
//   - 控制列按鈕（放大 / 縮小 / 重設 / 關閉）
//   - ESC / 點背景關閉
//
// 與 mermaid-init.js 配合使用。本檔在 book.toml 的 additional-js 中註冊。

(() => {
  const ZOOM_STEP = 1.2;
  const WHEEL_STEP = 1.1;
  const MIN_SCALE = 0.2;
  const MAX_SCALE = 20;

  function clamp(v, min, max) {
    return Math.max(min, Math.min(max, v));
  }

  function ensureModal() {
    let modal = document.getElementById('mermaid-zoom-modal');
    if (modal) return modal;

    modal = document.createElement('div');
    modal.id = 'mermaid-zoom-modal';
    modal.innerHTML = `
      <div class="mz-backdrop"></div>
      <div class="mz-stage">
        <div class="mz-content"></div>
      </div>
      <div class="mz-controls">
        <button class="mz-btn" data-action="zoom-in" aria-label="放大" title="放大">+</button>
        <button class="mz-btn" data-action="zoom-out" aria-label="縮小" title="縮小">−</button>
        <button class="mz-btn" data-action="reset" aria-label="重設" title="重設">⟳</button>
        <button class="mz-btn" data-action="close" aria-label="關閉" title="關閉 (Esc)">×</button>
      </div>
      <div class="mz-hint">滾輪縮放 · 拖曳平移 · ESC 關閉</div>
    `;
    document.body.appendChild(modal);

    const stage = modal.querySelector('.mz-stage');
    const content = modal.querySelector('.mz-content');
    const state = { scale: 1, tx: 0, ty: 0, dragging: false, lastX: 0, lastY: 0 };

    function apply() {
      content.style.transform =
        `translate(${state.tx}px, ${state.ty}px) scale(${state.scale})`;
    }
    function reset() {
      state.scale = 1; state.tx = 0; state.ty = 0; apply();
    }
    function close() {
      modal.classList.remove('mz-open');
      // 延後清空，避免 transform 動畫殘留
      setTimeout(() => { content.innerHTML = ''; reset(); }, 150);
    }

    modal.querySelector('.mz-backdrop').addEventListener('click', close);

    modal.querySelectorAll('.mz-btn').forEach((btn) => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        const a = btn.dataset.action;
        if (a === 'zoom-in')  { state.scale = clamp(state.scale * ZOOM_STEP, MIN_SCALE, MAX_SCALE); apply(); }
        else if (a === 'zoom-out') { state.scale = clamp(state.scale / ZOOM_STEP, MIN_SCALE, MAX_SCALE); apply(); }
        else if (a === 'reset') { reset(); }
        else if (a === 'close') { close(); }
      });
    });

    // 滾輪縮放（以游標位置為中心）
    stage.addEventListener('wheel', (e) => {
      e.preventDefault();
      const factor = e.deltaY < 0 ? WHEEL_STEP : 1 / WHEEL_STEP;
      const newScale = clamp(state.scale * factor, MIN_SCALE, MAX_SCALE);
      const ratio = newScale / state.scale;
      const rect = stage.getBoundingClientRect();
      const cx = e.clientX - rect.left - rect.width / 2;
      const cy = e.clientY - rect.top - rect.height / 2;
      state.tx = cx - (cx - state.tx) * ratio;
      state.ty = cy - (cy - state.ty) * ratio;
      state.scale = newScale;
      apply();
    }, { passive: false });

    // 拖曳平移
    stage.addEventListener('mousedown', (e) => {
      if (e.target.closest('.mz-btn')) return;
      state.dragging = true;
      state.lastX = e.clientX;
      state.lastY = e.clientY;
      stage.classList.add('mz-grabbing');
    });
    document.addEventListener('mousemove', (e) => {
      if (!state.dragging) return;
      state.tx += e.clientX - state.lastX;
      state.ty += e.clientY - state.lastY;
      state.lastX = e.clientX;
      state.lastY = e.clientY;
      apply();
    });
    document.addEventListener('mouseup', () => {
      state.dragging = false;
      stage.classList.remove('mz-grabbing');
    });

    // 觸控（行動裝置基本支援：單指拖曳）
    stage.addEventListener('touchstart', (e) => {
      if (e.target.closest('.mz-btn')) return;
      if (e.touches.length !== 1) return;
      state.dragging = true;
      state.lastX = e.touches[0].clientX;
      state.lastY = e.touches[0].clientY;
    }, { passive: true });
    stage.addEventListener('touchmove', (e) => {
      if (!state.dragging || e.touches.length !== 1) return;
      state.tx += e.touches[0].clientX - state.lastX;
      state.ty += e.touches[0].clientY - state.lastY;
      state.lastX = e.touches[0].clientX;
      state.lastY = e.touches[0].clientY;
      apply();
    }, { passive: true });
    stage.addEventListener('touchend', () => { state.dragging = false; });

    // ESC 關閉
    document.addEventListener('keydown', (e) => {
      if (!modal.classList.contains('mz-open')) return;
      if (e.key === 'Escape') close();
      else if (e.key === '0') reset();
      else if (e.key === '+' || e.key === '=') {
        state.scale = clamp(state.scale * ZOOM_STEP, MIN_SCALE, MAX_SCALE); apply();
      } else if (e.key === '-' || e.key === '_') {
        state.scale = clamp(state.scale / ZOOM_STEP, MIN_SCALE, MAX_SCALE); apply();
      }
    });

    return modal;
  }

  function openZoom(sourceSvg) {
    const modal = ensureModal();
    const content = modal.querySelector('.mz-content');
    content.innerHTML = '';
    const clone = sourceSvg.cloneNode(true);
    // 清除 mermaid 原本套用的 inline 尺寸，讓 CSS 接管
    clone.removeAttribute('width');
    clone.removeAttribute('height');
    clone.removeAttribute('style');
    content.appendChild(clone);
    modal.classList.add('mz-open');
  }

  function bindMermaidClicks() {
    // mermaid 11+ 把渲染後的 SVG 直接放在 <pre class="mermaid"> 內，
    // 偶爾也可能是 <div class="mermaid">，兩者都處理。
    document.querySelectorAll(
      'pre.mermaid svg, div.mermaid svg, .mermaid > svg'
    ).forEach((svg) => {
      if (svg.dataset.zoomBound) return;
      svg.dataset.zoomBound = 'true';
      svg.classList.add('mz-clickable');
      svg.addEventListener('click', () => openZoom(svg));
    });
  }

  // Mermaid 是非同步渲染，用 MutationObserver 監聽新出現的 SVG。
  const observer = new MutationObserver(bindMermaidClicks);
  observer.observe(document.body, { childList: true, subtree: true });

  // 第一次嘗試（mermaid 可能已經渲染完）
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', bindMermaidClicks);
  } else {
    bindMermaidClicks();
  }
})();
