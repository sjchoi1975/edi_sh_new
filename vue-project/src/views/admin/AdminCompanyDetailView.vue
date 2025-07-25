<template>
  <div class="board_640">
    <div class="form-title">업체 상세</div>
    <div class="form-grid">
      <div class="form-group">
        <label>아이디(이메일)</label>
        <input :value="company.email || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>업체명</label>
        <input :value="company.company_name || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>사업자등록번호</label>
        <input :value="company.business_registration_number || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>대표자</label>
        <input :value="company.representative_name || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>사업장 소재지</label>
        <input :value="company.business_address || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>유선전화</label>
        <input :value="company.landline_phone || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>담당자</label>
        <input :value="company.contact_person_name || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>휴대폰 번호</label>
        <input :value="company.mobile_phone || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>휴대폰 번호 2</label>
        <input :value="company.mobile_phone_2 || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>수신용 이메일</label>
        <input :value="company.receive_email || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>구분</label>
        <input :value="company.company_group || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>수수료 등급</label>
        <input :value="company.default_commission_grade || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>관리자</label>
        <input :value="company.assigned_pharmacist_contact || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>승인여부</label>
        <input :value="company.approval_status === 'approved' ? '승인' : (company.approval_status === 'pending' ? '미승인' : '-')" readonly disabled />
      </div>
      <div class="form-group">
        <label>비고</label>
        <input :value="company.remarks || '-'" readonly disabled />
      </div>
      <div class="button-area">        
        <button class="btn-reset-password" @click="handleResetPassword">비밀번호 재설정 이메일 발송</button>
        <button class="btn-edit" @click="goEdit">수정</button>
        <button class="btn-list" @click="goList">목록</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '@/supabase'
import TopNavigationBar from '@/components/TopNavigationBar.vue'

const route = useRoute()
const router = useRouter()
const company = ref({})

const breadcrumbSubMenu = computed(() => {
  if (route.query.from === 'pending') return '미승인 업체';
  return '승인 업체';
});

onMounted(async () => {
  const { data, error } = await supabase
    .from('companies')
    .select('*')
    .eq('id', route.params.id)
    .single()
  if (!error && data) {
    company.value = data
  }
})

function goEdit() {
  const from = route.query.from === 'pending' ? 'pending' : 'approved';
  router.push(`/admin/companies/${route.params.id}/edit?from=${from}`);
}

function goList() {
  const from = route.query.from === 'pending' ? 'pending' : 'approved';
  router.push(`/admin/companies/${from}`);
}

async function handleResetPassword() {
  if (!company.value.email) {
    alert('이메일 정보가 없습니다.');
    return;
  }
  if (!confirm(`${company.value.email}로 비밀번호 재설정 이메일을 발송하시겠습니까?`)) return;
  
  try {
    // Supabase 이메일 비밀번호 재설정 기능 사용
    const { error } = await supabase.auth.resetPasswordForEmail(company.value.email, {
      redirectTo: `${window.location.origin}/reset-password`
    });
    
    if (error) {
      console.error('비밀번호 재설정 이메일 발송 오류:', error);
      throw new Error(error.message || '이메일 발송에 실패했습니다.');
    }
    
    alert(`${company.value.email}로 비밀번호 재설정 이메일이 발송되었습니다.\n해당 업체에서 이메일을 확인하여 비밀번호를 재설정하도록 안내해주세요.`);
  } catch (error) {
    console.error('비밀번호 재설정 이메일 발송 실패:', error);
    alert('이메일 발송 실패: ' + error.message);
  }
}
</script>
