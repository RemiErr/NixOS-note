// Mermaid zoom modal
//
// 點擊任何 Mermaid 圖會開啟全螢幕浮層，支援：
//   - 滾輪縮放（以游標位置為中心）
//   - 拖曳平移
//   - 控制列按鈕（放大 / 縮小 / 重設 / 關閉）
//   - ESC / 點背景關閉
//   - 鍵盤：+ / - / 0
//
// 與 mermaid-init.js 配合使用。本檔在 book.toml 的 additional-js 中註冊。

(() => {
  const DEBUG = false; // 改 true 可在 console 看到綁定 / 觸發紀錄
  const log = (...args) => { if (DEBUG) console.debug('[mermaid-zoom]', ...args); };

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
        <button class="mz-btn" data-action="zoom-in" aria-label="放大" title="放大 (+)">+</button>
        <button class="mz-btn" data-action="zoom-out" aria-label="縮小" title="縮小 (−)">−</button>
        <button class="mz-btn" data-action="reset" aria-label="重設" title="重設 (0)">⟳</button>
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
      setTimeout(() => { content.innerHTML = ''; reset(); }, 150);
    }
    function zoomIn() { state.scale = clamp(state.scale * ZOOM_STEP, MIN_SCALE, MAX_SCALE); apply(); }
    function zoomOut() { state.scale = clamp(state.scale / ZOOM_STEP, MIN_SCALE, MAX_SCALE); apply(); }

    modal.querySelector('.mz-backdrop').addEventListener('click', close);

    modal.querySelectorAll('.mz-btn').forEach((btn) => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        const a = btn.dataset.action;
        if (a === 'zoom-in') zoomIn();
        else if (a === 'zoom-out') zoomOut();
        else if (a === 'reset') reset();
        else if (a === 'close') close();
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
      e.preventDefault();
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

    // 觸控
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

    // 鍵盤
    document.addEventListener('keydown', (e) => {
      if (!modal.classList.contains('mz-open')) return;
      if (e.key === 'Escape') close();
      else if (e.key === '0') reset();
      else if (e.key === '+' || e.key === '=') zoomIn();
      else if (e.key === '-' || e.key === '_') zoomOut();
    });

    return modal;
  }

  function openZoom(sourceSvg) {
    log('open zoom for', sourceSvg);
    const modal = ensureModal();
    const content = modal.querySelector('.mz-content');
    content.innerHTML = '';
    const clone = sourceSvg.cloneNode(true);
    clone.removeAttribute('width');
    clone.removeAttribute('height');
    clone.removeAttribute('style');
    content.appendChild(clone);
    modal.classList.add('mz-open');
  }

  // 找出點擊事件對應的 mermaid SVG（若有）
  function findMermaidSvg(target) {
    if (!target || target.nodeType !== 1) return null;
    // closest 會往上找最近的 mermaid 容器
    const container = target.closest(
      'pre.mermaid, div.mermaid, .mermaid'
    );
    if (!container) return null;
    return container.querySelector('svg');
  }

  // 事件委派：綁在 document 上，比個別綁在 SVG 上更穩
  // （不會被後續渲染、mermaid 內部事件、或 SVG 重新生成影響）
  document.addEventListener('click', (e) => {
    // 浮層內的點擊由 modal 自己處理
    if (e.target.closest('#mermaid-zoom-modal')) return;
    const svg = findMermaidSvg(e.target);
    if (!svg) return;
    e.preventDefault();
    e.stopPropagation();
    openZoom(svg);
  }, true); // capture 階段，避免被 mermaid 內部 handler 攔截

  log('initialized: click delegation active');
})();
