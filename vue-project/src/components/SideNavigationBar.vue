<template>
  <nav class="side-nav">
    <div class="side-nav-logo">
      <img src="@/assets/logo.png" alt="신일제약 실적관리" class="logo-image" />
    </div>
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
          <div class="side-nav-profile-email" :title="companyName">
            {{ companyName.length > 10 ? companyName.slice(0, 10) + '...' : companyName }}
          </div>
          <div class="side-nav-profile-role">{{ userRole === 'admin' ? '관리자' : '사용자' }}</div>
        </div>
      </div>
      <button class="side-nav-logout" @click="handleLogout" style="text-align: center;">로그아웃</button>
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

const companyName = ref('');

// 대메뉴/중메뉴 구조
const adminMenuTree = [
  { label: '공지사항 관리', icon: 'pi pi-bell', children: [
    { label: '공지사항 목록', path: '/admin/notices' }
  ]},
  { label: '업체 관리', icon: 'pi pi-users', children: [
    { label: '승인 업체', path: '/admin/companies/approved' },
    { label: '미승인 업체', path: '/admin/companies/pending' }
  ]},
  { label: '제품 관리', icon: 'pi pi-briefcase', children: [
    { label: '제품 목록', path: '/admin/products' }
  ]},
  { label: '거래처 관리', icon: 'pi pi-building', children: [
    { label: '거래처 목록', path: '/admin/clients' },
    { label: '담당업체 지정', path: '/admin/clients/assign-companies' },
    { label: '문전약국 지정', path: '/admin/clients/assign-pharmacies' }
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
    { label: '업체별 등록 현황', path: '/admin/performance/companies' },
    { label: '전체 등록 현황', path: '/admin/performance/whole' }
  ]},
  { label: '정산 관리', icon: 'pi pi-file', children: [
    { label: '흡수율 분석', path: '/admin/absorption-analysis' },
    { label: '정산내역서 공유', path: '/admin/settlement-share' }
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
    { label: '등록 현황', path: '/performance/list' }
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
  return route.path === item.path;
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

onMounted(async () => {
  window.__goToNotice = (id) => {
    router.push(`/notices/${id}`);
  };
  // ...기존 데이터 불러오기 코드...
  try {
    const { data: { session } } = await supabase.auth.getSession();
    if (session?.user) {
      const { data, error } = await supabase
        .from('companies')
        .select('company_name')
        .eq('user_id', session.user.id)
        .single();
      if (!error && data && data.company_name) {
        companyName.value = data.company_name;
      }
    }
  } catch {}
});
</script>

<style scoped>
.side-nav {
  position: fixed;
  top: 0;
  left: 0;
  height: 100vh;
  width: 210px;
  background: var(--bg-sidebar);
  color: var(--text-primary);
  display: flex;
  flex-direction: column;
  border-right: 1px solid var(--border-secondary);
  z-index: var(--z-index-sidebar);
}
.side-nav-logo {
  height: 54px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 1.25rem;
  color: var(--primary-color);
}
.logo-image {
  max-height: 40px;
  max-width: 180px;
  object-fit: contain;
}
.side-nav-list {
  flex: 1;
  list-style: none;
  margin: 0;
  padding-top: 1rem;
  padding-bottom: 1rem;
  overflow-y: auto;
}
.side-nav-section {
  margin-bottom: 0.25rem;
}
.side-nav-section-label {
  padding: 0.4rem 0;
  display: flex;
  align-items: center;
  font-size: 1.12rem;
  color: var(--text-primary) !important;
  font-weight: 700 !important;
  background: transparent;
  border-radius: 0;
  cursor: pointer;
  transition: background-color 0.2s ease-in-out, color 0.2s ease-in-out;
  gap: 0.5rem;
  text-shadow: none;
}

.side-nav-section-label:hover {
  
  background-color: var(--primary-color-lightest);
  color: #333;
  border-radius: 6px;
  margin-right: 1.5rem;
}
.side-nav-section-label.open {
  color: var(--primary-color) !important;
  font-weight: 700 !important;
}
.side-nav-section-icon {
  font-size: 1rem;
  color: var(--text-secondary);
  transition: color 0.2s ease-in-out;
  margin-right: 0;
}
.side-nav-section-label:hover .side-nav-section-icon,
.side-nav-section-label.open .side-nav-section-icon {
  color: var(--primary-color) !important;
}
.side-nav-sub-list {
  list-style: none;
  margin: 0;
  padding: 0.25rem 0;
}
.side-nav-sub-item {
  display: flex;
  align-items: center;
  cursor: pointer;
  padding: 0.4rem 1rem 0.4rem 1.6rem;
  color: var(--text-secondary);
  font-size: 0.95rem;
  font-weight: 600;
  background: transparent;
  border-radius: 8;
  transition: background-color 0.2s ease-in-out, color 0.2s ease-in-out;
}
.side-nav-sub-item.active {
  background-color: var(--primary-color);
  color: #fff;
  font-weight: 600;
  border-radius: 6px;
  margin-right: 1.5rem;
}
.side-nav-sub-item:not(.active):hover {
  background-color: var(--primary-color-lightest);
  border-radius: 6px;
  margin-right: 1.5rem;
}



.side-nav-bottom {
  border-top: 1px solid var(--border-secondary);
  padding: 1rem 1rem;
  background: var(--bg-sidebar);
}
.side-nav-profile {
  display: flex;
  align-items: center;
  margin-bottom: 0.75rem;
}
.side-nav-profile-icon {
  font-size: 1.4rem;
  color: var(--text-secondary);
  margin-left: 1rem;
}
.side-nav-profile-info {
  display: flex;
  flex-direction: column;
}
.side-nav-profile-email {
  font-size: 1rem;
  color: var(--text-primary);
  margin-left: 1rem;
  font-weight: 500;
}
.side-nav-profile-role {
  font-size: 0.9rem;
  color: var(--text-secondary);
  margin-left: 1rem;
}
.side-nav-logout {
  background: transparent;
  border: none;
  color: var(--text-secondary);
  font-size: 0.9rem;
  cursor: pointer;
  text-decoration: none;
  transition: color 0.15s;
  display: block;
  width: 100%;
  text-align: left;
  margin-bottom: 0.5rem;
}
.side-nav-logout:hover {
  color: var(--primary-color);
  text-decoration-line: underline;
}
</style> 