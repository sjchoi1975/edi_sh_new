<template>
  <div class="login-root">
    <div class="login-left"></div>
    <div class="login-right">
      <div class="login-logo">신일제약 실적관리 시스템</div>
      <form class="login-form" @submit.prevent="handleLogin">
        <div class="form-group">
          <label for="email">아이디(이메일)</label>
          <InputText id="email" type="email" v-model="email" placeholder="이메일" />
        </div>
        <div class="form-group">
          <label for="password">비밀번호</label>
          <InputText id="password" type="password" v-model="password" placeholder="비밀번호" />
        </div>
        <Button :label="'로그인'" class="login-btn" :disabled="!canLogin" :style="loginBtnStyle" @click="handleLogin" />
        <Button label="회원가입" class="signup-btn" @click="$router.push('/signup')" />
      </form>
      <div class="copyright">© 2025. 주식회사 팜플코리아 All Rights Reserved.</div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import InputText from 'primevue/inputtext';
import Button from 'primevue/button';
import { supabase } from '@/supabase';
import { useRouter } from 'vue-router';

const email = ref('');
const password = ref('');
const loading = ref(false);
const router = useRouter();

const canLogin = computed(() => email.value.trim() !== '' && password.value.trim() !== '');
const loginBtnStyle = computed(() => ({
  background: canLogin.value ? '#5FA56B' : '#ABCEB2',
  color: canLogin.value ? '#fff' : '#fff',
  border: 'none',
  width: '100%',
  marginBottom: '0.5rem',
  fontSize: '1rem',
  cursor: canLogin.value ? 'pointer' : 'not-allowed',
}));

const handleLogin = async () => {
  if (!canLogin.value) return;
  loading.value = true;
  try {
    const { data: companyRow } = await supabase
      .from('companies')
      .select('id, approval_status, user_type')
      .eq('email', email.value.trim().toLowerCase())
      .maybeSingle();
    if (!companyRow) {
      alert('아이디(이메일) 정보가 없습니다. 다시 확인해주세요.');
      loading.value = false;
      return;
    }
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: email.value,
      password: password.value,
    });
    if (authError) {
      alert('비밀번호가 일치하지 않습니다. 다시 확인해주세요.');
      loading.value = false;
      return;
    }
    if (companyRow.approval_status !== 'approved') {
      alert('미승인 회원입니다. 관리자에게 승인을 요청해주세요.');
      await supabase.auth.signOut();
      loading.value = false;
      return;
    }
    if (companyRow.user_type === 'admin') {
      router.push('/admin/notices');
    } else {
      router.push('/notices');
    }
  } catch (error) {
    alert('로그인 중 오류가 발생했습니다.');
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped>
html, body, #app, .login-root {
  margin: 0 !important;
  padding: 0 !important;
  width: 100vw;
  height: 100vh;
}
.login-root {
  display: flex;
  min-height: 100vh;
  background: #f7f7f9;
  font-size: 13px;
  margin: 0 !important;
  padding: 0 !important;
}
.login-left {
  flex: 1;
  background: url('/login-bg.jpg') no-repeat center center;
  background-size: cover;
}
.login-right {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: #fff;
  min-width: 400px;
  box-shadow: 0 0 16px 0 rgba(0,0,0,0.04);
}
.login-logo {
  font-size: 1.8rem;
  font-weight: bold;
  color: #6db56e;
  margin-bottom: 4rem;
  letter-spacing: 2px;
}
.login-form {
  width: 100%;
  max-width: 340px;
  display: flex;
  flex-direction: column;
  gap: 1.2rem;
}
.form-group label {
  font-size: 0.9rem;
  font-weight: 500;
  margin-bottom: 0.3rem;
  color: #222;
}
.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
}
.login-btn {
  width: 100%;
  border: none !important;
  margin-bottom: 0.5rem;
  font-size: 1rem;
}
.signup-btn {
  width: 100%;
  background: #3b82f6 !important;
  color: #fff !important;
  border: none !important;
  font-size: 1rem;
}
.copyright {
  margin-top: 3rem;
  color: #888;
  font-size: 0.85rem;
  text-align: center;
}
@media (max-width: 900px) {
  .login-root {
    flex-direction: column;
  }
  .login-left {
    display: none;
  }
  .login-right {
    min-width: unset;
    width: 100vw;
  }
}
:global(.main-content), div.main-content {
  margin: 0 !important;
  padding: 0 !important;
}
</style> 