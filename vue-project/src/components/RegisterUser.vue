<template>
  <div class="register-user-form">
    <h2>회원 등록</h2>
    <form @submit.prevent="onSubmit">
      <div class="p-field">
        <label for="email">이메일</label>
        <InputText id="email" v-model="form.email" type="email" required />
      </div>
      <div class="p-field">
        <label for="password">비밀번호</label>
        <InputText id="password" v-model="form.password" type="password" required />
      </div>
      <div class="p-field">
        <label for="company">업체명</label>
        <InputText id="company" v-model="form.company" required />
      </div>
      <Button label="등록" type="submit" :loading="loading" />
    </form>
    <div v-if="message" :class="{'success': success, 'error': !success}">{{ message }}</div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import InputText from 'primevue/inputtext';
import Button from 'primevue/button';

const form = ref({
  email: '',
  password: '',
  company: ''
});
const loading = ref(false);
const message = ref('');
const success = ref(false);

const EDGE_FUNCTION_URL = 'https://vaeolqywqckkiwtvspxf.functions.supabase.co/register-user'; // 실제 URL로 교체 필요

const onSubmit = async () => {
  loading.value = true;
  message.value = '';
  success.value = false;
  try {
    const res = await fetch(EDGE_FUNCTION_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: form.value.email,
        password: form.value.password,
        company: form.value.company
      })
    });
    const data = await res.json();
    if (res.ok) {
      message.value = '회원 등록이 완료되었습니다.';
      success.value = true;
      form.value.email = '';
      form.value.password = '';
      form.value.company = '';
    } else {
      message.value = data.error || '등록에 실패했습니다.';
    }
  } catch (e) {
    message.value = '오류가 발생했습니다.';
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped>
.register-user-form {
  max-width: 400px;
  margin: 0 auto;
}
.p-field {
  margin-bottom: 1rem;
}
.success {
  color: green;
}
.error {
  color: red;
}
</style> 