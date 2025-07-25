<template>
  <TopNavigationBar :breadcrumbMenu="'업체 관리'" :breadcrumbSubMenu="breadcrumbSubMenu" />
  <div class="board_640">
    <div class="form-title">업체 수정</div>
    <form @submit.prevent="handleSubmit" class="form-grid">
      <div class="form-group">
        <label>아이디(이메일)<span class="required">*</span></label>
        <input v-model="email" type="email" required />
      </div>
      <div class="form-group">
        <label>업체명<span class="required">*</span></label>
        <input v-model="companyName" type="text" required />
      </div>
      <div class="form-group">
        <label>사업자등록번호<span class="required">*</span></label>
        <input v-model="businessNumber" type="text" required />
      </div>
      <div class="form-group">
        <label>대표자<span class="required">*</span></label>
        <input v-model="representative" type="text" required />
      </div>
      <div class="form-group">
        <label>사업장 소재지<span class="required">*</span></label>
        <input v-model="address" type="text" required />
      </div>
      <div class="form-group">
        <label>유선전화</label>
        <input v-model="landline" type="text" />
      </div>
      <div class="form-group">
        <label>담당자<span class="required">*</span></label>
        <input v-model="contactPerson" type="text" required />
      </div>
      <div class="form-group">
        <label>휴대폰 번호<span class="required">*</span></label>
        <input v-model="mobile" type="text" required />
      </div>
      <div class="form-group">
        <label>휴대폰 번호 2</label>
        <input v-model="mobile2" type="text" />
      </div>
      <div class="form-group">
        <label>수신용 이메일</label>
        <input v-model="receiveEmail" type="email" />
      </div>
      <div class="form-group">
        <label>구분</label>
        <input v-model="companyGroup" type="text" />
      </div>
      <div class="form-group">
        <label>수수료 등급</label>
        <select v-model="commissionGrade">
          <option disabled value="">등급 선택</option>
          <option v-for="item in commissionGradeOptions" :key="item.value" :value="item.value">
            {{ item.label }}
          </option>
        </select>
      </div>
      <div class="form-group">
        <label>관리자</label>
        <input v-model="manager" type="text" />
      </div>
      <div class="form-group">
        <label>승인여부</label>
        <select v-model="approvalStatus">
          <option disabled value="">승인여부 선택</option>
          <option v-for="item in approvalStatusOptions" :key="item.value" :value="item.value">
            {{ item.label }}
          </option>
        </select>
      </div>
      <div class="form-group">
        <label>비고</label>
        <input v-model="remarks" type="text" />
      </div>
      <div style="justify-content: flex-end; margin-top: 2rem;">
        <button class="btn-cancel" type="button" @click="goDetail" style="margin-right: 1rem;">취소</button>
        <button class="btn-save" type="submit">저장</button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { supabase } from '@/supabase';
import TopNavigationBar from '@/components/TopNavigationBar.vue';

const email = ref('');
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
const commissionGrade = ref('');
const manager = ref('');
const remarks = ref('');
const approvalStatus = ref('');
const router = useRouter();
const route = useRoute();
const loading = ref(false);

const commissionGradeOptions = [
  { label: 'A', value: 'A' },
  { label: 'B', value: 'B' },
  { label: 'C', value: 'C' }
];
const approvalStatusOptions = [
  { label: '승인', value: 'approved' },
  { label: '미승인', value: 'pending' }
];

const breadcrumbSubMenu = computed(() => {
  if (route.query.from === 'pending') return '미승인 업체';
  return '승인 업체';
});

onMounted(async () => {
  const { data, error } = await supabase
    .from('companies')
    .select('*')
    .eq('id', route.params.id)
    .single();
  if (!error && data) {
    email.value = data.email || '';
    companyName.value = data.company_name || '';
    businessNumber.value = data.business_registration_number || '';
    representative.value = data.representative_name || '';
    address.value = data.business_address || '';
    landline.value = data.landline_phone || '';
    contactPerson.value = data.contact_person_name || '';
    mobile.value = data.mobile_phone || '';
    mobile2.value = data.mobile_phone_2 || '';
    receiveEmail.value = data.receive_email || '';
    companyGroup.value = data.company_group || '';
    commissionGrade.value = data.default_commission_grade || '';
    manager.value = data.assigned_pharmacist_contact || '';
    remarks.value = data.remarks || '';
    approvalStatus.value = data.approval_status || '';
  }
});

function goDetail() {
  const from = route.query.from === 'pending' ? 'pending' : 'approved';
  router.push(`/admin/companies/${route.params.id}?from=${from}`);
}

const handleSubmit = async () => {
  try {
    loading.value = true;
    const currentUser = await supabase.auth.getUser();
    if (!currentUser.data.user) {
      alert('로그인 정보가 없습니다. 다시 로그인해주세요.');
      loading.value = false;
      return;
    }
    const adminUserId = currentUser.data.user.id;

    const { error } = await supabase
      .from('companies')
      .update({
        email: email.value,
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
        approval_status: approvalStatus.value,
        remarks: remarks.value,
        updated_at: new Date().toISOString(),
        updated_by: adminUserId,
      })
      .eq('id', route.params.id);

    if (error) throw error;
    alert('수정되었습니다.');
    const from = route.query.from === 'pending' ? 'pending' : 'approved';
    router.push(`/admin/companies/${from}`);
  } catch (err) {
    console.error('업체 정보 수정 중 오류가 발생했습니다.', err);
    alert('업체 정보 수정에 실패했습니다.');
  } finally {
    loading.value = false;
  }
};
</script>