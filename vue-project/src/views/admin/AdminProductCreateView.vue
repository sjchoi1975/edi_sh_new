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
        <input id="insuranceCode" v-model="insuranceCode" type="text" maxlength="9" required @keypress="allowOnlyNumbers" />
      </div>
      <div class="form-group">
        <label>약가<span class="required">*</span></label>
        <input v-model="price" type="number" required />
      </div>
      <div class="form-group">
        <label>수수료율 A등급(%)</label>
        <input v-model="commissionA" type="number" step="0.001" />
      </div>
      <div class="form-group">
        <label>수수료율 B등급(%)</label>
        <input v-model="commissionB" type="number" step="0.001" />
      </div>
      <div class="form-group">
        <label>수수료율 C등급(%)</label>
        <input v-model="commissionC" type="number" step="0.001" />
      </div>
      <div class="form-group">
        <label>표준코드<span class="required">*</span></label>
        <input id="standardCode" v-model="standardCode" type="text" maxlength="13" required @keypress="allowOnlyNumbers" />
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
      <div class="button-area">
        <button class="btn-cancel" type="button" @click="goList">취소</button>
        <button class="btn-save" type="submit" :disabled="!isFormValid">등록</button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
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

// 필수 필드 검증
const isFormValid = computed(() => {
  return baseMonth.value && baseMonth.value.trim() !== '' &&
         productName.value && productName.value.trim() !== '' &&
         insuranceCode.value && insuranceCode.value.trim() !== '' &&
         price.value && price.value.toString().trim() !== '' &&
         standardCode.value && standardCode.value.trim() !== '';
});

// 숫자만 입력 허용
const allowOnlyNumbers = (event) => {
  const charCode = event.which ? event.which : event.keyCode;
  if (charCode > 31 && (charCode < 48 || charCode > 57)) {
    event.preventDefault();
  }
};

const handleSubmit = async () => {
  // 필수 필드 검증
  if (!baseMonth.value || !productName.value || !insuranceCode.value || !price.value || !standardCode.value) {
    alert('필수 항목을 모두 입력하세요.');
    return;
  }

  // 보험코드 형식 검증 (9자리 숫자)
  if (insuranceCode.value.length !== 9 || !/^\d{9}$/.test(insuranceCode.value)) {
    alert('보험코드는 9자리 숫자여야 합니다.');
    setTimeout(() => {
      const insuranceCodeInput = document.getElementById('insuranceCode');
      if (insuranceCodeInput) {
        insuranceCodeInput.focus();
        insuranceCodeInput.select();
      }
    }, 100);
    return;
  }

  // 표준코드 형식 검증 (13자리 숫자)
  if (standardCode.value.length !== 13 || !/^\d{13}$/.test(standardCode.value)) {
    alert('표준코드는 13자리 숫자여야 합니다.');
    setTimeout(() => {
      const standardCodeInput = document.getElementById('standardCode');
      if (standardCodeInput) {
        standardCodeInput.focus();
        standardCodeInput.select();
      }
    }, 100);
    return;
  }

  // 약가 형식 검증 (0 이상의 숫자)
  if (price.value && (isNaN(Number(price.value)) || Number(price.value) < 0)) {
    alert('약가는 0 이상의 숫자여야 합니다.');
    setTimeout(() => {
      const priceInput = document.querySelector('input[v-model="price"]');
      if (priceInput) {
        priceInput.focus();
        priceInput.select();
      }
    }, 100);
    return;
  }

  // 수수료율 A 검증 (0~1, 소수점 3자리)
  if (commissionA.value && commissionA.value.toString().trim() !== '') {
    const commissionAValue = Number(commissionA.value);
    if (isNaN(commissionAValue) || commissionAValue < 0 || commissionAValue > 1) {
      alert('수수료율 A는 0~1 사이의 숫자여야 합니다.');
      setTimeout(() => {
        const commissionAInput = document.querySelector('input[v-model="commissionA"]');
        if (commissionAInput) {
          commissionAInput.focus();
          commissionAInput.select();
        }
      }, 100);
      return;
    }
    // 소수점 3자리로 반올림
    commissionA.value = Math.round(commissionAValue * 1000) / 1000;
  }

  // 수수료율 B 검증 (0~1, 소수점 3자리)
  if (commissionB.value && commissionB.value.toString().trim() !== '') {
    const commissionBValue = Number(commissionB.value);
    if (isNaN(commissionBValue) || commissionBValue < 0 || commissionBValue > 1) {
      alert('수수료율 B는 0~1 사이의 숫자여야 합니다.');
      setTimeout(() => {
        const commissionBInput = document.querySelector('input[v-model="commissionB"]');
        if (commissionBInput) {
          commissionBInput.focus();
          commissionBInput.select();
        }
      }, 100);
      return;
    }
    // 소수점 3자리로 반올림
    commissionB.value = Math.round(commissionBValue * 1000) / 1000;
  }

  // 수수료율 C 검증 (0~1, 소수점 3자리)
  if (commissionC.value && commissionC.value.toString().trim() !== '') {
    const commissionCValue = Number(commissionC.value);
    if (isNaN(commissionCValue) || commissionCValue < 0 || commissionCValue > 1) {
      alert('수수료율 C는 0~1 사이의 숫자여야 합니다.');
      setTimeout(() => {
        const commissionCInput = document.querySelector('input[v-model="commissionC"]');
        if (commissionCInput) {
          commissionCInput.focus();
          commissionCInput.select();
        }
      }, 100);
      return;
    }
    // 소수점 3자리로 반올림
    commissionC.value = Math.round(commissionCValue * 1000) / 1000;
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
