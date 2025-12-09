// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers/index"
import "header_dropdown"

// スクロール位置の保存と復元（デバッグ用ログ付き）
(function() {
  let isNavigatingBack = false

  // Turbo遷移前に保存
  document.addEventListener('turbo:before-visit', () => {
    const pos = window.scrollY
    sessionStorage.setItem('scrollPos_' + window.location.pathname, pos)
    console.log('[Scroll] Saved:', window.location.pathname, pos)
  })

  // クリックで遷移する場合はフラグをリセット
  document.addEventListener('turbo:click', () => {
    console.log('[Scroll] Click detected, reset flag')
    isNavigatingBack = false
  })

  // 戻る/進む検知
  window.addEventListener('popstate', () => {
    console.log('[Scroll] Popstate detected (back/forward)')
    isNavigatingBack = true
  })

  // ページ描画完了後に復元
  document.addEventListener('turbo:render', () => {
    console.log('[Scroll] Render, isNavigatingBack:', isNavigatingBack)
    if (isNavigatingBack) {
      const saved = sessionStorage.getItem('scrollPos_' + window.location.pathname)
      console.log('[Scroll] Saved position for', window.location.pathname, ':', saved)
      if (saved) {
        requestAnimationFrame(() => {
          requestAnimationFrame(() => {
            console.log('[Scroll] Restoring to:', saved)
            window.scrollTo(0, parseInt(saved))
          })
        })
      }
      isNavigatingBack = false
    }
  })
})()

// English Conversation page specific
if (window.location.pathname === '/english_conversation') {
  import("english_conversation")
}