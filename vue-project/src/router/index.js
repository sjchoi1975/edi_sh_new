import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'
import LoginView from '../views/LoginView.vue'
import SignupView from '../views/SignupView.vue'
import AdminNoticesView from '../views/admin/AdminNoticesView.vue'
import NoticesView from '../views/NoticesView.vue'

// 새로 추가된 관리자용 컴포넌트 import
import AdminCompaniesView from '../views/admin/AdminCompaniesView.vue'
// import AdminApprovalRequestsView from '../views/admin/AdminApprovalRequestsView.vue' // 삭제
import AdminProductsView from '../views/admin/AdminProductsView.vue'
import AdminClientsView from '../views/admin/AdminClientsView.vue'
import AdminPharmaciesView from '../views/admin/AdminPharmaciesView.vue'
import AdminWholesaleRevenueView from '../views/admin/AdminWholesaleRevenueView.vue'
import AdminDirectRevenueView from '../views/admin/AdminDirectRevenueView.vue'
import AdminSettlementMonthView from '../views/admin/AdminSettlementMonthView.vue'
import AdminPerformanceInputView from '../views/admin/AdminPerformanceInputView.vue'
import AdminPerformanceViewView from '../views/admin/AdminPerformanceViewView.vue'
import AdminSettlementStatementsView from '../views/admin/AdminSettlementStatementsView.vue'
import AdminCompaniesApprovedView from '../views/admin/AdminCompaniesApprovedView.vue'
import AdminCompaniesPendingView from '../views/admin/AdminCompaniesPendingView.vue'

import { supabase } from '@/supabase'; // <<< Supabase 클라이언트 임포트
import { ref, onMounted } from 'vue'

function sanitizeFileName(name) {
  // 한글, 공백, 특수문자 제거 → 영문, 숫자, 언더스코어, 점만 남김
  return name.replace(/[^a-zA-Z0-9._-]/g, '_');
}

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomeView
    },
    {
      path: '/about',
      name: 'about',
      // route level code-splitting
      // this generates a separate chunk (About.[hash].js) for this route
      // which is lazy-loaded when the route is visited.
      component: () => import('../views/AboutView.vue')
    },
    {
      path: '/login',
      name: 'login',
      component: LoginView
    },
    {
      path: '/signup',
      name: 'signup',
      component: SignupView
    },
    // { // <<< 기존 About 라우트 예시 (참고용)
    //   path: '/about',
    //   name: 'about',
    //   component: () => import('../views/AboutView.vue')
    // },
    { // <<< 여기에 새로운 Companies 라우트 추가
      path: '/admin/companies/approved',
      name: 'admin-companies-approved',
      component: AdminCompaniesApprovedView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/companies/pending',
      name: 'admin-companies-pending',
      component: AdminCompaniesPendingView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/notices',
      name: 'admin-notices',
      component: AdminNoticesView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/notices/create',
      name: 'admin-notice-create',
      component: () => import('@/views/admin/AdminNoticeCreateView.vue'),
      meta: { requiresAuth: true, role: 'admin' }
    },
    // 추가된 관리자 라우트
    // {
    //   path: '/admin/approval-requests',
    //   name: 'admin-approval-requests',
    //   component: AdminApprovalRequestsView, // 삭제
    //   meta: { requiresAuth: true, role: 'admin' }
    // },
    {
      path: '/admin/products',
      name: 'admin-products',
      component: AdminProductsView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/clients',
      name: 'admin-clients',
      component: AdminClientsView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/pharmacies',
      name: 'admin-pharmacies',
      component: AdminPharmaciesView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/wholesale-revenue',
      name: 'admin-wholesale-revenue',
      component: AdminWholesaleRevenueView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/direct-revenue',
      name: 'admin-direct-revenue',
      component: AdminDirectRevenueView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/settlement-month',
      name: 'admin-settlement-month',
      component: AdminSettlementMonthView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/performance-input',
      name: 'admin-performance-input',
      component: AdminPerformanceInputView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/performance-view',
      name: 'admin-performance-view',
      component: AdminPerformanceViewView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/settlement-statements',
      name: 'admin-settlement-statements',
      component: AdminSettlementStatementsView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/notices',
      name: 'user-notices',
      component: NoticesView,
      meta: { requiresAuth: true, role: 'user' } // 일반 사용자 역할 명시 (선택적이지만 권장)
    },
    {
      path: '/notices/:id',
      name: 'NoticeDetail',
      component: () => import('@/views/NoticeDetailView.vue')
    },
    {
      path: '/admin/notices/:id',
      name: 'AdminNoticeDetail',
      component: () => import('@/views/admin/AdminNoticeDetailView.vue'),
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/notices/:id/edit',
      name: 'AdminNoticeEdit',
      component: () => import('@/views/admin/AdminNoticeEditView.vue'),
      meta: { requiresAuth: true, role: 'admin' }
    }
  ]
})

// (선택 사항) 네비게이션 가드 추가: requiresAuth 메타 필드가 있는 라우트에 대해 인증 여부 확인
router.beforeEach(async (to, from, next) => {
  console.log(`[Router Guard] Navigating from: ${from.fullPath} to: ${to.fullPath}`);

  // 로그인 및 회원가입 페이지는 항상 접근 허용
  if (to.name === 'login' || to.name === 'signup') {
    console.log('[Router Guard] Accessing login/signup page. Allowing.');
    return next();
  }

  const { data: { session }, error: sessionError } = await supabase.auth.getSession();

  if (sessionError) {
    console.error('[Router Guard] Error getting session:', sessionError.message);
    // 세션 가져오기 실패 시 로그인 페이지로 (심각한 오류 상황)
    return next({ name: 'login', query: { redirect: to.fullPath } });
  }
  console.log('[Router Guard] Session:', session ? 'Exists' : 'Does not exist');

  const requiresAuth = to.matched.some(record => record.meta.requiresAuth);
  console.log(`[Router Guard] Route requiresAuth: ${requiresAuth}`);

  if (requiresAuth) {
    if (!session) {
      console.log('[Router Guard] Auth required, but no session. Redirecting to login.');
      return next({ name: 'login', query: { redirect: to.fullPath } }); // 로그인 후 원래 경로로 리디렉션하기 위한 query 추가
    }

    // 세션이 있는 경우, 역할 검사
    const userRole = session.user?.user_metadata?.user_type;
    console.log(`[Router Guard] User role from session: ${userRole}`);

    const requiredRole = to.meta.role; // 가장 일치하는 라우트의 role을 직접 사용
    console.log(`[Router Guard] Required role for route: ${requiredRole}`);

    if (requiredRole) {
      if (userRole === requiredRole) {
        console.log('[Router Guard] Role matched. Proceeding.');
        return next();
      } else {
        console.log(`[Router Guard] Role mismatch. User role: ${userRole}, Required: ${requiredRole}. Redirecting to home.`);
        alert('접근 권한이 없습니다. (역할 불일치)');
        return next({ name: 'home' }); // 또는 사용자의 기본 대시보드나 로그인 페이지
      }
    } else {
      // requiresAuth는 true이지만, 특정 role이 명시되지 않은 경우 (예: 로그인한 모든 사용자 접근 가능)
      console.log('[Router Guard] Auth required, no specific role. Session exists. Proceeding.');
      return next();
    }
  } else {
    // 인증이 필요 없는 페이지
    console.log('[Router Guard] No auth required for this route. Proceeding.');
    return next();
  }
});

const files = ref([]); // 여러 파일 저장
const fileNames = ref([]);

function onFileChange(e) {
  files.value = Array.from(e.target.files).slice(0, 5); // 최대 5개
  fileNames.value = files.value.map(f => f.name);
}

async function uploadFiles() {
  let fileUrls = [];
  for (const f of files.value) {
    const safeName = sanitizeFileName(f.name);
    const filePath = `attachments/${Date.now()}_${safeName}`;
    const { data, error } = await supabase.storage
      .from('notices')
      .upload(filePath, f);
    if (error) {
      alert('파일 업로드 실패: ' + error.message);
      return;
    }
    const url = data?.path
      ? supabase.storage.from('notices').getPublicUrl(data.path).data.publicUrl
      : null;
    fileUrls.push(url);
  }

  const { error: insertError } = await supabase.from('notices').insert([
    {
      title: title.value,
      content: content.value,
      is_pinned: isPinned.value,
      view_count: 0,
      file_url: fileUrls // 배열 또는 문자열
    }
  ]);
}

const userType = ref('');

onMounted(async () => {
  // 기존 공지사항 데이터 불러오는 코드 아래에 추가
  const { data: { session } } = await supabase.auth.getSession();
  userType.value = session?.user?.user_metadata?.user_type || '';
});

export default router