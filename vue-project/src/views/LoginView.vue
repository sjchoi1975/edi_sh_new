<template>
  <div class="login-root">
    <div class="login-right">
      <div class="login-logo">신일제약 실적관리 시스템</div>
      <form class="login-form" @submit.prevent="handleLogin">
        <div class="form-group">
          <label for="email">아이디(이메일)</label>
          <input id="email" type="email" v-model="email" />
        </div>
        <div class="form-group">
          <label for="password">비밀번호</label>
          <input id="password" type="password" v-model="password" />
        </div>
        <Button :label="'로그인'" class="login-btn" :disabled="!canLogin" :style="loginBtnStyle" @click="handleLogin" />
        <Button label="회원가입" class="signup-btn" @click="$router.push('/signup')" />
      </form>
      <div class="copyright">© 2025. 주식회사 팜플코리아 All Rights Reserved.</div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
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

onMounted(() => {
  document.body.classList.add('no-main-padding');
});

onUnmounted(() => {
  document.body.classList.remove('no-main-padding');
});
</script> 