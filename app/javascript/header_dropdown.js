// ヘッダードロップダウンメニューの共通JavaScript
document.addEventListener('DOMContentLoaded', function() {
  const mobileMenuToggle = document.querySelector('.mobile-menu-toggle');
  const headerNav = document.querySelector('.header-nav');
  const dropdownTriggers = document.querySelectorAll('.dropdown-trigger');

  // Mobile menu functionality
  if (mobileMenuToggle && headerNav) {
    mobileMenuToggle.addEventListener('click', function() {
      mobileMenuToggle.classList.toggle('active');
      headerNav.classList.toggle('active');
    });

    // Close menu when clicking outside
    document.addEventListener('click', function(event) {
      if (!mobileMenuToggle.contains(event.target) && !headerNav.contains(event.target)) {
        mobileMenuToggle.classList.remove('active');
        headerNav.classList.remove('active');
      }
    });

    // Close menu when clicking on a link
    const navLinks = document.querySelectorAll('.nav-link:not(.dropdown-trigger)');
    navLinks.forEach(link => {
      link.addEventListener('click', function() {
        mobileMenuToggle.classList.remove('active');
        headerNav.classList.remove('active');
      });
    });
  }

  // Dropdown functionality
  dropdownTriggers.forEach(trigger => {
    const dropdown = trigger.closest('.nav-dropdown');
    
    // Debug: ドロップダウン要素が正しく取得できているか確認
    console.log('Dropdown trigger found:', trigger);
    console.log('Dropdown container found:', dropdown);
    
    // Click to toggle dropdown
    trigger.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();
      
      console.log('Dropdown trigger clicked');
      
      // Close other dropdowns
      document.querySelectorAll('.nav-dropdown').forEach(otherDropdown => {
        if (otherDropdown !== dropdown) {
          otherDropdown.classList.remove('active', 'show');
        }
      });
      
      // Toggle current dropdown
      const isActive = dropdown.classList.contains('active') || dropdown.classList.contains('show');
      
      if (isActive) {
        dropdown.classList.remove('active', 'show');
        console.log('Dropdown closed');
      } else {
        dropdown.classList.add('active', 'show');
        // 強制的にスタイルを適用
        const menu = dropdown.querySelector('.dropdown-menu');
        if (menu) {
          menu.style.opacity = '1';
          menu.style.visibility = 'visible';
          menu.style.transform = 'translateY(0)';
          menu.style.pointerEvents = 'auto';
        }
        console.log('Dropdown opened');
      }
    });
    
    // Mouse enter/leave for desktop with delay
    let hoverTimeout;
    
    dropdown.addEventListener('mouseenter', function() {
      if (window.innerWidth > 768) {
        clearTimeout(hoverTimeout);
        dropdown.classList.add('active');
      }
    });
    
    dropdown.addEventListener('mouseleave', function() {
      if (window.innerWidth > 768) {
        // 少し遅延を追加してカーソル移動時の誤閉じを防ぐ
        hoverTimeout = setTimeout(() => {
          // クリックで開いた場合は閉じない
          if (!dropdown.classList.contains('show')) {
            dropdown.classList.remove('active');
          }
        }, 150);
      }
    });

    // ドロップダウンメニュー自体でのマウスイベント
    const dropdownMenu = dropdown.querySelector('.dropdown-menu');
    if (dropdownMenu) {
      dropdownMenu.addEventListener('mouseenter', function() {
        if (window.innerWidth > 768) {
          clearTimeout(hoverTimeout);
          dropdown.classList.add('active');
        }
      });

      dropdownMenu.addEventListener('mouseleave', function() {
        if (window.innerWidth > 768) {
          hoverTimeout = setTimeout(() => {
            if (!dropdown.classList.contains('show')) {
              dropdown.classList.remove('active');
            }
          }, 150);
        }
      });
    }
  });

  // Close dropdowns when clicking outside
  document.addEventListener('click', function(event) {
    const isDropdownClick = event.target.closest('.nav-dropdown');
    const isDropdownItem = event.target.closest('.dropdown-item');
    
    if (!isDropdownClick) {
      document.querySelectorAll('.nav-dropdown').forEach(dropdown => {
        dropdown.classList.remove('active', 'show');
        // インラインスタイルもクリア
        const menu = dropdown.querySelector('.dropdown-menu');
        if (menu) {
          menu.style.opacity = '';
          menu.style.visibility = '';
          menu.style.transform = '';
          menu.style.pointerEvents = '';
        }
      });
    }
    
    // ドロップダウンアイテムがクリックされた場合
    if (isDropdownItem && !isDropdownItem.classList.contains('disabled')) {
      // アクティブなリンクの場合のみ閉じる
      if (isDropdownItem.tagName === 'A' || isDropdownItem.onclick) {
        setTimeout(() => {
          document.querySelectorAll('.nav-dropdown').forEach(dropdown => {
            dropdown.classList.remove('active', 'show');
            const menu = dropdown.querySelector('.dropdown-menu');
            if (menu) {
              menu.style.opacity = '';
              menu.style.visibility = '';
              menu.style.transform = '';
              menu.style.pointerEvents = '';
            }
          });
        }, 100);
      }
    }
  });
});

// 開発中ポップアップ機能
function showDevelopmentModal(countryName) {
  const modal = document.createElement('div');
  modal.style.cssText = `
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    justify-content: center;
    align-items: center;
    z-index: 10000;
  `;
  
  const modalContent = document.createElement('div');
  modalContent.style.cssText = `
    background: white;
    padding: 40px;
    border-radius: 15px;
    text-align: center;
    max-width: 400px;
    width: 90%;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  `;
  
  modalContent.innerHTML = `
    <div style="font-size: 3rem; margin-bottom: 20px;">🚧</div>
    <h3 style="margin: 0 0 15px 0; color: #2c3e50; font-size: 1.5rem;">${countryName}は開発中です</h3>
    <p style="margin: 0 0 25px 0; color: #666; line-height: 1.6;">
      現在${countryName}の機能を開発中です。<br>
      しばらくお待ちください。
    </p>
    <button onclick="this.closest('.modal-overlay').remove()" style="
      background: #f5b342;
      color: white;
      border: none;
      padding: 12px 30px;
      border-radius: 25px;
      font-size: 16px;
      font-weight: 600;
      cursor: pointer;
      transition: background 0.3s ease;
    " onmouseover="this.style.background='#e09c2a'" onmouseout="this.style.background='#f5b342'">
      了解しました
    </button>
  `;
  
  modal.className = 'modal-overlay';
  modal.appendChild(modalContent);
  document.body.appendChild(modal);
  
  // モーダル外をクリックしても閉じる
  modal.addEventListener('click', function(e) {
    if (e.target === modal) {
      modal.remove();
    }
  });
}