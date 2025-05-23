<template>
  <nav class="side-nav">
    <div class="side-nav-logo">신일제약 실적관리</div>
    <ul class="side-nav-list">
      <li v-for="(menu, idx) in menuTree" :key="menu.label" class="side-nav-section">
        <div class="side-nav-section-label" :class="{ open: openMenu === idx }" @click="toggleMenu(idx)">
          <i :class="menu.icon" class="side-nav-section-icon"></i>
          <span>{{ menu.label }}</span>
        </div>
        <ul v-if="openMenu === idx" class="side-nav-sub-list">
          <li v-for="item in menu.children" :key="item.label" :class="['side-nav-sub-item', { active: isActive(item) }]" @click="go(item)">
            <span class="side-nav-sub-label" :class="{ 'active-bg': isActive(item) }">{{ item.label }}</span>
          </li>
        </ul>
      </li>
    </ul>
    <div class="side-nav-bottom">
      <div class="side-nav-profile">
        <i class="pi pi-user side-nav-profile-icon"></i>
        <div class="side-nav-profile-info">
          <div class="side-nav-profile-email">{{ userEmail }}</div>
          <div class="side-nav-profile-role">{{ userRole === 'admin' ? '관리자' : '사용자' }}</div>
        </div>
      </div>
      <button class="side-nav-logout" @click="handleLogout">로그아웃</button>
    </div>
  </nav>
</template>

<script setup>
import { ref, computed, onMounted, h } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { supabase } from '@/supabase';

const props = defineProps({
  userRole: { type: String, required: true },
  userEmail: { type: String, default: '' }
});
const emit = defineEmits(['logout']);
const router = useRouter();
const route = useRoute();
const openMenu = ref(0); // 첫 번째 대메뉴 기본 오픈

// 대메뉴/중메뉴 구조
const adminMenuTree = [
  { label: '공지사항 관리', icon: 'pi pi-bell', children: [
    { label: '공지사항 목록', path: '/admin/notices' }
  ]},
  { label: '업체 관리', icon: 'pi pi-users', children: [
    { label: '승인 업체 목록', path: '/admin/companies/approved' },
    { label: '미승인 업체 목록', path: '/admin/companies/pending' }
  ]},
  { label: '제품 관리', icon: 'pi pi-briefcase', children: [
    { label: '제품 목록', path: '/admin/products' }
  ]},
  { label: '거래처 관리', icon: 'pi pi-building', children: [
    { label: '거래처 목록', path: '/admin/clients' }
  ]},
  { label: '문전약국 관리', icon: 'pi pi-home', children: [
    { label: '문전약국 목록', path: '/admin/pharmacies' }
  ]},
  { label: '매출 관리', icon: 'pi pi-chart-bar', children: [
    { label: '도매매출 목록', path: '/admin/wholesale-revenue' },
    { label: '직거래매출 목록', path: '/admin/direct-revenue' }
  ]},
  { label: '실적 관리', icon: 'pi pi-pencil', children: [
    { label: '정산월 관리', path: '/admin/settlement-months' },
    { label: '실적 입력', path: '/admin/performance-input' },
    { label: '내역 조회', path: '/admin/performance-list' }
  ]},
  { label: '정산내역서 관리', icon: 'pi pi-file', children: [
    { label: '월별 정산 목록', path: '/admin/settlement-statements' }
  ]}
];
const userMenuTree = [
  { label: '공지사항 조회', icon: 'pi pi-bell', children: [
    { label: '공지사항 목록', path: '/notices' }
  ]},
  { label: '제품 조회', icon: 'pi pi-briefcase', children: [
    { label: '제품 목록', path: '/products' }
  ]},
  { label: '거래처 조회', icon: 'pi pi-building', children: [
    { label: '거래처 목록', path: '/clients' }
  ]},
  { label: '실적 관리', icon: 'pi pi-pencil', children: [
    { label: '실적 등록', path: '/performance/register' },
    { label: '등록 현황', path: '/performance/list' },
    { label: '증빙 파일 제출', path: '/performance/upload' }
  ]},
  { label: '정산내역서 조회', icon: 'pi pi-file', children: [
    { label: '월별 정산 목록', path: '/settlements' }
  ]},
  { label: '내 정보', icon: 'pi pi-user', children: [
    { label: '내 정보', path: '/my-info' }
  ]}
];
const menuTree = computed(() => props.userRole === 'admin' ? adminMenuTree : userMenuTree);

function go(item) {
  if (item.path) router.push(item.path);
}
function isActive(item) {
  return route.path.startsWith(item.path);
}
function toggleMenu(idx) {
  openMenu.value = openMenu.value === idx ? null : idx;
}

const breadcrumbSubMenu = computed(() => {
  for (const menu of menuTree.value) {
    for (const child of menu.children) {
      if (route.path.startsWith(child.path)) {
        return child.label;
      }
    }
  }
  return '';
});

const handleLogout = async () => {
  await supabase.auth.signOut();
  router.push('/login');
};

const titleTemplate = (row) => {
  return h(
    'a',
    {
      style: 'color:#1976d2;text-decoration:underline;cursor:pointer;',
      onClick: () => router.push(`/notices/${row.id}`)
    },
    row.title
  );
};

function goToDetail(id) {
  router.push(`/notices/${id}`);
}

const files = ref([]); // 여러 파일 저장

function onFileChange(e) {
  const selected = Array.from(e.target.files);
  // 기존 파일 + 새로 선택한 파일 합치기, 최대 5개
  files.value = files.value.concat(selected).slice(0, 5);
  // input value 초기화(같은 파일 다시 선택 가능)
  e.target.value = '';
}

function removeFile(idx) {
  files.value.splice(idx, 1);
}

onMounted(() => {
  window.__goToNotice = (id) => {
    router.push(`/notices/${id}`);
  };
  // ...기존 데이터 불러오기 코드...
});
</script>

<style scoped>
.side-nav {
  position: fixed;
  top: 0;
  left: 0;
  height: 100vh;
  width: 220px;
  background: #fff;
  color: #222;
  display: flex;
  flex-direction: column;
  border-right: 1px solid #e5e7eb;
  z-index: 1000;
  font-size: 14px;
}
.side-nav-logo {
  height: 56px;
  display: flex;
  align-items: center;
  font-weight: bold;
  font-size: 1.18rem;
  color: #5fa56b;
  padding-left: 28px;
  border-bottom: 1px solid #e5e7eb;
  letter-spacing: 0.01em;
}
.side-nav-list {
  flex: 1;
  list-style: none;
  margin: 0;
  padding: 16px 0 0 0;
}
.side-nav-section {
  margin-bottom: 2px;
}
.side-nav-section-label {
  padding: 0 18px;
  height: 40px;
  display: flex;
  align-items: center;
  font-size: 15px;
  color: #222;
  font-weight: bold;
  background: #fff;
  border-radius: 6px;
  cursor: pointer;
  transition: background 0.15s, color 0.15s;
  gap: 10px;
}
.side-nav-section-icon {
  font-size: 1.0rem;
  color: #222;
  font-weight: 700;
}
.side-nav-section-label.open, .side-nav-section-label:hover {
  background: #fff;
  color: #222;
}
.side-nav-sub-list {
  list-style: none;
  margin: 0;
  padding: 0;
}
.side-nav-sub-item {
  display: flex;
  align-items: center;
  cursor: pointer;
  padding: 0 0 0 44px;
  height: 34px;
  color: #222;
  font-size: 14px;
  font-weight: 700;
  background: #fff;
  border-radius: 0 6px 6px 0;
  margin-bottom: 1px;
  transition: background 0.15s, color 0.15s;
}
.side-nav-sub-label {
  display: inline-block;
  padding: 4px 24px 4px 10px;
  border-radius: 6px;
  transition: background 0.15s, color 0.15s;
}
.side-nav-sub-label.active-bg {
  background: #5fa56b;
  color: #fff;
  width: calc(100% - 24px);
}
.side-nav-sub-item.active .side-nav-sub-label {
  background: #5fa56b;
  color: #fff;
  width: calc(100% - 24px);
}
.side-nav-sub-item:hover .side-nav-sub-label {
  background: #eaf6ee;
  color: #5fa56b;
}
.side-nav-bottom {
  border-top: 1px solid #e5e7eb;
  padding: 18px 18px 14px 18px;
  background: #fff;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}
.side-nav-profile {
  display: flex;
  align-items: center;
  margin-bottom: 8px;
}
.side-nav-profile-icon {
  font-size: 1.5rem;
  color: #222;
  margin-right: 10px;
}
.side-nav-profile-info {
  display: flex;
  flex-direction: column;
}
.side-nav-profile-email {
  font-size: 13px;
  color: #222;
  font-weight: 500;
}
.side-nav-profile-role {
  font-size: 12px;
  color: #444;
}
.side-nav-logout {
  background: none;
  border: none;
  color: #4caf50;
  font-size: 13px;
  cursor: pointer;
  padding: 8px;
  margin: 8px auto 0 auto;
  text-decoration: underline;
  transition: color 0.15s;
  display: block;
  width: 100%;
  text-align: center;
}
.side-nav-logout:hover {
  color: #388e3c;
}
.file-list {
  margin-top: 6px;
}
.file-item {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 2px;
  font-size: 0.97rem;
}
.file-remove {
  color: #e74c3c;
  cursor: pointer;
  font-weight: bold;
  margin-left: 4px;
}
.file-remove:hover {
  text-decoration: underline;
}
</style> 