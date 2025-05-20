<script setup>
import { ref, onMounted, nextTick } from 'vue';
import { RouterView } from 'vue-router';
import { supabase } from '@/supabase';
import router from './router';
import TopNavigationBar from './components/TopNavigationBar.vue';

const user = ref(null);
const userEmail = ref('');
const userType = ref(''); // 'admin', 'user', or ''

console.log('[App.vue] Script setup: Initializing');

// 사용자 상태 설정 함수
const setUserState = (sessionUser) => {
  if (sessionUser) {
    user.value = sessionUser;
    userEmail.value = sessionUser.email;
    userType.value = sessionUser.user_metadata?.user_type || '';
    console.log(`[App.vue] setUserState: User set - Email: ${userEmail.value}, Type: ${userType.value}`);
  } else {
    user.value = null;
    userEmail.value = '';
    userType.value = '';
    console.log('[App.vue] setUserState: User cleared');
  }
};

// 리디렉션 처리 함수
const handleRedirect = async (currentSession) => {
  const currentPath = router.currentRoute.value.path;
  console.log(`[App.vue] handleRedirect: Current path: ${currentPath}, UserType: ${userType.value}`);

  if (currentSession && currentSession.user) {
    // 사용자가 로그인된 상태
    const targetPath = userType.value === 'admin' ? '/admin/notices' : (userType.value === 'user' ? '/notices' : null);
    
    if (targetPath) {
      // 역할에 따른 기본 페이지로 이동해야 하는 경우
      if (currentPath === '/' || currentPath === '/login' || currentPath === targetPath) { // 현재 경로가 루트, 로그인 또는 이미 타겟 경로인 경우
         if (currentPath !== targetPath) { // 이미 타겟 경로에 있다면 불필요한 push 방지
            console.log(`[App.vue] handleRedirect: User logged in. Redirecting from ${currentPath} to ${targetPath}`);
            try {
                await router.push(targetPath);
            } catch (e) {
                console.error(`[App.vue] handleRedirect: Failed to push to ${targetPath}`, e);
            }
         } else {
            console.log(`[App.vue] handleRedirect: User logged in. Already at target path ${targetPath}. No redirect needed.`);
         }
      } else {
        // 로그인 되어있으나, 허용되지 않은 다른 경로에 있으려고 한다면, 일단은 그대로 두거나, 혹은 홈으로 보낼 수 있습니다.
        // 현재는 라우터 가드에서 처리하도록 별도 조치 없음.
        console.log(`[App.vue] handleRedirect: User logged in. At path ${currentPath}. No redirect based on login status alone unless at / or /login.`);
      }
    } else {
        // userType이 없거나 유효하지 않은 경우 (예: 메타데이터 누락)
        console.warn(`[App.vue] handleRedirect: User logged in but userType ('${userType.value}') is invalid. Staying at ${currentPath} or redirecting to login if critical.`);
        // 이 경우, 문제가 될 수 있으므로 /login으로 보내거나, 에러 처리가 필요할 수 있습니다.
        // 우선은 라우터 가드가 /login으로 보내도록 기대합니다.
        if (currentPath !== '/login' && currentPath !== '/signup') {
             console.log(`[App.vue] handleRedirect: Invalid userType, pushing to /login from ${currentPath}`);
             await router.push('/login');
        }
    }
  } else {
    // 사용자가 로그인되지 않은 상태
    if (currentPath !== '/login' && currentPath !== '/signup') {
      console.log(`[App.vue] handleRedirect: User not logged in. Redirecting from ${currentPath} to /login`);
      try {
        await router.push('/login');
      } catch (e) {
        console.error('[App.vue] handleRedirect: Failed to push to /login (user not logged in)', e);
      }
    } else {
        console.log(`[App.vue] handleRedirect: User not logged in. Already at ${currentPath}. No redirect needed.`);
    }
  }
};

onMounted(async () => {
  console.log('[App.vue] onMounted: Component mounted. Registering onAuthStateChange.');
  
  // 초기 세션 로드 및 상태 설정
  // onAuthStateChange가 INITIAL_SESSION 이벤트를 통해 초기 상태를 처리하므로,
  // onMounted에서는 getSession()을 호출하여 즉시 상태를 반영하려고 시도할 수 있지만,
  // onAuthStateChange 리스너가 등록된 후 INITIAL_SESSION 이벤트가 발생하므로 중복될 수 있습니다.
  // INITIAL_SESSION을 주로 사용하고, getSession은 보조적으로 사용하거나 로그 확인용으로만 남겨둘 수 있습니다.
  try {
    const { data: { session } } = await supabase.auth.getSession();
    console.log('[App.vue] onMounted: getSession() completed.', { session });
    if (session && session.user) {
        // 이미 INITIAL_SESSION에서 처리될 가능성이 높지만, 만약을 대비해 한번 더 사용자 상태 설정
        // setUserState(session.user); 
        // INITIAL_SESSION 이벤트에서 주도적으로 처리하도록 이 부분은 주석 처리하거나 제거 가능.
    } else if (!session && router.currentRoute.value.path !== '/login' && router.currentRoute.value.path !== '/signup') {
        // console.log('[App.vue] onMounted: No session from getSession(), redirecting to /login if not already there.');
        // await router.push('/login'); // INITIAL_SESSION에서 처리.
    }
  } catch (error) {
      console.error('[App.vue] onMounted: Error in getSession()', error);
  }


  supabase.auth.onAuthStateChange(async (event, session) => {
    console.log(`[App.vue] onAuthStateChange: Event: ${event}, Current Path: ${router.currentRoute.value.path}`, { session });
    await nextTick(); // Vue 상태 업데이트 및 라우터 변경 감지를 위해 nextTick 사용

    setUserState(session?.user); // 이벤트 발생 시마다 사용자 상태 업데이트

    if (event === 'INITIAL_SESSION') {
      console.log('[App.vue] Event: INITIAL_SESSION');
      await handleRedirect(session);
    } else if (event === 'SIGNED_IN') {
      console.log('[App.vue] Event: SIGNED_IN');
      await handleRedirect(session); // 로그인 시 리디렉션
    } else if (event === 'SIGNED_OUT') {
      console.log('[App.vue] Event: SIGNED_OUT');
      // setUserState(null); // 이미 위에서 호출됨
      await handleRedirect(null); // 로그아웃 시 리디렉션 (세션 없음)
    } else if (event === 'USER_UPDATED') {
        console.log('[App.vue] Event: USER_UPDATED. User metadata might have changed.');
        // 사용자 메타데이터(예: 역할)가 변경되었을 수 있으므로, 리디렉션 로직 재실행 고려
        // 다만, 역할 변경이 즉각적인 페이지 이동을 강제해야 하는지는 정책에 따라 다름.
        // 필요하다면 handleRedirect(session) 호출. 현재는 상태 업데이트만 함.
    } else if (event === 'PASSWORD_RECOVERY') {
        console.log('[App.vue] Event: PASSWORD_RECOVERY. User may need to be redirected to a password reset page.');
        // 필요한 경우 비밀번호 재설정 페이지로 리디렉션
    } else if (event === 'TOKEN_REFRESHED') {
        console.log('[App.vue] Event: TOKEN_REFRESHED. Session token has been refreshed.');
        // 특별한 조치 불필요. 세션은 계속 유효.
    }
  });
});

const handleLogout = async () => {
  console.log('[App.vue] handleLogout: Attempting logout');
  try {
    const { error } = await supabase.auth.signOut();
    if (error) {
        console.error('[App.vue] handleLogout: Logout failed', error);
        alert('로그아웃 실패: ' + error.message);
    } else {
        console.log('[App.vue] handleLogout: Logout successful. onAuthStateChange will handle redirect.');
        // setUserState(null); // onAuthStateChange에서 처리
        // router.push('/login'); // onAuthStateChange에서 처리
    }
  } catch (error) {
    console.error('[App.vue] handleLogout: Exception during logout', error);
    alert('로그아웃 중 예외 발생: ' + error.message);
  }
};
</script>

<template>
  <div id="app-container">
    <TopNavigationBar v-if="user" :userRole="userType" :userEmail="userEmail" @logout="handleLogout" />
    <div class="main-content">
      <!-- <RouterView :key="router.currentRoute.value.fullPath" /> -->
      <RouterView />
    </div>
  </div>
</template>

<style scoped>
header {
  line-height: 1.5;
  max-height: 100vh;
}

.logo {
  display: block;
  margin: 0 auto 2rem;
}

nav {
  width: 100%;
  font-size: 12px;
  text-align: center;
  margin-top: 2rem;
}

nav a.router-link-exact-active {
  color: var(--color-text);
}

nav a.router-link-exact-active:hover {
  background-color: transparent;
}

nav a {
  display: inline-block;
  padding: 0 1rem;
  border-left: 1px solid var(--color-border);
}

nav a:first-of-type {
  border: 0;
}

/* .user-info 관련 스타일은 TopNavigationBar.vue로 이동되었거나 그곳에서 관리 */

@media (min-width: 1024px) {
  header {
    display: flex;
    place-items: center;
    padding-right: calc(var(--section-gap) / 2);
  }

  .logo {
    margin: 0 2rem 0 0;
  }

  header .wrapper {
    display: flex;
    place-items: flex-start;
    flex-wrap: wrap;
  }

  nav {
    text-align: left;
    margin-left: -1rem;
    font-size: 1rem;
    padding: 1rem 0;
    margin-top: 1rem;
  }
}

#app-container {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

.main-content {
  flex-grow: 1;
  padding: 1rem; /* 기본 패딩 유지 */
}
</style>

<style>
/* 전역 스타일은 여기에 유지 */
body {
  margin: 0;
  font-family: var(--font-family); /* PrimeVue 테마나 index.html에서 설정된 폰트 사용 */
  background-color: #f8f9fa; /* 밝은 회색 배경 */
  color: #333; /* 기본 텍스트 색상 */
}
</style>
