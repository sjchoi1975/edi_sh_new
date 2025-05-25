<template>
  <div class="board_960">
    <div class="form-title">거래처 등록</div>
    <form @submit.prevent="handleSubmit" class="notice-form grid-form">
      <div class="form-row">
        <div class="form-col col-2">
          <label>거래처코드 <span class="required">*</span></label>
          <input v-model="clientCode" type="text" required />
        </div>
        <div class="form-col col-2">
          <label>병의원명 <span class="required">*</span></label>
          <input v-model="name" type="text" required />
        </div>
      </div>
      <div class="form-row">
        <div class="form-col col-2">
          <label>사업자등록번호</label>
          <input v-model="businessNumber" type="text" />
        </div>
        <div class="form-col col-2">
          <label>원장명</label>
          <input v-model="ownerName" type="text" />
        </div>
      </div>
      <div class="form-row">
        <div class="form-col col-2">
          <label>주소</label>
          <input v-model="address" type="text" />
        </div>
        <div class="form-col col-2">
          <label>상태</label>
          <select v-model="status">
            <option value="active">활성</option>
            <option value="inactive">비활성</option>
          </select>
        </div>
      </div>
      <div class="form-row">
        <div class="form-col col-3">
          <label>비고</label>
          <input v-model="remarks" type="text" />
        </div>
      </div>
      <div class="btn-row">
        <button class="btn-cancel" type="button" @click="goList">취소</button>
        <button class="btn-primary" type="submit">저장</button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { supabase } from '@/supabase';

const clientCode = ref('');
const name = ref('');
const businessNumber = ref('');
const ownerName = ref('');
const address = ref('');
const status = ref('active');
const remarks = ref('');
const router = useRouter();

const handleSubmit = async () => {
  if (!clientCode.value || !name.value) {
    alert('필수 항목을 모두 입력하세요.');
    return;
  }
  const { error } = await supabase.from('clients').insert([{
    client_code: clientCode.value,
    name: name.value,
    business_registration_number: businessNumber.value,
    owner_name: ownerName.value,
    address: address.value,
    status: status.value,
    remarks: remarks.value
  }]);
  if (error) {
    alert('등록 실패: ' + error.message);
  } else {
    alert('등록되었습니다.');
    router.push('/admin/clients');
  }
};

function goList() {
  router.push('/admin/clients');
}
</script>
