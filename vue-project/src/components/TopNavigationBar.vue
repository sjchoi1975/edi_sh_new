<template>
  <header class="top-nav">
    <div class="top-nav-breadcrumb">
      <span class="breadcrumb-menu">{{ breadcrumbMenu }}</span>
      <span class="breadcrumb-sep">&gt;</span>
      <span class="breadcrumb-submenu">{{ breadcrumbSubMenu }}</span>
    </div>
  </header>
</template>

<script setup>
const props = defineProps({
  breadcrumbMenu: { type: String, default: '' },
  breadcrumbSubMenu: { type: String, default: '' }
});
const emit = defineEmits(['logout']);
</script>

<style scoped>
.top-nav {
  height: 54px; /* 사이드바 로고 높이와 동기화 */
  background: var(--bg-topbar); /* CSS 변수 사용 (흰색) */
  color: var(--text-primary);
  display: flex;
  align-items: center;
  justify-content: space-between; /* 오른쪽 사용자 메뉴 등을 위한 공간 확보 */
  padding: 0 1.5rem; /* 좌우 패딩 (24px) */
  box-sizing: border-box;
  position: fixed;
  top: 0; /* 상단에 붙임 */
  left: 220px; /* 사이드바 너비와 일치시킴 */
  right: 0; /* 오른쪽 끝까지 확장 */
  z-index: var(--z-index-topbar);
  border-bottom: 1px solid var(--border-secondary); /* 구분선 색상 변경 */
  box-shadow: none; /* CleanPay 참고하여 그림자 제거 또는 var(--box-shadow-sm) */
}

.top-nav-breadcrumb {
  display: flex;
  align-items: center;
  margin-left: 0; /* 왼쪽 여백 제거 (top-nav 패딩 사용) */
  font-size: var(--font-size-md); /* 기본 폰트 크기 (15px) */
  gap: 0.5rem; /* 아이템 간 간격 */
}

.breadcrumb-menu {
  font-size: 0.95rem; /* 대메뉴 폰트 크기 (13px) */
  color: var(--text-secondary); /* 약간 연한 색 */
  font-weight: 500;
}

.breadcrumb-sep {
  color: var(--text-light); /* 더 연한 색 */
  margin: 0 0.25rem; /* 좌우 여백 약간 */
}

.breadcrumb-submenu {
  font-size: 1.2rem; /* 중메뉴 폰트 크기 (대메뉴보다 크게) */
  color: var(--text-primary); /* 더 진한 색 */
  font-weight: 600; /* 중메뉴 더 굵게 */
}

/* 사용자 정보, 알림, 설정 아이콘 등 우측 영역 스타일 (필요시 추가) */
/* .top-nav-actions { ... } */
</style> 