<template>
  <div class="board_640">
    <div class="form-title">제품 수정</div>
    <form @submit.prevent="handleSubmit" class="form-grid">
      <div class="form-group">
        <label>기준월<span class="required">*</span></label>
        <input id="baseMonth" v-model="baseMonth" type="text" placeholder="YYYY-MM" maxlength="7" required />
      </div>
      <div class="form-group">
        <label>제품명<span class="required">*</span></label>
        <input id="productName" v-model="productName" type="text" required />
      </div>
      <div class="form-group">
        <label>보험코드<span class="required">*</span></label>
        <input id="insuranceCode" v-model="insuranceCode" type="text" maxlength="9" required />
      </div>
      <div class="form-group">
        <label>약가<span class="required">*</span></label>
        <input id="price" v-model="price" type="number" required />
      </div>
      <div class="form-group">
        <label>수수료율 A등급(%)</label>
        <input id="commissionA" v-model="commissionA" type="number" step="0.001" />
      </div>
      <div class="form-group">
        <label>수수료율 B등급(%)</label>
        <input id="commissionB" v-model="commissionB" type="number" step="0.001" />
      </div>
      <div class="form-group">
        <label>수수료율 C등급(%)</label>
        <input id="commissionC" v-model="commissionC" type="number" step="0.001" />
      </div>
      <div class="form-group">
        <label>표준코드<span class="required">*</span></label>
        <input id="standardCode" v-model="standardCode" type="text" maxlength="13" required />
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
        <button class="btn-cancel" type="button" @click="goDetail">취소</button>
        <button class="btn-save" type="submit" :disabled="!isFormValid">수정</button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { supabase } from '@/supabase';

const route = useRoute();
const router = useRouter();
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

// 원본 데이터 저장
const originalData = ref({
  baseMonth: '',
  productName: '',
  insuranceCode: '',
  price: '',
  commissionA: '',
  commissionB: '',
  commissionC: '',
  standardCode: '',
  unitPackagingDesc: '',
  unitQuantity: '',
  status: '',
  remarks: ''
});

// 필수 필드 검증 및 변경값 감지
const isFormValid = computed(() => {
  // 필수값 검증
  const hasRequiredFields = baseMonth.value && baseMonth.value.trim() !== '' && 
                           productName.value && productName.value.trim() !== '' && 
                           insuranceCode.value && insuranceCode.value.toString().trim() !== '' && 
                           price.value && price.value.toString().trim() !== '' && 
                           standardCode.value && standardCode.value.toString().trim() !== '';
  
  // 변경값 감지
  const hasChanges = baseMonth.value !== originalData.value.baseMonth ||
                    productName.value !== originalData.value.productName ||
                    insuranceCode.value !== originalData.value.insuranceCode ||
                    price.value !== originalData.value.price ||
                    commissionA.value !== originalData.value.commissionA ||
                    commissionB.value !== originalData.value.commissionB ||
                    commissionC.value !== originalData.value.commissionC ||
                    standardCode.value !== originalData.value.standardCode ||
                    unitPackagingDesc.value !== originalData.value.unitPackagingDesc ||
                    unitQuantity.value !== originalData.value.unitQuantity ||
                    status.value !== originalData.value.status ||
                    remarks.value !== originalData.value.remarks;
  
  return hasRequiredFields && hasChanges;
});

onMounted(async () => {
  const { data, error } = await supabase
    .from('products')
    .select('*')
    .eq('id', route.params.id)
    .single();
  if (!error && data) {
    baseMonth.value = data.base_month;
    productName.value = data.product_name;
    insuranceCode.value = data.insurance_code;
    price.value = data.price;
    commissionA.value = data.commission_rate_a ? data.commission_rate_a : '';
    commissionB.value = data.commission_rate_b ? data.commission_rate_b : '';
    commissionC.value = data.commission_rate_c ? data.commission_rate_c : '';
    standardCode.value = data.standard_code;
    unitPackagingDesc.value = data.unit_packaging_desc;
    unitQuantity.value = data.unit_quantity;
    status.value = data.status;
    remarks.value = data.remarks;
    
    // 원본 데이터 저장
    originalData.value.baseMonth = data.base_month;
    originalData.value.productName = data.product_name;
    originalData.value.insuranceCode = data.insurance_code;
    originalData.value.price = data.price;
    originalData.value.commissionA = data.commission_rate_a ? data.commission_rate_a : '';
    originalData.value.commissionB = data.commission_rate_b ? data.commission_rate_b : '';
    originalData.value.commissionC = data.commission_rate_c ? data.commission_rate_c : '';
    originalData.value.standardCode = data.standard_code;
    originalData.value.unitPackagingDesc = data.unit_packaging_desc;
    originalData.value.unitQuantity = data.unit_quantity;
    originalData.value.status = data.status;
    originalData.value.remarks = data.remarks;
  }
});

const handleSubmit = async () => {
  // 필수 필드 검증
  if (!baseMonth.value || baseMonth.value.trim() === '') {
    alert('기준월은 필수 입력 항목입니다.');
    setTimeout(() => {
      const baseMonthInput = document.getElementById('baseMonth');
      if (baseMonthInput) {
        baseMonthInput.focus();
        baseMonthInput.select();
      }
    }, 100);
    return;
  }

  if (!productName.value || productName.value.trim() === '') {
    alert('제품명은 필수 입력 항목입니다.');
    setTimeout(() => {
      const productNameInput = document.getElementById('productName');
      if (productNameInput) {
        productNameInput.focus();
        productNameInput.select();
      }
    }, 100);
    return;
  }

  if (!insuranceCode.value || insuranceCode.value.toString().trim() === '') {
    alert('보험코드는 필수 입력 항목입니다.');
    setTimeout(() => {
      const insuranceCodeInput = document.getElementById('insuranceCode');
      if (insuranceCodeInput) {
        insuranceCodeInput.focus();
        insuranceCodeInput.select();
      }
    }, 100);
    return;
  }

  if (!price.value || price.value.toString().trim() === '') {
    alert('약가는 필수 입력 항목입니다.');
    setTimeout(() => {
      const priceInput = document.getElementById('price');
      if (priceInput) {
        priceInput.focus();
        priceInput.select();
      }
    }, 100);
    return;
  }

  if (!standardCode.value || standardCode.value.toString().trim() === '') {
    alert('표준코드는 필수 입력 항목입니다.');
    setTimeout(() => {
      const standardCodeInput = document.getElementById('standardCode');
      if (standardCodeInput) {
        standardCodeInput.focus();
        standardCodeInput.select();
      }
    }, 100);
    return;
  }

  // 기준월 형식 검증 (YYYY-MM)
  const monthRegex = /^\d{4}-\d{2}$/;
  if (!monthRegex.test(baseMonth.value)) {
    alert('기준월은 YYYY-MM 형식으로 입력해주세요.');
    setTimeout(() => {
      const baseMonthInput = document.getElementById('baseMonth');
      if (baseMonthInput) {
        baseMonthInput.focus();
        baseMonthInput.select();
      }
    }, 100);
    return;
  }

  // 보험코드 형식 검증 (9자리 숫자)
  if (insuranceCode.value.toString().length !== 9 || !/^\d{9}$/.test(insuranceCode.value.toString())) {
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
  if (standardCode.value.toString().length !== 13 || !/^\d{13}$/.test(standardCode.value.toString())) {
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
      const priceInput = document.getElementById('price');
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
        const commissionAInput = document.getElementById('commissionA');
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
        const commissionBInput = document.getElementById('commissionB');
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
        const commissionCInput = document.getElementById('commissionC');
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

  const dataToUpdate = {
    base_month: baseMonth.value,
    product_name: productName.value,
    insurance_code: insuranceCode.value === '' ? null : Number(insuranceCode.value),
    price: price.value === '' ? null : Number(price.value),
    commission_rate_a: commissionA.value === '' ? 0 : Number(commissionA.value),
    commission_rate_b: commissionB.value === '' ? 0 : Number(commissionB.value),
    commission_rate_c: commissionC.value === '' ? 0 : Number(commissionC.value),
    standard_code: standardCode.value === '' ? null : standardCode.value,
    unit_packaging_desc: unitPackagingDesc.value,
    unit_quantity: unitQuantity.value === '' ? null : Number(unitQuantity.value),
    status: status.value,
    remarks: remarks.value
  };
  
  const { error } = await supabase
    .from('products')
    .update(dataToUpdate)
    .eq('id', route.params.id);
  if (error) {
    alert('수정 실패: ' + error.message);
  } else {
    alert('수정되었습니다.');
    router.push('/admin/products');
  }
};

function goDetail() {
  router.push(`/admin/products/${route.params.id}`);
}
</script>
