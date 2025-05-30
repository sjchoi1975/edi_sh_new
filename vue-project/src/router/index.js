import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'
import LoginView from '../views/LoginView.vue'
import SignupView from '../views/SignupView.vue'
import AdminNoticesView from '../views/admin/AdminNoticesView.vue'
import NoticesView from '@/views/user/NoticesView.vue'

import AdminCompaniesApprovedView from '../views/admin/AdminCompaniesApprovedView.vue'
import AdminCompaniesPendingView from '../views/admin/AdminCompaniesPendingView.vue'
import AdminCompanyCreateView from '../views/admin/AdminCompanyCreateView.vue'
import AdminCompanyDetailView from '../views/admin/AdminCompanyDetailView.vue'
import AdminCompanyEditView from '../views/admin/AdminCompanyEditView.vue'
import AdminProductsView from '../views/admin/AdminProductsView.vue'
import AdminProductCreateView from '../views/admin/AdminProductCreateView.vue'
import AdminClientsView from '../views/admin/AdminClientsView.vue'
import AdminClientsCreateView from '../views/admin/AdminClientsCreateView.vue'
import AdminPharmaciesView from '../views/admin/AdminPharmaciesView.vue'
import AdminPharmaciesCreateView from '../views/admin/AdminPharmaciesCreateView.vue'
import AdminWholesaleRevenueView from '../views/admin/AdminWholesaleRevenueView.vue'
import AdminWholesaleRevenueCreateView from '../views/admin/AdminWholesaleRevenueCreateView.vue'

import AdminDirectRevenueView from '../views/admin/AdminDirectRevenueView.vue'
import AdminDirectRevenueCreateView from '../views/admin/AdminDirectRevenueCreateView.vue'
import AdminSettlementMonthsView from '../views/admin/AdminSettlementMonthsView.vue'
import AdminSettlementMonthsCreateView from '../views/admin/AdminSettlementMonthsCreateView.vue'
import AdminSettlementMonthsDetailView from '../views/admin/AdminSettlementMonthsDetailView.vue'
import AdminSettlementMonthsEditView from '../views/admin/AdminSettlementMonthsEditView.vue'

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
    // {
    //   path: '/about',
    //   name: 'about',
    //   // route level code-splitting
    //   // this generates a separate chunk (About.[hash].js) for this route
    //   // which is lazy-loaded when the route is visited.
    //   component: () => import('../views/AboutView.vue')
    // },
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
      path: '/admin/products/create',
      name: 'admin-product-create',
      component: AdminProductCreateView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/products/:id',
      name: 'admin-product-detail',
      component: () => import('@/views/admin/AdminProductDetailView.vue'),
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/products/:id/edit',
      name: 'admin-product-edit',
      component: () => import('@/views/admin/AdminProductEditView.vue'),
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/clients',
      name: 'admin-clients',
      component: AdminClientsView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/clients/create',
      name: 'admin-clients-create',
      component: AdminClientsCreateView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/clients/:id',
      name: 'admin-clients-detail',
      component: () => import('@/views/admin/AdminClientsDetailView.vue'),
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/clients/:id/edit',
      name: 'admin-clients-edit',
      component: () => import('@/views/admin/AdminClientsEditView.vue'),
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/clients/assign-companies',
      name: 'admin-clients-assign-companies',
      component: () => import('@/views/admin/AdminClientsAssignCompaniesView.vue'),
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/clients/assign-pharmacies',
      name: 'admin-clients-assign-pharmacies',
      component: () => import('@/views/admin/AdminClientsAssignPharmaciesView.vue'),
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/pharmacies',
      name: 'admin-pharmacies',
      component: AdminPharmaciesView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/pharmacies/create',
      name: 'admin-pharmacies-create',
      component: AdminPharmaciesCreateView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/pharmacies/:id',
      name: 'admin-pharmacies-detail',
      component: () => import('@/views/admin/AdminPharmaciesDetailView.vue'),
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/pharmacies/:id/edit',
      name: 'admin-pharmacies-edit',
      component: () => import('@/views/admin/AdminPharmaciesEditView.vue'),
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/wholesale-revenue',
      name: 'admin-wholesale-revenue',
      component: AdminWholesaleRevenueView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/wholesale-revenue/create',
      name: 'admin-wholesale-revenue-create',
      component: AdminWholesaleRevenueCreateView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/direct-revenue',
      name: 'admin-direct-revenue',
      component: AdminDirectRevenueView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/direct-revenue/create',
      name: 'admin-direct-revenue-create',
      component: AdminDirectRevenueCreateView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/settlement-month',
      name: 'admin-settlement-month',
      component: AdminSettlementMonthsView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/performance-list',
      name: 'AdminPerformanceRegisterList',
      component: () => import('@/views/admin/AdminPerformanceRegisterList.vue'),
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/absorption-analysis',
      name: 'AdminAbsorptionAnalysis',
      component: () => import('@/views/admin/AdminAbsorptionAnalysis.vue'),
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/settlement-months',
      name: 'admin-settlement-months',
      component: AdminSettlementMonthsView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/settlement-months/create',
      name: 'admin-settlement-months-create',
      component: AdminSettlementMonthsCreateView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/settlement-months/:id',
      name: 'admin-settlement-months-detail',
      component: AdminSettlementMonthsDetailView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/settlement-months/:id/edit',
      name: 'admin-settlement-months-edit',
      component: AdminSettlementMonthsEditView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/notices',
      name: 'user-notices',
      component: NoticesView,
      meta: { requiresAuth: true, role: 'user' }
    },
    {
      path: '/notices/:id',
      name: 'NoticeDetail',
      component: () => import('@/views/user/NoticeDetailView.vue')
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
    },
        {
      path: '/admin/companies/create',
      name: 'admin-company-create',
      component: AdminCompanyCreateView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/companies/:id',
      name: 'admin-company-detail',
      component: AdminCompanyDetailView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/admin/companies/:id/edit',
      name: 'admin-company-edit',
      component: AdminCompanyEditView,
      meta: { requiresAuth: true, role: 'admin' }
    },
    {
      path: '/products',
      name: 'user-products',
      component: () => import('@/views/user/ProductsView.vue'),
      meta: { requiresAuth: true, role: 'user' }
    },
    {
      path: '/products/:id',
      name: 'user-product-detail',
      component: () => import('@/views/user/ProductDetailView.vue'),
      meta: { requiresAuth: true, role: 'user' }
    },
    {
      path: '/clients',
      name: 'user-clients',
      component: () => import('@/views/user/ClientsView.vue'),
      meta: { requiresAuth: true, role: 'user' }
    },
    {
      path: '/clients/:id',
      name: 'user-client-detail',
      component: () => import('@/views/user/ClientsDetailView.vue'),
      meta: { requiresAuth: true, role: 'user' }
    },
    {
      path: '/performance/register',
      name: 'performance-register',
      component: () => import('@/views/user/PerformanceRegister.vue'),
      meta: { requiresAuth: true, role: 'user' }
    },
    {
      path: '/performance/list',
      name: 'performance-list',
      component: () => import('@/views/user/PerformanceRegisterList.vue'),
      meta: { requiresAuth: true, role: 'user' }
    },
    {
      path: '/performance/upload',
      name: 'performance-upload',
      component: () => import('@/views/user/PerformanceUploadView.vue'),
      meta: { requiresAuth: true, role: 'user' }
    },
    {
      path: '/my-info',
      name: 'my-info',
      component: () => import('@/views/user/MyInfoView.vue'),
      meta: { requiresAuth: true, role: 'user' }
    },
    {
      path: '/my-info/edit',
      name: 'my-info-edit',
      component: () => import('@/views/user/MyInfoEditView.vue'),
      meta: { requiresAuth: true, role: 'user' }
    },
    {
      path: '/my-info/change-password',
      name: 'my-info-change-password',
      component: () => import('@/views/user/ChangePasswordView.vue'),
      meta: { requiresAuth: true, role: 'user' }
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