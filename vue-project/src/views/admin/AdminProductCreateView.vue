<template>
  <div class="board_640">
    <div class="form-title">제품 등록</div>
    <form @submit.prevent="handleSubmit" class="form-grid">
      <div class="form-group">
        <label>기준월<span class="required">*</span></label>
        <input v-model="baseMonth" type="text" placeholder="YYYY-MM" maxlength="7" required />
      </div>
      <div class="form-group">
        <label>제품명<span class="required">*</span></label>
        <input v-model="productName" type="text" required />
      </div>
      <div class="form-group">
        <label>보험코드<span class="required">*</span></label>
        <input v-model="insuranceCode" type="number" maxlength="9" required />
      </div>
      <div class="form-group">
        <label>약가<span class="required">*</span></label>
        <input v-model="price" type="number" required />
      </div>
      <div class="form-group">
        <label>수수료율 A</label>
        <input v-model="commissionA" type="number" step="0.001" required />
      </div>
      <div class="form-group">
        <label>수수료율 B</label>
        <input v-model="commissionB" type="number" step="0.001" required />
      </div>
      <div class="form-group">
        <label>수수료율 C</label>
        <input v-model="commissionC" type="number" step="0.001" />
      </div>
      <div class="form-group">
        <label>표준코드<span class="required">*</span></label>
        <input v-model="standardCode" type="text" maxlength="13" required />
      </div>
      <div class="form-group">
        <label>단위/포장형태</label>
        <input v-model="unitPackagingDesc" type="text" />
      </div>
      <div class="form-group">
        <label>단위수량</label>
        <input v-model="unitQuantity" type="number" />
      </div>
      <div class="form-group">
        <label>상태</label>
        <select v-model="status">
          <option value="active">활성</option>
          <option value="inactive">비활성</option>
        </select>
      </div>
      <div class="form-group">
        <label>비고</label>
        <input v-model="remarks" type="text" />
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

const baseMonth = ref('');
const productName = ref('');
const insuranceCode = ref('');
const price = ref('');
const commissionA = ref('');
const commissionB = ref('');
const commissionC = ref('');
const standardCode = ref('');
const unitPackagingDesc = ref('');
const unitQuantity = ref('');
const status = ref('active');
const remarks = ref('');
const router = useRouter();

const handleSubmit = async () => {
  if (!baseMonth.value || !productName.value || !insuranceCode.value || !price.value || !commissionA.value || !commissionB.value || !standardCode.value) {
    alert('필수 항목을 모두 입력하세요.');
    return;
  }
  const dataToInsert = {
    base_month: baseMonth.value,
    product_name: productName.value,
    insurance_code: insuranceCode.value === '' ? null : Number(insuranceCode.value),
    price: price.value === '' ? null : Number(price.value),
    commission_rate_a: commissionA.value === '' ? null : Number(commissionA.value),
    commission_rate_b: commissionB.value === '' ? null : Number(commissionB.value),
    commission_rate_c: commissionC.value === '' ? null : Number(commissionC.value),
    standard_code: standardCode.value === '' ? null : standardCode.value,
    unit_packaging_desc: unitPackagingDesc.value,
    unit_quantity: unitQuantity.value === '' ? null : Number(unitQuantity.value),
    status: status.value,
    remarks: remarks.value
  };
  const { error } = await supabase.from('products').insert([dataToInsert]);
  if (error) {
    alert('등록 실패: ' + error.message);
  } else {
    alert('등록되었습니다.');
    router.push('/admin/products');
  }
};

function goList() {
  router.push('/admin/products');
}
</script> 
