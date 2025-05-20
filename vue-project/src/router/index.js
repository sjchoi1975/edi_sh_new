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

import { supabase } from '@/supabase'; // <<< Supabase 클라이언트 임포트

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
      path: '/admin/companies', // 경로 유지
      name: 'admin-companies',   // 이름 유지 (또는 더 명확하게 admin-companies-list 등으로 변경 가능)
      component: AdminCompaniesView, // AdminCompaniesView 컴포넌트로 변경
      meta: { requiresAuth: true, role: 'admin' } // 관리자 역할 명시
    },
    {
      path: '/admin/notices',
      name: 'admin-notices',
      component: AdminNoticesView,
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


export default router