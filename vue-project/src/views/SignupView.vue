<template>
  <div class="signup-root">
    <div class="signup-right">
      <div class="signup-logo">신일제약 실적관리 시스템</div>
      <form class="signup-form" @submit.prevent="handleSignup">
        <div class="form-row" v-for="field in fields" :key="field.key">
          <label :for="field.key">{{ field.label }}</label>
          <InputText
            v-if="field.type !== 'password' && field.type !== 'password2'"
            :id="field.key"
            :type="field.inputType"
            v-model="formData[field.key]"
            :placeholder="field.label"
          />
          <InputText
            v-else-if="field.type === 'password'"
            :id="field.key"
            type="password"
            v-model="formData.password"
            placeholder="비밀번호"
          />
          <InputText
            v-else-if="field.type === 'password2'"
            :id="field.key"
            type="password"
            v-model="formData.confirmPassword"
            placeholder="비밀번호 확인"
          />
        </div>
        <div class="button-row">
          <Button label="회원가입" class="signup-btn" @click="handleSignup" />
          <Button label="취소" class="cancel-btn" @click.prevent="goToLogin" />
        </div>
        <div class="login-link">
          이미 계정이 있으신가요? <a @click.prevent="goToLogin" href="#">로그인</a>
        </div>
      </form>
      <div class="copyright">© 2025. 주식회사 팜플코리아 All Rights Reserved.</div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import InputText from 'primevue/inputtext';
import Button from 'primevue/button';
import { supabase } from '@/supabase';
import { useRouter } from 'vue-router';
import { onMounted, onUnmounted } from 'vue';

const formData = ref({
  email: '',
  password: '',
  confirmPassword: '',
  companyName: '',
  businessRegistrationNumber: '',
  representativeName: '',
  businessAddress: '',
  contactPersonName: '',
  mobilePhone: '',
});
const router = useRouter();

const fields = [
  { key: 'email', label: '아이디(이메일)', inputType: 'email' },
  { key: 'password', label: '비밀번호', type: 'password' },
  { key: 'confirmPassword', label: '비밀번호 확인', type: 'password2' },
  { key: 'companyName', label: '업체명', inputType: 'text' },
  { key: 'businessRegistrationNumber', label: '사업자등록번호', inputType: 'text' },
  { key: 'representativeName', label: '대표자명', inputType: 'text' },
  { key: 'businessAddress', label: '사업장 소재지', inputType: 'text' },
  { key: 'contactPersonName', label: '담당자명', inputType: 'text' },
  { key: 'mobilePhone', label: '휴대폰번호', inputType: 'text' },
];

const handleSignup = async () => {
  if (formData.value.password !== formData.value.confirmPassword) {
    alert('비밀번호가 일치하지 않습니다.');
    return;
  }
  try {
    const emailLower = formData.value.email.trim().toLowerCase();
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: emailLower,
      password: formData.value.password,
      options: {
        data: {
          user_type: 'user',
          approval_status: 'pending'
        }
      }
    });
    if (authError) throw authError;
    if (authData && authData.user) {
      const { error: companyInsertError } = await supabase
        .from('companies')
        .insert([
          {
            user_id: authData.user.id,
            email: emailLower,
            company_name: formData.value.companyName,
            business_registration_number: formData.value.businessRegistrationNumber,
            representative_name: formData.value.representativeName,
            business_address: formData.value.businessAddress,
            contact_person_name: formData.value.contactPersonName,
            mobile_phone: formData.value.mobilePhone,
            user_type: 'user',
            approval_status: 'pending'
          }
        ]);
      if (companyInsertError) throw companyInsertError;
      alert('가입 요청이 완료되었습니다. 관리자 승인 후 로그인이 가능합니다.');
      router.push('/login');
    } else {
      throw new Error('사용자 정보가 생성되지 않았습니다.');
    }
  } catch (error) {
    alert('가입 요청 실패: ' + (error.error_description || error.message));
  }
};

const goToLogin = () => {
  router.push('/login');
};

onMounted(() => {
  document.body.classList.add('no-main-padding');
});

onUnmounted(() => {
  document.body.classList.remove('no-main-padding');
});
</script>

<style scoped>
.signup-root {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  width: 100vw;
  background: #f7f7f9;
  font-size: 13px;
}
.signup-right {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: #fff;
  min-width: 400px;
  box-shadow: 0 0 16px 0 rgba(0,0,0,0.04);
  width: 100%;
  max-width: 480px;
  padding: 40px 32px 32px 32px;
  border-radius: 12px;
  position: relative;
}
.signup-logo {
  font-size: 1.8em;
  font-weight: bold;
  color: #5fa56b;
  margin-bottom: 2rem;
  letter-spacing: 2px;
}
.signup-form {
  width: 100%;
  max-width: 420px;
  display: flex;
  flex-direction: column;
  gap: 1.2rem;
}
.form-row {
  display: flex;
  align-items: center;
  gap: 1.2rem;
  margin-bottom: 0.1rem;
}
.form-row label {
  width: 140px;
  font-size: 0.9rem;
  font-weight: 500;
  color: #222;
  text-align: right;
}
.form-row input {
  flex: 1;
  min-width: 0;
  padding: 8px 12px;
  font-size: 0.95rem;
}
.button-row {
  display: flex;
  gap: 1rem;
  margin-top: 0.7rem;
}
.signup-btn {
  flex: 1;
  background: #3b82f6 !important;
  color: #fff !important;
  border: none !important;
  font-size: 0.95rem;
}
.cancel-btn {
  flex: 1;
  background: #e0e0e0 !important;
  color: #222 !important;
  border: none !important;
  font-size: 0.95rem;
}
.login-link {
  margin-top: 0.5rem;
  text-align: center;
  color: #1976d2;
  font-size: 0.85rem;
  margin-bottom: 2.8rem;
}
.login-link a {
  color: #1976d2;
  text-decoration: underline;
  cursor: pointer;
}
.copyright {
  position: absolute;
  bottom: 24px;
  left: 0;
  width: 100%;
  color: #888;
  font-size: 0.8rem;
  text-align: center;
}
@media (max-width: 900px) {
  .signup-right {
    min-width: unset;
    width: 100vw;
  }
  .signup-form {
    max-width: 98vw;
  }
}
</style> 