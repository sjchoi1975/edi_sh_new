<template>
  <div class="top-nav-bar">
    <!-- 테스트용 라우터 링크가 있던 div 전체 삭제 -->

    <!-- 새로운 헤더 영역 -->
    <div class="header-content-area">
      <div class="page-title-display">{{ pageTitle }}</div>
      <div class="user-info-display">
        <span class="user-email-text">{{ userEmail }}</span>
        <Button label="로그아웃" icon="pi pi-sign-out" class="p-button-sm p-button-text logout-button" @click="requestLogout" />
      </div>
    </div>

    <!-- 메뉴바 -->
    <Menubar :model="menuItems" class="actual-menubar" />
    <!-- Menubar 내부의 <template #start> 와 <template #end> 는 제거됨 -->
  </div>
</template>

<script setup>
import { computed } from 'vue';
import Menubar from 'primevue/menubar';
import Button from 'primevue/button';
import { useRouter } from 'vue-router';

const props = defineProps({
  userRole: {
    type: String,
    required: true,
    default: 'user'
  },
  userEmail: {
    type: String,
    default: ''
  }
});

const emit = defineEmits(['logout']);

const router = useRouter();

const pageTitle = computed(() => {
  // 원래 로직으로 복원: 사용자 역할에 따라 고정된 페이지 제목 반환
  return props.userRole === 'admin' ? '신일제약 실적관리 관리자페이지' : '신일제약 실적관리';
});

const createMenuItem = (label, path) => ({
  label,
  path, // 경로(path)를 메뉴 아이템 객체에 추가
  command: () => { router.push(path); }
});

const adminMenu = [
  {
    label: '공지사항 관리',
    items: [
      createMenuItem('공지사항 목록', '/admin/notices'),
    ]
  },
  {
    label: '업체 관리',
    items: [
      createMenuItem('업체 목록', '/admin/companies'),
    ]
  },
  {
    label: '제품 관리',
    items: [
      createMenuItem('제품 목록', '/admin/products'),
    ]
  },
  {
    label: '거래처 관리',
    items: [
      createMenuItem('거래처 목록', '/admin/clients'),
    ]
  },
  {
    label: '문전약국 관리',
    items: [
      createMenuItem('문전약국 목록', '/admin/pharmacies'),
    ]
  },
  {
    label: '매출 관리',
    items: [
      createMenuItem('도매매출 목록', '/admin/wholesale-revenue'),
      createMenuItem('직거래매출 목록', '/admin/direct-revenue'),
    ]
  },
  {
    label: '실적 관리',
    items: [
      createMenuItem('정산월 관리', '/admin/settlement-month'),
      createMenuItem('실적 입력', '/admin/performance-input'),
      createMenuItem('내역 조회', '/admin/performance-view'),
    ]
  },
  {
    label: '정산 관리',
    items: [
      createMenuItem('정산내역서', '/admin/settlement-statements'),
    ]
  },
];

const userMenu = [
  {
    label: '공지사항',
    items: [
      createMenuItem('공지사항 목록', '/notices'),
    ]
  },
  {
    label: '제품 조회',
    items: [
      createMenuItem('제품 목록', '/products'),
    ]
  },
  {
    label: '거래처 조회',
    items: [
      createMenuItem('거래처 목록', '/clients'),
    ]
  },
  {
    label: '실적 관리',
    items: [
      createMenuItem('실적 등록', '/performance/register'),
      createMenuItem('등록 현황', '/performance/status'),
      createMenuItem('증빙 파일 제출', '/performance/proof-submission'),
    ]
  },
  {
    label: '정산내역서',
    items: [
      createMenuItem('정산내역서', '/settlements'),
    ]
  },
  createMenuItem('내 정보', '/my-info'),
];

const menuItems = computed(() => {
  const fullAdminMenu = [
    { label: '공지사항 관리', items: [createMenuItem('공지사항 목록', '/admin/notices')] },
    { label: '업체 관리', items: [createMenuItem('업체 목록', '/admin/companies')] },
    { label: '제품 관리', items: [createMenuItem('제품 목록', '/admin/products')] },
    { label: '거래처 관리', items: [createMenuItem('거래처 목록', '/admin/clients')] },
    { label: '문전약국 관리', items: [createMenuItem('문전약국 목록', '/admin/pharmacies')] },
    { label: '매출 관리', items: [createMenuItem('도매매출 목록', '/admin/wholesale-revenue'), createMenuItem('직거래매출 목록', '/admin/direct-revenue')] },
    { label: '실적 관리', items: [createMenuItem('정산월 관리', '/admin/settlement-month'), createMenuItem('실적 입력', '/admin/performance-input'), createMenuItem('내역 조회', '/admin/performance-view')] },
    { label: '정산 관리', items: [createMenuItem('정산내역서', '/admin/settlement-statements')] },
  ];

  const fullUserMenu = [
    { label: '공지사항', items: [createMenuItem('공지사항 목록', '/notices')] },
    { label: '제품 조회', items: [createMenuItem('제품 목록', '/products')] },
    { label: '거래처 조회', items: [createMenuItem('거래처 목록', '/clients')] },
    { label: '실적 관리', items: [createMenuItem('실적 등록', '/performance/register'), createMenuItem('등록 현황', '/performance/status'), createMenuItem('증빙 파일 제출', '/performance/proof-submission')] },
    { label: '정산내역서', items: [createMenuItem('정산내역서', '/settlements')] },
    createMenuItem('내 정보', '/my-info'),
  ];
  return props.userRole === 'admin' ? fullAdminMenu : fullUserMenu;
});

const requestLogout = () => {
  emit('logout');
};

</script>

<style scoped>
.top-nav-bar { /* 전체 컴포넌트 래퍼 */
  display: flex;
  flex-direction: column;
  width: 100%;
}

.header-content-area { /* 페이지 제목, 사용자 정보가 들어갈 상단 바 */
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 1rem; /* 상하좌우 패딩 */
  background-color: #ffffff; /* 흰색 배경 */
  border-bottom: 1px solid #dee2e6; /* 하단 구분선 */
  color: #212529; /* 기본 텍스트 색상 */
}

.page-title-display { /* 페이지 제목 텍스트 */
  font-size: 1.2em;
  font-weight: bold;
}

.user-info-display { /* 사용자 이메일 및 로그아웃 버튼 래퍼 */
  display: flex;
  align-items: center;
}

.user-email-text { /* 사용자 이메일 텍스트 */
  margin-right: 1rem;
  font-size: 0.9rem; /* 약간 작게 */
}

.user-info-display .logout-button.p-button-text { /* 로그아웃 버튼 (텍스트 형태일 때) */
  color: #007bff; /* 파란색 계열 */
}

.user-info-display .logout-button.p-button-text .pi { /* 로그아웃 버튼 아이콘 */
  color: #007bff; /* 파란색 계열 */
}

/* PrimeVue Menubar 자체 스타일 */
.actual-menubar.p-menubar {
  background-color: #004D40 !important;
  color: #ffffff !important;
  border-radius: 0;
  border: none;
  width: 100%; /* 메뉴바는 전체 너비 */
  padding: 1.0rem 0; /* 메뉴바 자체 상하 패딩 */
  box-shadow: none;
}

/* 메뉴 아이템 리스트 (ul) 스타일 */
:deep(.actual-menubar.p-menubar .p-menubar-root-list) {
  max-width: 1280px;    /* 최대 너비 1280px */
  width: 100%;           /* 부모(1280px) 내에서 꽉 차도록 */
  margin: 0 auto;        /* 수평 중앙 정렬 */
  display: flex;         /* 내부 li들을 정렬하기 위해 */
  justify-content: center; /* li 메뉴 아이템들을 중앙에 배치 */
}

/* 새로운 규칙: 각 메뉴 아이템 링크에 패딩 추가 */
:deep(.actual-menubar.p-menubar .p-menuitem > .p-menuitem-content > .p-menuitem-link) {
  padding: 0.75rem 1.25rem; /* 아이템 내부 패딩 */
  display: flex;
  align-items: center;
}

/* 최상위 메뉴 아이템 링크 자체와 그 내부의 모든 요소에 흰색 적용 */
:deep(.actual-menubar.p-menubar .p-menubar-root-list > .p-menuitem > .p-menuitem-content > a.p-menuitem-link) {
  color: #ffffff !important;
}

/* 기존 메뉴 아이템 텍스트/아이콘 색상 지정 규칙은 위 규칙으로 대체되거나 보강되므로 주석 처리 또는 삭제 가능 */
/*
:deep(.actual-menubar.p-menubar .p-menubar-root-list > .p-menuitem > .p-menuitem-content .p-menuitem-link .p-menuitem-text),
:deep(.actual-menubar.p-menubar .p-menubar-root-list > .p-menuitem > .p-menuitem-content .p-menuitem-link > .p-menuitem-icon),
:deep(.actual-menubar.p-menubar .p-menubar-root-list > .p-menuitem > .p-menuitem-content .p-menuitem-link > .p-submenu-icon) {
  color: #ffffff !important;
}
*/

/* 드롭다운 메뉴의 아이템 링크에 직접 색상 적용 */
:deep(.p-menubar .p-submenu-list .p-menuitem-link) { /* 링크 자체에 적용 */
 color: #333333 !important; /* 드롭다운 내부 링크는 어두운 색으로 */
}

/* 기존 드롭다운 메뉴 텍스트 색상 규칙은 위 규칙으로 대체되므로 주석 처리 또는 삭제 가능 */
/*
:deep(.p-menubar .p-submenu-list .p-menuitem-link .p-menuitem-text) {
 color: #333333; 
}
*/

/* 활성/포커스된 최상위 메뉴 아이템 배경 */
:deep(.actual-menubar.p-menubar .p-menubar-root-list > .p-menuitem.p-focus > .p-menuitem-content) {
  background-color: #00382e !important; /* 기존보다 약간 어두운 녹색 */
}

/* 열린 하위 메뉴 배경 */
:deep(.p-menubar .p-submenu-list) {
  background-color: #f8f9fa; /* 밝은 회색 */
}

/* 하위 메뉴 아이템 호버 시 배경 */
:deep(.p-menubar .p-menuitem .p-menuitem-link:hover) {
  background-color: #e9ecef;
}

/* 이전 스타일 클래스 (이제 사용되지 않거나 용도 변경됨) 에 대한 규칙은 제거하거나,
   영향이 없다면 그대로 두어도 무방하지만 정리를 위해 제거하는 것이 좋음.
   .page-title-container, .user-info-container (이전 Menubar 슬롯용)
   .page-title, .user-info, .user-email (이전 Menubar 슬롯용)
   :deep(.p-menubar-start), :deep(.p-menubar-end) (이전 슬롯 패딩용)
   기존 .top-nav-bar .p-menubar 에 있던 padding:0 은 .actual-menubar.p-menubar 로 옮겨가면서 padding: 0 1rem; 로 변경됨.
*/
</style> 