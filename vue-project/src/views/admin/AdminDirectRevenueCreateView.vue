<template>
  <div class="board_640">
    <div class="form-title">직거래매출 등록</div>
    <form @submit.prevent="handleSubmit" class="form-grid">
      <div class="form-group">
        <label>약국코드</label>
        <input v-model="pharmacyCode" type="text" />
      </div>
      <div class="form-group">
        <label>약국명</label>
        <input v-model="pharmacyName" type="text" />
      </div>
      <div class="form-group">
        <label>사업자등록번호<span class="required">*</span></label>
        <input v-model="businessNumber" type="text" required />
      </div>
      <div class="form-group">
        <label>주소</label>
        <input v-model="address" type="text" />
      </div>
      <div class="form-group">
        <label>표준코드<span class="required">*</span></label>
        <input v-model="standardCode" type="text" required />
      </div>
      <div class="form-group">
        <label>제품명</label>
        <input v-model="productName" type="text" />
      </div>
      <div class="form-group">
        <label>매출액<span class="required">*</span></label>
        <input v-model="salesAmount" type="text" required />
      </div>
      <div class="form-group">
        <label>매출일자<span class="required">*</span></label>
        <input v-model="salesDate" type="text" required />
      </div>
      <div style="justify-content: flex-end; margin-top: 2rem;">
        <button class="btn-cancel" type="button" @click="goList" style="margin-right: 1rem;">취소</button>
        <button class="btn-save" type="submit">저장</button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { supabase } from '@/supabase';

const pharmacyCode = ref('');
const pharmacyName = ref('');
const businessNumber = ref('');
const address = ref('');
const standardCode = ref('');
const productName = ref('');
const salesAmount = ref('');
const salesDate = ref('');
const remarks = ref('');
const router = useRouter();

const handleSubmit = async () => {
  if (!businessNumber.value || !standardCode.value || !salesAmount.value || !salesDate.value) {
    alert('필수 항목을 모두 입력하세요.');
    return;
  }
  const { data: { user } } = await supabase.auth.getUser();
  const userId = user?.id;
  const dataToInsert = {
    pharmacy_code: pharmacyCode.value,
    pharmacy_name: pharmacyName.value,
    business_registration_number: businessNumber.value,
    address: address.value,
    standard_code: standardCode.value,
    product_name: productName.value,
    sales_amount: salesAmount.value === '' ? null : Number(salesAmount.value),
    sales_date: salesDate.value,
    created_by: userId,
    updated_by: null
  };
  const { error } = await supabase.from('direct_sales').insert([dataToInsert]);
  if (error) {
    alert('등록 실패: ' + error.message);
  } else {
    alert('등록되었습니다.');
    router.push('/admin/direct-revenue');
  }
};

function goList() {
  router.push('/admin/direct-revenue');
}
</script>