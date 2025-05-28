<template>
  <div class="performance-register-view">
    <div class="header-title">실적 등록</div>
    <div class="table-container" style="position:relative;">
      <div style="display:flex;gap:32px;margin-bottom:12px;align-items:center;">
        <div style="display:flex;align-items:center;width:200px;height:32px;border:1px solid #aaa;background:#fff;">
          <span style="display:inline-block;width:80px;text-align:center;background:#f5f5f5;height:100%;line-height:30px;border-right:1px solid #aaa;">정산월</span>
          <span style="flex:1;text-align:center;">{{ activeMonth ? activeMonth.settlement_month : '' }}</span>
        </div>
        <div style="display:flex;align-items:center;width:300px;height:32px;border:1px solid #aaa;background:#fff;">
          <span style="display:inline-block;width:80px;text-align:center;background:#f5f5f5;height:100%;line-height:30px;border-right:1px solid #aaa;">제출기간</span>
          <span style="flex:1;text-align:center;">{{ activeMonth ? (activeMonth.start_date + ' ~ ' + activeMonth.end_date) : '' }}</span>
        </div>
        <!-- 처방월 박스 -->
        <div style="display:flex;align-items:center;width:200px;height:32px;border:1px solid #aaa;background:#fff;">
          <span style="display:inline-block;width:80px;text-align:center;background:#f5f5f5;height:100%;line-height:30px;border-right:1px solid #aaa;">처방월</span>
          <select v-model="prescriptionOffset" style="flex:1;height:30px;border:none;background:transparent;outline:none;text-align:center;font-size:1rem;line-height:28px;padding:0;">
            <option v-for="opt in prescriptionOptions" :key="opt.value" :value="opt.value">
              {{ opt.month }}
            </option>
          </select>
        </div>
      </div>
      
      <div style="display:flex;align-items:center;margin-bottom:12px;">
        <div style="display:flex;align-items:center;flex:1;">
          <div style="display:flex;align-items:center;width:352px;height:32px;border:1px solid #aaa;background:#fff;">
            <span style="display:inline-block;width:80px;text-align:center;background:#f5f5f5;height:100%;line-height:30px;border-right:1px solid #aaa;">병원 선택</span>
            <input type="text" v-model="selectedHospitalName" readonly @click="openHospitalModal" style="flex:1;height:30px;border:none;padding:0 8px;background:#fff;outline:none;cursor:pointer;line-height:30px;display:flex;align-items:center;" placeholder="병원명을 선택하세요" />
          </div>
          <span v-if="selectedHospitalInfo" style="margin-left:8px;font-size:1rem;color:#666;white-space:nowrap;">
            ({{ selectedHospitalInfo.business_registration_number }}, {{ selectedHospitalInfo.owner_name }}, {{ selectedHospitalInfo.address }})
          </span>
        </div>
        <button class="btn-primary" @click="onRegister" :disabled="!canRegister" style="margin-left:16px;">등록</button>
      </div>
      
      <table class="input-table">
        <thead>
          <tr>
            <th style="width:32px;"></th>
            <th style="width:18%">제품명</th>
            <th style="width:14%">보험코드</th>
            <th style="width:8%">약가</th>
            <th style="width:8%">처방수량</th>
            <th style="width:8%">처방액</th>
            <th style="width:12%">처방구분</th>
            <th style="width:12%">비고</th>
            <th style="width:60px;"></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(row, rowIdx) in inputRows" :key="rowIdx">
            <td></td>
            <td style="position:relative;">
              <input
                v-model="row.product_name_display"
                :tabindex="isInputEnabled ? 0 : -1"
                @input="handleProductNameInput(rowIdx, $event)"
                @keydown.enter.prevent="applySelectedProductFromSearch(rowIdx)"
                @keydown.down.prevent="navigateProductSearchList('down')"
                @keydown.up.prevent="navigateProductSearchList('up')"
                @keydown="onArrowKey($event, rowIdx, 'product_name')"
                @focus="currentCell = {row: rowIdx, col: 'product_name'}; productSearchForRow.activeRowIndex = rowIdx;"
                @blur="setTimeout(() => hideProductSearchList(rowIdx), 200)" 
                :disabled="!isInputEnabled"
                :class="cellClass(rowIdx, 'product_name')"
                style="width:100%;background:#fff;"
                autocomplete="off"
              />
              <div v-if="productSearchForRow.show && productSearchForRow.activeRowIndex === rowIdx && productSearchForRow.results.length > 0" class="product-search-dropdown">
                <ul>
                  <li
                    v-for="(product, index) in productSearchForRow.results"
                    :key="product.id"
                    @click="clickProductFromSearchList(product, rowIdx)"
                    :class="{ 'selected': productSearchForRow.selectedIndex === index }"
                  >
                    {{ product.product_name }} ({{ product.insurance_code }}) - {{ product.price }}
                  </li>
                </ul>
              </div>
            </td>
            <td>
              <input v-model="row.insurance_code" readonly tabindex="-1" style="width:100%;background:#f5f5f5;" />
            </td>
            <td>
              <input v-model="row.price" readonly tabindex="-1" style="width:100%;background:#f5f5f5;" />
            </td>
            <td>
              <input
                v-model="row.prescription_qty"
                :tabindex="isInputEnabled ? 0 : -1"
                @keydown.enter.prevent="addOrFocusNextRow(rowIdx)"
                @keydown="onArrowKey($event, rowIdx, 'prescription_qty')"
                @input="onQtyInput(rowIdx)"
                @focus="currentCell = {row: rowIdx, col: 'prescription_qty'}"
                :disabled="!isInputEnabled"
                :class="cellClass(rowIdx, 'prescription_qty')"
                style="width:100%;background:#fff;"
              />
            </td>
            <td>
              <input v-model="row.prescription_amount" readonly tabindex="-1" style="width:100%;background:#f5f5f5;" />
            </td>
            <td>
              <select
                v-model="row.prescription_type"
                :tabindex="isInputEnabled ? 0 : -1"
                @change="onPrescriptionTypeInput(rowIdx)"
                @keydown="onArrowKey($event, rowIdx, 'prescription_type')"
                @focus="currentCell = {row: rowIdx, col: 'prescription_type'}"
                :disabled="!isInputEnabled"
                :class="cellClass(rowIdx, 'prescription_type')"
                style="width:100%;background:#fff;"
              >
                <option v-for="type in prescriptionTypeOptions" :key="type" :value="type">{{ type }}</option>
              </select>
            </td>
            <td>
              <input
                v-model="row.remarks"
                :tabindex="isInputEnabled ? 0 : -1"
                @keydown="onArrowKey($event, rowIdx, 'remarks')"
                @focus="currentCell = {row: rowIdx, col: 'remarks'}"
                :disabled="!isInputEnabled"
                :class="cellClass(rowIdx, 'remarks')"
                style="width:100%;background:#fff;"
              />
            </td>
            <td class="action-cell">
              <button class="btn-row" @click="addRowBelow(rowIdx)" title="아래에 행 추가">＋</button>
              <button class="btn-row" @click="deleteRow(rowIdx)" :disabled="inputRows.length === 1" title="행 삭제">－</button>
            </td>
          </tr>
        </tbody>
        <tfoot>
          <tr>
            <td colspan="4" style="text-align:right;font-weight:bold;">합계</td>
            <td style="text-align:right;font-weight:bold;">{{ totalQty }}</td>
            <td style="text-align:right;font-weight:bold;">{{ totalAmount }}</td>
            <td colspan="3"></td>
          </tr>
        </tfoot>
      </table>
      
      <div v-if="!activeMonth" style="position:absolute;top:0;left:0;width:100%;height:100%;display:flex;align-items:center;justify-content:center;z-index:10;background:rgba(255,255,255,0.85);">
        <div style="font-size:1.3rem;color:#d32f2f;text-align:center;">지금은 실적 입력 기간이 아닙니다.</div>
      </div>
      
      <!-- 병원 선택 모달 -->
      <Dialog v-model:visible="hospitalModalVisible" header="병원 선택" :modal="true" :closable="true" style="min-width:700px;">
        <div>
          <InputText v-model="hospitalSearch" placeholder="병원명, 사업자등록번호, 원장명, 주소 검색" style="width:100%;margin-bottom:12px;" />
          <DataTable
            :value="filteredHospitals" 
            class="custom-table"
            style="min-width:600px;"
            selectionMode="single"
            v-model:selection="selectedHospitalRow"
            @rowSelect="onHospitalRowSelect"
          >
            <Column field="name" header="병원명" :headerStyle="{ width: '24%' }" />
            <Column field="business_registration_number" header="사업자등록번호" :headerStyle="{ width: '18%' }" />
            <Column field="owner_name" header="원장명" :headerStyle="{ width: '14%' }" />
            <Column field="address" header="주소" :headerStyle="{ width: '44%' }" />
          </DataTable>
        </div>
      </Dialog>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, nextTick } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Dialog from 'primevue/dialog';
import InputText from 'primevue/inputtext';
import { supabase } from '@/supabase';

// 반응형 데이터
const activeMonth = ref(null);
const prescriptionMonth = ref('');
const prescriptionOffset = ref(1); // 1: -1M, 2: -2M, 3: -3M
const prescriptionOptions = ref([]);
const selectedHospitalName = ref('');
const selectedHospitalInfo = ref(null);
const selectedHospitalId = ref(null);
const hospitalModalVisible = ref(false);
const hospitalSearch = ref('');
const hospitals = ref([]);
const selectedHospitalRow = ref(null);

// 실적 입력용 행 (최소 1개 빈 행)
const inputRows = ref([{ 
  product_name_display: '', 
  product_id: null, 
  insurance_code: '', 
  price: '', 
  prescription_qty: '', 
  prescription_amount: '', 
  prescription_type: 'EDI', 
  remarks: '' 
}]);

// 계산된 속성
const isInputEnabled = computed(() => !!selectedHospitalId.value);
const canRegister = computed(() => {
  return inputRows.value.some(row => row.product_id && row.prescription_qty);
});

const currentCell = ref({ row: 0, col: 'product_name' });

// 상수
const prescriptionTypeOptions = [
  'EDI',
  '약국조제',
  '도매매출',
  '직거래매출',
  '차감',
  '원내매출',
  '원외매출',
];

const products = ref([]); // 전체 제품 목록
const productSearchForRow = ref({
  query: '',
  results: [],
  selectedIndex: -1,
  show: false,
  activeRowIndex: -1,
});

// 유틸리티 함수들
function getPrescriptionMonth(settlementMonth, offset) {
  if (!settlementMonth) return '';
  const [y, m] = settlementMonth.split('-');
  let mm = parseInt(m, 10) - offset;
  let yy = parseInt(y, 10);
  while (mm <= 0) { mm += 12; yy -= 1; }
  return `${yy}-${String(mm).padStart(2, '0')}`;
}

function updatePrescriptionOptions() {
  if (!activeMonth.value) {
    prescriptionOptions.value = [];
    return;
  }
  prescriptionOptions.value = [1, 2, 3].map(offset => ({
    value: offset,
    month: getPrescriptionMonth(activeMonth.value.settlement_month, offset)
  }));
}

// 워치어
watch([activeMonth], () => {
  updatePrescriptionOptions();
  prescriptionOffset.value = 1;
  prescriptionMonth.value = getPrescriptionMonth(activeMonth.value?.settlement_month, 1);
});

watch(prescriptionOffset, (val) => {
  prescriptionMonth.value = getPrescriptionMonth(activeMonth.value?.settlement_month, val);
});

// 병원 관련 함수들
function openHospitalModal() {
  if (!activeMonth.value) return;
  hospitalModalVisible.value = true;
}

function onHospitalRowSelect(e) {
  const hospital = e.data;
  selectedHospitalName.value = hospital.name;
  selectedHospitalInfo.value = hospital;
  selectedHospitalId.value = hospital.id;
  hospitalModalVisible.value = false;
}

const filteredHospitals = computed(() => {
  if (!hospitalSearch.value) return hospitals.value;
  const search = hospitalSearch.value.toLowerCase();
  return hospitals.value.filter(h =>
    (h.name && h.name.toLowerCase().includes(search)) ||
    (h.business_registration_number && h.business_registration_number.includes(search)) ||
    (h.owner_name && h.owner_name.toLowerCase().includes(search)) ||
    (h.address && h.address.toLowerCase().includes(search))
  );
});

// 데이터 fetch 함수들
async function fetchHospitals() {
  const { data: { session } } = await supabase.auth.getSession();
  const userUid = session?.user?.id;
  if (!userUid) return;
  
  const { data: myCompany } = await supabase.from('companies').select('id').eq('user_id', userUid).single();
  if (!myCompany) return;
  
  const { data: assignments } = await supabase.from('client_company_assignments').select('client_id').eq('company_id', myCompany.id);
  if (!assignments || assignments.length === 0) {
    hospitals.value = [];
    return;
  }
  
  const clientIds = assignments.map(a => a.client_id);
  const { data } = await supabase.from('clients').select('*').in('id', clientIds).eq('status', 'active');
  if (data) hospitals.value = data;
}

async function fetchProducts() {
  const { data, error } = await supabase.from('products').select('id, product_name, insurance_code, price').eq('status', 'active');
  if (!error && data) {
    const uniqByInsurance = {};
    const noInsurance = [];
    data.forEach(p => {
      if (p.insurance_code) {
        if (!uniqByInsurance[p.insurance_code]) uniqByInsurance[p.insurance_code] = p;
      } else {
        noInsurance.push(p);
      }
    });
    products.value = [...Object.values(uniqByInsurance), ...noInsurance];
  }
}

// 🔥 중요: 누락되었던 fetchActiveMonth 함수
async function fetchActiveMonth() {
  const today = new Date();
  const todayStr = today.toISOString().slice(0, 10);
  console.log('🔍 Debug - 오늘 날짜:', todayStr);
  
  try {
    // 1단계: 모든 active 상태인 settlement_months 조회
    const { data: allActive, error: queryError } = await supabase
      .from('settlement_months')
      .select('*')
      .eq('status', 'active');
      
    console.log('🔍 Debug - 모든 활성 월:', allActive);
    
    if (queryError) {
      console.error('❌ 쿼리 오류:', queryError);
      activeMonth.value = null;
      return;
    }
    
    // 2단계: JavaScript에서 날짜 범위 필터링
    const validMonths = allActive?.filter(month => {
      const startDate = new Date(month.start_date);
      const endDate = new Date(month.end_date);
      const todayDate = new Date(todayStr);
      
      console.log(`🔍 검사 중: ${month.settlement_month}`, {
        start: month.start_date,
        end: month.end_date,
        today: todayStr,
        startDate,
        endDate,
        todayDate,
        isValid: todayDate >= startDate && todayDate <= endDate
      });
      
      return todayDate >= startDate && todayDate <= endDate;
    }) || [];
    
    console.log('🔍 유효한 월:', validMonths);
    
    if (validMonths.length > 0) {
      // 가장 최근 settlement_month 선택
      const activeData = validMonths.sort((a, b) => b.settlement_month.localeCompare(a.settlement_month))[0];
      activeMonth.value = activeData;
      prescriptionOffset.value = 1;
      prescriptionMonth.value = getPrescriptionMonth(activeData.settlement_month, 1);
      console.log('✅ 활성 월 설정 완료:', activeData);
    } else {
      activeMonth.value = null;
      prescriptionMonth.value = '';
      prescriptionOffset.value = 1;
      console.log('❌ 오늘 날짜에 해당하는 활성 월이 없습니다');
    }
  } catch (err) {
    console.error('❌ fetchActiveMonth 오류:', err);
    activeMonth.value = null;
  }
}

// 제품 검색 관련 함수들
function handleProductNameInput(rowIndex, event) {
  if (!isInputEnabled.value) return;
  const query = event.target.value.toLowerCase();
  inputRows.value[rowIndex].product_name_display = event.target.value;
  inputRows.value[rowIndex].product_id = null;
  inputRows.value[rowIndex].insurance_code = '';
  inputRows.value[rowIndex].price = '';

  productSearchForRow.value.activeRowIndex = rowIndex;
  if (query.length < 1) {
    productSearchForRow.value.show = false;
    productSearchForRow.value.results = [];
    return;
  }
  productSearchForRow.value.results = products.value.filter(p =>
    (p.product_name && p.product_name.toLowerCase().includes(query)) ||
    (p.insurance_code && p.insurance_code.toLowerCase().includes(query))
  );
  productSearchForRow.value.selectedIndex = -1;
  productSearchForRow.value.show = productSearchForRow.value.results.length > 0;
}

function navigateProductSearchList(direction) {
  if (!productSearchForRow.value.show || productSearchForRow.value.results.length === 0) return;
  if (direction === 'down') {
    productSearchForRow.value.selectedIndex = (productSearchForRow.value.selectedIndex + 1) % productSearchForRow.value.results.length;
  } else if (direction === 'up') {
    productSearchForRow.value.selectedIndex = (productSearchForRow.value.selectedIndex - 1 + productSearchForRow.value.results.length) % productSearchForRow.value.results.length;
  }
}

function applySelectedProduct(product, rowIndex) {
  inputRows.value[rowIndex].product_name_display = product.product_name;
  inputRows.value[rowIndex].product_id = product.id;
  inputRows.value[rowIndex].insurance_code = product.insurance_code;
  inputRows.value[rowIndex].price = product.price;
  productSearchForRow.value.show = false;
  productSearchForRow.value.activeRowIndex = -1;
  nextTick(() => {
    focusField(rowIndex, 'prescription_qty');
  });
}

function applySelectedProductFromSearch(rowIndexToApply) {
  const idx = productSearchForRow.value.selectedIndex;
  const currentActionRow = productSearchForRow.value.activeRowIndex;
  if (productSearchForRow.value.show && idx !== -1 && productSearchForRow.value.results[idx] && currentActionRow === rowIndexToApply) {
    const product = productSearchForRow.value.results[idx];
    applySelectedProduct(product, currentActionRow);
  } else if (productSearchForRow.value.show && productSearchForRow.value.results.length > 0 && currentActionRow === rowIndexToApply) {
    const product = productSearchForRow.value.results[0];
    applySelectedProduct(product, currentActionRow);
  } else {
    focusField(rowIndexToApply, 'prescription_qty');
  }
  productSearchForRow.value.show = false;
}

function clickProductFromSearchList(product, rowIndex) {
  applySelectedProduct(product, rowIndex);
}

function hideProductSearchList(rowIndex) {
  if (productSearchForRow.value.activeRowIndex === rowIndex) {
    if (!inputRows.value[rowIndex].product_id) {
      inputRows.value[rowIndex].product_name_display = '';
    }
    productSearchForRow.value.show = false;
  }
}

function openProductModalForAdd() {
  // 제품 선택 모달 열기 (향후 구현)
  console.log('제품 선택 모달 열기');
}

// 테이블 네비게이션 함수들
function focusField(rowIdx, col) {
  nextTick(() => {
    const table = document.querySelector('.input-table');
    if (!table) return;
    const row = table.querySelectorAll('tbody tr')[rowIdx];
    if (!row) return;
    let el = null;
    if (col === 'product_name') el = row.querySelector('td:nth-child(2) input');
    else if (col === 'prescription_qty') el = row.querySelector('td:nth-child(5) input');
    else if (col === 'prescription_type') el = row.querySelector('td:nth-child(7) select');
    else if (col === 'remarks') el = row.querySelector('td:nth-child(8) input');
    if (el) el.focus();
  });
}

function addOrFocusNextRow(rowIdx) {
  const currentRow = inputRows.value[rowIdx];
  
  // 현재 행의 제품명 입력 중일 때
  if (currentCell.value.col === 'product_name') {
    // 제품이 선택되어 있지 않으면 다음으로 진행하지 않음
    if (!currentRow.product_id) {
      return;
    }
    // 제품이 선택되어 있으면 수량 입력으로 이동
    focusField(rowIdx, 'prescription_qty');
    return;
  }
  
  // 현재 행의 수량 입력 중일 때
  if (currentCell.value.col === 'prescription_qty') {
    // 수량이 입력되어 있지 않으면 다음으로 진행하지 않음
    if (!currentRow.prescription_qty) {
      return;
    }
    
    // 마지막 행이면 새 행 추가
    if (rowIdx === inputRows.value.length - 1) {
      inputRows.value.push({ 
        product_name_display: '', 
        product_id: null, 
        insurance_code: '', 
        price: '', 
        prescription_qty: '', 
        prescription_amount: '', 
        prescription_type: 'EDI',
        remarks: '' 
      });
    }
    // 다음 행의 제품명으로 이동
    focusField(rowIdx + 1, 'product_name');
  }
}

function onPrescriptionTypeInput(rowIdx) {
  const value = inputRows.value[rowIdx].prescription_type;
  for (let i = rowIdx + 1; i < inputRows.value.length; i++) {
    inputRows.value[i].prescription_type = value;
  }
}

function onQtyInput(rowIdx) {
  const qty = Number(inputRows.value[rowIdx].prescription_qty);
  const price = Number(inputRows.value[rowIdx].price);
  if (!isNaN(qty) && !isNaN(price) && price > 0) {
    inputRows.value[rowIdx].prescription_amount = (qty * price).toLocaleString();
  } else {
    inputRows.value[rowIdx].prescription_amount = '';
  }
}

function onArrowKey(e, rowIdx, col) {
  if (productSearchForRow.value.show && productSearchForRow.value.activeRowIndex === rowIdx && (e.key === "ArrowUp" || e.key === "ArrowDown")) {
    return;
  }
  if (!["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"].includes(e.key)) return;
  e.preventDefault();
  const cols = ["product_name", "prescription_qty", "prescription_type", "remarks"];
  let currentColIdx = cols.indexOf(col);
  let newRow = rowIdx;
  let newColIdx = currentColIdx;

  if (e.key === "ArrowUp") newRow = Math.max(0, rowIdx - 1);
  if (e.key === "ArrowDown") newRow = Math.min(inputRows.value.length - 1, rowIdx + 1);
  if (e.key === "ArrowLeft") newColIdx = Math.max(0, currentColIdx - 1);
  if (e.key === "ArrowRight") newColIdx = Math.min(cols.length - 1, currentColIdx + 1);

  if (e.key === "ArrowLeft" && currentColIdx === 0) newColIdx = 0;
  if (e.key === "ArrowRight" && currentColIdx === cols.length - 1) newColIdx = cols.length - 1;
  
  currentCell.value = { row: newRow, col: cols[newColIdx] };
  focusField(newRow, cols[newColIdx]);
}

function cellClass(rowIdx, col) {
  return currentCell.value.row === rowIdx && currentCell.value.col === col ? 'cell-focused' : '';
}

// 등록 함수
function onRegister() {
  console.log('등록 버튼 클릭 - 추후 구현');
  console.log('입력된 데이터:', {
    activeMonth: activeMonth.value,
    selectedHospital: selectedHospitalInfo.value,
    prescriptionMonth: prescriptionMonth.value,
    inputRows: inputRows.value.filter(row => row.product_id)
  });
}

// 합계 계산
const totalQty = computed(() => {
  return inputRows.value.reduce((sum, row) => sum + (Number(row.prescription_qty) || 0), 0);
});
const totalAmount = computed(() => {
  return inputRows.value.reduce((sum, row) => sum + (Number(row.prescription_amount.toString().replace(/,/g, '')) || 0), 0).toLocaleString();
});

// 행 추가/삭제
function addRowBelow(idx) {
  inputRows.value.splice(idx + 1, 0, {
    product_name_display: '', product_id: null, insurance_code: '', price: '', prescription_qty: '', prescription_amount: '', prescription_type: 'EDI', remarks: ''
  });
  nextTick(() => focusField(idx + 1, 'product_name'));
}
function deleteRow(idx) {
  if (inputRows.value.length === 1) return;
  inputRows.value.splice(idx, 1);
}

// 라이프사이클
onMounted(() => {
  fetchActiveMonth();
  fetchHospitals();
  fetchProducts();
});
</script>

<style scoped>
.btn-primary:disabled {
  background: #e0e0e0 !important;
  color: #b0b0b0 !important;
  border: 1px solid #d0d0d0 !important;
  cursor: not-allowed !important;
  opacity: 0.7;
}

.btn-product-select {
  background: #1976d2;
  color: #fff;
  border: 1px solid #1976d2;
  border-radius: 4px;
  padding: 0 12px;
  height: 32px;
  font-size: 1rem;
  cursor: pointer;
}

.btn-product-select:disabled {
  background: #e0e0e0 !important;
  color: #b0b0b0 !important;
  border: 1px solid #d0d0d0 !important;
  cursor: not-allowed !important;
  opacity: 0.7;
}

.input-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 8px;
}

.input-table th, .input-table td {
  border: 1px solid #ddd;
  padding: 0;
  text-align: center;
  height: 36px;
}

.input-table input, .input-table select {
  width: 100%;
  height: 34px;
  border: none;
  padding: 0 8px;
  font-size: 1rem;
  background: #fff;
  text-align: center;
}

.input-table input[readonly] {
  background: #f5f5f5;
  color: #555;
  cursor: default;
}

.cell-focused {
  background: #fffbe0 !important;
  outline: 2px solid #ffd600;
  z-index: 2;
}

.product-search-dropdown {
  position: absolute;
  background-color: white;
  border: 1px solid #ccc;
  border-top: none;
  max-height: 200px;
  overflow-y: auto;
  width: calc(100% - 2px);
  left: 0;
  z-index: 1000;
  box-shadow: 0 4px 8px rgba(0,0,0,0.1);
}

.product-search-dropdown ul {
  list-style: none;
  margin: 0;
  padding: 0;
}

.product-search-dropdown li {
  padding: 8px 12px;
  cursor: pointer;
  border-bottom: 1px solid #eee;
}

.product-search-dropdown li:last-child {
  border-bottom: none;
}

.product-search-dropdown li:hover {
  background-color: #f0f0f0;
}

.product-search-dropdown li.selected {
  background-color: #1976d2;
  color: white;
}

/* 드래그 관련 스타일 주석 처리
.drag-cell {
  cursor: grab;
  text-align: center;
  background: #f5f5f5;
}
.drag-handle {
  font-size: 1.3em;
  cursor: grab;
  user-select: none;
}
*/
.action-cell {
  text-align: center;
  background: #f5f5f5;
}
.btn-row {
  background: #fff;
  border: 1px solid #bbb;
  border-radius: 4px;
  font-size: 1.1em;
  width: 28px;
  height: 28px;
  margin: 0 2px;
  cursor: pointer;
  transition: background 0.2s;
}
.btn-row:disabled {
  background: #eee;
  color: #bbb;
  cursor: not-allowed;
}
</style>