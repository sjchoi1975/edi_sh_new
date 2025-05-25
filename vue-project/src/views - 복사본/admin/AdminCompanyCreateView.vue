<template>
  <div class="notice-create-view">
    <div class="form-title">신규 업체 등록</div>
    <form @submit.prevent="handleSubmit" class="notice-form grid-form">
      <div class="form-row">
        <div class="form-col">
          <label>아이디(이메일) <span class="required">*</span></label>
          <input v-model="email" type="email" required />
        </div>
        <div class="form-col">
          <label>비밀번호 <span class="required">*</span></label>
          <input v-model="password" type="password" required />
        </div>
        <div class="form-col">
          <label>비밀번호 확인 <span class="required">*</span></label>
          <input v-model="confirmPassword" type="password" required />
        </div>
      </div>
      <div class="form-row">
        <div class="form-col">
          <label>업체명 <span class="required">*</span></label>
          <input v-model="companyName" type="text" required />
        </div>
        <div class="form-col">
          <label>사업자등록번호 <span class="required">*</span></label>
          <input v-model="businessNumber" type="text" required />
        </div>
        <div class="form-col">
          <label>대표자 <span class="required">*</span></label>
          <input v-model="representative" type="text" required />
        </div>
      </div>
      <div class="form-row">
        <div class="form-col col-2 align-right">
          <label>사업장 소재지 <span class="required">*</span></label>
          <input v-model="address" type="text" required />
        </div>
        <div class="form-col align-left">
          <label>유선전화</label>
          <input v-model="landline" type="text" />
        </div>
      </div>
      <div class="form-row">
        <div class="form-col">
          <label>담당자 <span class="required">*</span></label>
          <input v-model="contactPerson" type="text" required />
        </div>
        <div class="form-col">
          <label>휴대폰 번호 <span class="required">*</span></label>
          <input v-model="mobile" type="text" required />
        </div>
        <div class="form-col">
          <label>휴대폰 번호 2</label>
          <input v-model="mobile2" type="text" />
        </div>
      </div>
      <div class="form-row">
        <div class="form-col">
          <label>수신용 이메일</label>
          <input v-model="receiveEmail" type="email" />
        </div>
        <div class="form-col">
          <label>구분</label>
          <input v-model="companyGroup" type="text" />
        </div>
        <div class="form-col">
          <label>수수료 등급</label>
          <select v-model="commissionGrade">
            <option disabled value="">등급 선택</option>
            <option v-for="item in commissionGradeOptions" :key="item.value" :value="item.value">
              {{ item.label }}
            </option>
          </select>
        </div>
      </div>
      <div class="form-row">
        <div class="form-col">
          <label>관리자</label>
          <input v-model="manager" type="text" />
        </div>
        <div class="form-col">
          <label>승인여부</label>
          <select v-model="approvalStatus">
            <option disabled value="">승인여부 선택</option>
            <option v-for="item in approvalStatusOptions" :key="item.value" :value="item.value">
              {{ item.label }}
            </option>
          </select>
        </div>
        <div class="form-col"></div>
      </div>
      <div class="form-row">
        <div class="form-col col-3">
          <label>비고</label>
          <input v-model="remarks" type="text" />
        </div>
      </div>
      <div class="btn-row" style="justify-content: flex-end; margin-top: 1.2rem;">
        <Button class="btn-cancel" type="button" @click="goList" label="취소" />
        <Button class="btn-primary" type="submit" label="등록" />
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import Dropdown from 'primevue/dropdown';
import Button from 'primevue/button';
import { supabase } from '@/supabase';

const email = ref('');
const password = ref('');
const confirmPassword = ref('');
const companyName = ref('');
const businessNumber = ref('');
const representative = ref('');
const address = ref('');
const landline = ref('');
const contactPerson = ref('');
const mobile = ref('');
const mobile2 = ref('');
const receiveEmail = ref('');
const companyGroup = ref('');
const commissionGrade = ref('A');
const manager = ref('');
const remarks = ref('');
const approvalStatus = ref('미승인');
const router = useRouter();
const route = useRoute();
const loading = ref(false);

const commissionGradeOptions = [
  { label: 'A', value: 'A' },
  { label: 'B', value: 'B' },
  { label: 'C', value: 'C' }
];
const approvalStatusOptions = [
  { label: '승인', value: '승인' },
  { label: '미승인', value: '미승인' }
];

function getListPath() {
  // 쿼리 또는 라우트에서 listType(approved/pending) 확인
  const type = route.query.listType;
  if (type === 'pending') return '/admin/companies/pending';
  return '/admin/companies/approved';
}

function goList() {
  router.push(getListPath());
}

const handleSubmit = async () => {
  if (loading.value) return;
  // 필수 입력값 체크
  if (!email.value || !password.value || !confirmPassword.value || !companyName.value || !businessNumber.value || !representative.value || !address.value || !contactPerson.value || !mobile.value) {
    alert('필수 항목을 모두 입력해 주세요.');
    return;
  }
  if (password.value !== confirmPassword.value) {
    alert('비밀번호가 일치하지 않습니다.');
    return;
  }
  loading.value = true;
  try {
    // 1. 이메일 중복 체크
    const { data: emailDup } = await supabase.from('companies').select('id').eq('email', email.value).maybeSingle();
    if (emailDup) {
      alert('이미 등록된 이메일입니다.');
      loading.value = false;
      return;
    }
    // 2. 사업자등록번호 중복 체크
    const { data: brnDup } = await supabase.from('companies').select('id').eq('business_registration_number', businessNumber.value).maybeSingle();
    if (brnDup) {
      alert('이미 등록된 사업자등록번호입니다.');
      loading.value = false;
      return;
    }
    // 3. Supabase Auth 회원가입
    const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
      email: email.value,
      password: password.value,
      options: {
        data: {
          user_type: 'user',
          company_name: companyName.value
        }
      }
    });
    if (signUpError) {
      alert('회원가입 실패: ' + signUpError.message);
      loading.value = false;
      return;
    }
    const userId = signUpData.user?.id;
    // 4. companies 테이블에 데이터 저장
    const { error: insertError } = await supabase.from('companies').insert({
      email: email.value,
      password: '', // 보안상 저장하지 않음
      company_name: companyName.value,
      business_registration_number: businessNumber.value,
      representative_name: representative.value,
      business_address: address.value,
      landline_phone: landline.value,
      contact_person_name: contactPerson.value,
      mobile_phone: mobile.value,
      mobile_phone_2: mobile2.value,
      receive_email: receiveEmail.value,
      company_group: companyGroup.value,
      default_commission_grade: commissionGrade.value,
      assigned_pharmacist_contact: manager.value,
      remarks: remarks.value,
      approval_status: approvalStatus.value === '승인' ? 'approved' : 'pending',
      user_id: userId,
      user_type: 'user',
      status: 'active',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    });
    if (insertError) {
      alert('업체 등록 실패: ' + insertError.message);
      loading.value = false;
      return;
    }
    alert('등록되었습니다.');
    if (approvalStatus.value === '승인') {
      router.push('/admin/companies/approved');
    } else {
      router.push('/admin/companies/pending');
    }
  } catch (err) {
    alert('오류: ' + (err.message || err));
  } finally {
    loading.value = false;
  }
};
</script> 