<template>
  <div class="signup-container">
    <h2>회원가입</h2>
    <div class="p-fluid">
      <!-- ... existing input fields ... -->
      <div class="p-field">
        <label for="email">이메일 (아이디로 사용)</label>
        <InputText id="email" type="email" v-model="formData.email" />
      </div>
      <div class="p-field">
        <label for="password">비밀번호</label>
        <InputText id="password" type="password" v-model="formData.password" />
      </div>
      <div class="p-field">
        <label for="confirmPassword">비밀번호 확인</label>
        <InputText id="confirmPassword" type="password" v-model="formData.confirmPassword" />
      </div>
      <div class="p-field">
        <label for="companyName">업체명</label>
        <InputText id="companyName" type="text" v-model="formData.companyName" />
      </div>
      <div class="p-field">
        <label for="businessNumber">사업자등록번호</label>
        <InputText id="businessNumber" type="text" v-model="formData.businessRegistrationNumber" />
      </div>
      <div class="p-field">
        <label for="representativeName">대표자명</label>
        <InputText id="representativeName" type="text" v-model="formData.representativeName" />
      </div>
      <div class="p-field">
        <label for="businessAddress">사업장 소재지</label>
        <InputText id="businessAddress" type="text" v-model="formData.businessAddress" />
      </div>
      <div class="p-field">
        <label for="contactPersonName">담당자명</label>
        <InputText id="contactPersonName" type="text" v-model="formData.contactPersonName" />
      </div>
      <div class="p-field">
        <label for="mobilePhone">휴대폰번호</label>
        <InputText id="mobilePhone" type="text" v-model="formData.mobilePhone" />
      </div>
      <Button label="가입 요청" @click="handleSignup" class="p-mt-3" />
      <div class="p-mt-3 p-text-center">
        <span>이미 계정이 있으신가요? </span>
        <router-link to="/login">로그인</router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import InputText from 'primevue/inputtext';
import Button from 'primevue/button';
import { supabase } from '@/supabase';
import router from '@/router';

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

const handleSignup = async () => {
  if (formData.value.password !== formData.value.confirmPassword) {
    alert('비밀번호가 일치하지 않습니다.');
    return;
  }
  try {
    // 1. Supabase Auth로 사용자 생성 (이메일, 비밀번호) 및 user_metadata 추가
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: formData.value.email,
      password: formData.value.password,
      options: {
        data: {
          user_type: 'user', // 기본 사용자 유형
          approval_status: 'pending' // 가입 시 기본 승인 상태
        }
      }
    });
    if (authError) throw authError;

    // 2. 생성된 사용자 ID와 함께 companies 테이블에 업체 정보 저장
    if (authData && authData.user) {
      const { error: companyInsertError } = await supabase
        .from('companies')
        .insert([
          {
            user_id: authData.user.id, // Auth에서 생성된 사용자 ID
            email: formData.value.email,
            company_name: formData.value.companyName,
            business_registration_number: formData.value.businessRegistrationNumber,
            representative_name: formData.value.representativeName,
            business_address: formData.value.businessAddress,
            contact_person_name: formData.value.contactPersonName,
            mobile_phone: formData.value.mobilePhone,
            user_type: 'user', // companies 테이블에도 사용자 유형 저장
            approval_status: 'pending' // companies 테이블에도 승인 상태 저장
            // status, company_group 등은 관리자가 추후 설정하거나 기본값 사용
          }
        ]);
      if (companyInsertError) throw companyInsertError;

      alert('가입 요청이 완료되었습니다. 관리자 승인 후 로그인이 가능합니다.');
      router.push('/login'); // 로그인 페이지로 이동
    } else {
      throw new Error('사용자 정보가 생성되지 않았습니다.');
    }

  } catch (error) {
    console.error('Signup error:', error);
    alert('가입 요청 실패: ' + (error.error_description || error.message));
  }
};
</script>

<style scoped>
.signup-container {
  max-width: 500px;
  margin: 30px auto;
  padding: 20px;
  border: 1px solid #ccc;
  border-radius: 8px;
}
.p-field {
  margin-bottom: 1rem;
}
.p-mt-3 {
  margin-top: 1.5rem;
}
/* 추가된 스타일 */
.p-text-center {
  text-align: center;
}
</style> 