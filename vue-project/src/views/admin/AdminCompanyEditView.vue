<template>
  <div class="board_960">
    <div class="form-title">업체 정보 수정</div>
    <form @submit.prevent="handleSubmit" class="notice-form grid-form">
      <div class="form-row">
        <div class="form-col">
          <label>아이디(이메일)</label>
          <span class="input-readonly">{{ email }}</span>
        </div>
        <div class="form-col"></div>
        <div class="form-col"></div>
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
        <div class="form-col col-2">
          <label>사업장 소재지 <span class="required">*</span></label>
          <input v-model="address" type="text" required />
        </div>
        <div class="form-col">
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
        <button class="btn-cancel" type="button" @click="goDetail">취소</button>
        <button class="btn-primary" type="submit">저장</button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { supabase } from '@/supabase';

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
  if (loading.value) return;
  loading.value = true;
  try {
    const currentUser = await supabase.auth.getUser();
    if (!currentUser.data.user) {
      alert('로그인 정보가 없습니다. 다시 로그인해주세요.');
      loading.value = false;
      return;
    }
    const adminUserId = currentUser.data.user.id;

    // 기존 업체 정보를 불러와서 approved_at 값 확인
    const { data: existingCompany, error: fetchError } = await supabase
      .from('companies')
      .select('approved_at')
      .eq('id', route.params.id)
      .single();

    if (fetchError) {
      alert('기존 업체 정보 조회 실패: ' + fetchError.message);
      loading.value = false;
      return;
    }

    const updatePayload = {
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
      approval_status: approvalStatus.value,
      updated_at: new Date().toISOString(),
      updated_by: adminUserId // 최종 수정자 ID 추가
    };

    // 승인 상태로 변경되고, 기존 approved_at이 없을 경우 (최초 승인)
    if (approvalStatus.value === 'approved' && !existingCompany?.approved_at) {
      updatePayload.approved_at = new Date().toISOString();
    }

    const { error } = await supabase.from('companies').update(updatePayload).eq('id', route.params.id);
    if (error) {
      alert('수정 실패: ' + error.message);
      loading.value = false;
      return;
    }
    alert('수정되었습니다.');
    // 수정 후 목록으로 이동
    const from = route.query.from === 'pending' ? 'pending' : 'approved';
    router.push(`/admin/companies/${from}`);
  } catch (err) {
    alert('오류: ' + (err.message || err));
  } finally {
    loading.value = false;
  }
};
</script>