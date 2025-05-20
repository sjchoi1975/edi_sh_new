<template>
  <div class="login-container">
    <h2>로그인</h2>
    <div class="p-fluid">
      <div class="p-field">
        <label for="email">이메일</label>
        <InputText id="email" type="email" v-model="email" />
      </div>
      <div class="p-field">
        <label for="password">비밀번호</label>
        <InputText id="password" type="password" v-model="password" />
      </div>
      <Button label="로그인" @click="handleLogin" class="p-mt-2" :loading="loading" />
      <div class="p-mt-3 p-text-center">
        <span>계정이 없으신가요? </span>
        <router-link to="/signup">회원가입</router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import InputText from 'primevue/inputtext';
import Button from 'primevue/button';
import { supabase } from '@/supabase';
// import router from '@/router'; // App.vue에서 리디렉션을 처리하므로 직접 사용하지 않음

const email = ref('');
const password = ref('');
const loading = ref(false);

const handleLogin = async () => {
  loading.value = true;
  try {
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: email.value,
      password: password.value,
    });

    if (authError) {
      // signInWithPassword 자체가 실패한 경우 (잘못된 이메일/비밀번호 등)
      // Supabase 에러 코드를 확인하여 더 구체적인 메시지 제공 가능
      console.error('Login failed (signInWithPassword):', authError);
      alert('로그인 실패: ' + (authError.message || '이메일 또는 비밀번호를 확인하세요.'));
      loading.value = false;
      return; // 여기서 함수 종료
    }

    // 로그인은 성공했으나, 사용자 메타데이터나 승인 상태에 따른 처리
    if (authData && authData.user) {
      // user_metadata가 로드될 때까지 약간의 시간이 걸릴 수 있으므로,
      // 최신 사용자 정보를 한번 더 가져오는 것을 고려할 수 있으나,
      // onAuthStateChange에서 USER_UPDATED 이벤트로 처리될 수도 있음.
      // 여기서는 로그인 시점의 메타데이터를 기준으로 판단합니다.
      const approvalStatus = authData.user.user_metadata?.approval_status;
      // const userType = authData.user.user_metadata?.user_type;

      console.log('[LoginView] Login successful, approval_status:', approvalStatus);

      if (approvalStatus === 'approved') {
        // App.vue의 onAuthStateChange가 SIGNED_IN 이벤트를 받아 리디렉션 처리
        console.log('[LoginView] User approved. App.vue will handle redirect.');
        // router.push('/'); // 이 부분을 제거
      } else if (approvalStatus === 'pending') {
        alert('아직 관리자 승인 대기 중입니다. 로그인 페이지로 돌아갑니다.');
        await supabase.auth.signOut(); // SIGNED_OUT 이벤트 유발 -> App.vue가 /login으로 보냄
      } else {
        // 'rejected' 또는 기타 상태 (approval_status가 없거나 다른 값)
        alert('로그인이 허용되지 않은 사용자입니다. 관리자에게 문의해주세요. 로그인 페이지로 돌아갑니다.');
        await supabase.auth.signOut(); // SIGNED_OUT 이벤트 유발
      }
    } else {
      // 로그인 성공 응답을 받았으나 user 객체가 없는 매우 예외적인 경우
      console.error('[LoginView] Login seemed successful, but no user data in response.');
      alert('로그인 처리 중 예기치 않은 오류가 발생했습니다.');
      // 필요하다면 여기서도 signOut 처리
    }

  } catch (error) {
    // signInWithPassword에서 throw된 에러 외의 예외 (네트워크 문제 등)
    console.error('Login error (catch block):', error);
    alert('로그인 중 오류 발생: ' + error.message);
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped>
.login-container {
  max-width: 400px;
  margin: 50px auto;
  padding: 20px;
  border: 1px solid #ccc;
  border-radius: 8px;
}
.p-field {
  margin-bottom: 1.5rem;
}
.p-mt-3 {
  margin-top: 1.5rem;
}
.p-text-center {
  text-align: center;
}
</style> 