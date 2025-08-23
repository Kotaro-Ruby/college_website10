// 注目の大学セクションの表示切り替え機能
document.addEventListener('DOMContentLoaded', function() {
  initializeFeaturedToggle();
});

document.addEventListener('turbo:load', function() {
  initializeFeaturedToggle();
});

function initializeFeaturedToggle() {
  // 表示切り替えアイコンを探す
  const toggleIcons = document.querySelectorAll('.view-toggle-icon, .toggle-view-icon, [data-toggle-view]');
  
  toggleIcons.forEach(icon => {
    // 既存のイベントリスナーを削除
    const newIcon = icon.cloneNode(true);
    icon.parentNode.replaceChild(newIcon, icon);
    
    newIcon.addEventListener('click', function() {
      toggleView(this);
    });
  });
  
  // グリッドアイコンとリストアイコンを個別に処理
  const gridIcon = document.querySelector('.fa-th, .grid-view-icon, [data-view="grid"]');
  const listIcon = document.querySelector('.fa-list, .list-view-icon, [data-view="list"]');
  
  if (gridIcon) {
    gridIcon.style.cursor = 'pointer';
    gridIcon.addEventListener('click', function() {
      setGridView();
    });
  }
  
  if (listIcon) {
    listIcon.style.cursor = 'pointer';
    listIcon.addEventListener('click', function() {
      setListView();
    });
  }
}

function toggleView(icon) {
  const section = icon.closest('.featured-section, .colleges-section, [data-section]');
  if (!section) return;
  
  const collegesContainer = section.querySelector('.colleges-grid, .featured-colleges, .colleges-container');
  if (!collegesContainer) return;
  
  // 現在の表示状態を切り替え
  if (collegesContainer.classList.contains('list-view')) {
    collegesContainer.classList.remove('list-view');
    collegesContainer.classList.add('grid-view');
    updateToggleIcon(icon, 'grid');
  } else {
    collegesContainer.classList.remove('grid-view');
    collegesContainer.classList.add('list-view');
    updateToggleIcon(icon, 'list');
  }
  
  // LocalStorageに保存
  localStorage.setItem('preferredView', collegesContainer.classList.contains('list-view') ? 'list' : 'grid');
}

function setGridView() {
  const containers = document.querySelectorAll('.colleges-grid, .featured-colleges, .colleges-container');
  containers.forEach(container => {
    container.classList.remove('list-view');
    container.classList.add('grid-view');
  });
  
  // アイコンの状態を更新
  document.querySelectorAll('.fa-th, .grid-view-icon').forEach(icon => {
    icon.classList.add('active');
  });
  document.querySelectorAll('.fa-list, .list-view-icon').forEach(icon => {
    icon.classList.remove('active');
  });
  
  localStorage.setItem('preferredView', 'grid');
}

function setListView() {
  const containers = document.querySelectorAll('.colleges-grid, .featured-colleges, .colleges-container');
  containers.forEach(container => {
    container.classList.remove('grid-view');
    container.classList.add('list-view');
  });
  
  // アイコンの状態を更新
  document.querySelectorAll('.fa-list, .list-view-icon').forEach(icon => {
    icon.classList.add('active');
  });
  document.querySelectorAll('.fa-th, .grid-view-icon').forEach(icon => {
    icon.classList.remove('active');
  });
  
  localStorage.setItem('preferredView', 'list');
}

function updateToggleIcon(icon, currentView) {
  if (icon.classList.contains('fa-th') || icon.classList.contains('fa-list')) {
    if (currentView === 'grid') {
      icon.classList.remove('fa-list');
      icon.classList.add('fa-th');
    } else {
      icon.classList.remove('fa-th');
      icon.classList.add('fa-list');
    }
  }
}

// ページ読み込み時に保存された表示設定を適用
function applySavedView() {
  const savedView = localStorage.getItem('preferredView');
  if (savedView === 'list') {
    setListView();
  } else {
    setGridView();
  }
}

// 初期化時に保存された設定を適用
document.addEventListener('DOMContentLoaded', applySavedView);