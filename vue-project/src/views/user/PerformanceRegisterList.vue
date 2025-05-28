<template>
  <div class="performance-register-view">
    <div class="header-title">등록 현황</div>
    <div class="table-container" style="position:relative;">
      <div class="performance-header-row">
        <!-- 정산월 선택 드롭다운 -->
        <div class="info-box info-box-settlement">
          <span class="info-box-label">정산월</span>
          <select v-model="selectedSettlementMonth" class="prescription-select" @change="onSettlementMonthChange">
            <option value="">- 선택하세요 -</option>
            <option v-for="month in availableMonths" :key="month.settlement_month" :value="month.settlement_month">
              {{ month.settlement_month }}
            </option>
          </select>
        </div>
        <div class="info-box info-box-period">
          <span class="info-box-label">제출기간</span>
          <span class="info-box-content">{{ selectedMonthInfo ? (selectedMonthInfo.start_date + ' ~ ' + selectedMonthInfo.end_date) : '' }}</span>
        </div>
        <!-- 처방월 표시 -->
        <div class="info-box info-box-prescription">
          <span class="info-box-label">처방월</span>
          <select v-model="prescriptionOffset" class="prescription-select" @change="onPrescriptionOffsetChange">
            <option v-for="opt in prescriptionOptions" :key="opt.value" :value="opt.value">
              {{ opt.month }}
            </option>
          </select>
        </div>
      </div>
      
      <div class="performance-action-row">
        <div class="hospital-selection-container">
          <div class="hospital-input-box">
            <span class="info-box-label">병원 선택</span>
            <select 
              v-model="selectedHospitalId" 
              class="hospital-input"
              @change="onHospitalChange"
              :class="currentCell.row === -1 && currentCell.col === 'hospital' ? 'hospital-input-focused' : ''"
            >
              <option value="">- 전체 -</option>
              <option v-for="hospital in hospitals" :key="hospital.id" :value="hospital.id">
                {{ hospital.name }}
              </option>
            </select>
          </div>
          <span v-if="selectedHospitalInfo" class="hospital-info">
            ({{ selectedHospitalInfo.business_registration_number }}, {{ selectedHospitalInfo.owner_name }}, {{ selectedHospitalInfo.address }})
          </span>
        </div>
        <button 
          class="btn-primary register-button" 
          @click="onSave" 
          :disabled="!canSave" 
          :class="{ 'disabled-area': !isEditMode }"
        >{{ isEditMode ? '저장' : '등록' }}</button>
      </div>
      
      <table class="input-table" :class="{ 'disabled-area': !isEditMode }">
        <thead>
          <tr>
            <th style="width:40px;">No</th>
            <th style="width:20%;">제품명</th>
            <th style="width:8%;">보험코드</th>
            <th style="width:8%;">약가</th>
            <th style="width:8%;">처방수량</th>
            <th style="width:10%;">처방액</th>
            <th style="width:10%;">처방구분</th>
            <th style="width:14%;">비고</th>
            <th style="width:40px;">삭제</th>
            <th style="width:40px;">추가</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(row, rowIdx) in displayRows" :key="rowIdx">
            <td style="text-align:center;">{{ rowIdx + 1 }}</td>
            <td style="position:relative;text-align:left;">
              <input
                v-model="row.product_name_display"
                :tabindex="isEditMode ? 0 : -1"
                :readonly="!isEditMode"
                @input="handleProductNameInput(rowIdx, $event)"
                @keydown.enter.prevent="applySelectedProductFromSearch(rowIdx)"
                @keydown.down.prevent="navigateProductSearchList('down')"
                @keydown.up.prevent="navigateProductSearchList('up')"
                @keydown="onArrowKey($event, rowIdx, 'product_name')"
                @focus="handleProductNameFocus(rowIdx)"
                @blur="setTimeout(() => hideProductSearchList(rowIdx), 200)" 
                :disabled="!isEditMode"
                :class="[
                  cellClass(rowIdx, 'product_name'),
                  { 'disabled-area': !isEditMode }
                ]"
                autocomplete="off"
                style="text-align:left;"
              />
              <div v-if="productSearchForRow.show && productSearchForRow.activeRowIndex === rowIdx && productSearchForRow.results.length > 0" class="product-search-dropdown">
                <ul>
                  <li
                    v-for="(product, index) in productSearchForRow.results"
                    :key="product.id"
                    @click="clickProductFromSearchList(product, rowIdx)"
                    :class="{ 'selected': productSearchForRow.selectedIndex === index }"
                  >
                    <span class="product-name">{{ truncateText(product.product_name, 25) }}</span>
                    <span class="insurance-code">{{ product.insurance_code }}</span>
                  </li>
                </ul>
              </div>
            </td>
            <td style="text-align:center;">
              <input 
                v-model="row.insurance_code" 
                readonly 
                tabindex="-1" 
                class="disabled-area"
                style="text-align:center;"
              />
            </td>
            <td style="text-align:right;">
              <input 
                v-model="row.price" 
                readonly 
                tabindex="-1" 
                class="disabled-area"
                style="text-align:right;"
              />
            </td>
            <td style="text-align:right;">
              <input
                v-model="row.prescription_qty"
                :tabindex="isEditMode ? 0 : -1"
                :readonly="!isEditMode"
                @keydown.enter.prevent="addOrFocusNextRow(rowIdx)"
                @keydown="onArrowKey($event, rowIdx, 'prescription_qty')"
                @input="onQtyInput(rowIdx)"
                @focus="handleFieldFocus(rowIdx, 'prescription_qty')"
                :disabled="!isEditMode"
                :class="[
                  cellClass(rowIdx, 'prescription_qty'),
                  { 'disabled-area': !isEditMode }
                ]"
                style="text-align:right;"
              />
            </td>
            <td style="text-align:right;">
              <input 
                v-model="row.prescription_amount" 
                readonly 
                tabindex="-1" 
                class="disabled-area"
                style="text-align:right;"
              />
            </td>
            <td style="text-align:center;">
              <select
                v-model="row.prescription_type"
                :tabindex="isEditMode ? 0 : -1"
                :readonly="!isEditMode"
                @change="onPrescriptionTypeInput(rowIdx)"
                @keydown="onPrescriptionTypeKeydown($event, rowIdx)"
                @focus="handleFieldFocus(rowIdx, 'prescription_type')"
                :disabled="!isEditMode"
                :class="[
                  cellClass(rowIdx, 'prescription_type'),
                  { 'disabled-area': !isEditMode }
                ]"
                style="text-align:center;"
              >
                <option v-for="type in prescriptionTypeOptions" :key="type" :value="type">{{ type }}</option>
              </select>
            </td>
            <td style="text-align:left;">
              <input
                v-model="row.remarks"
                :tabindex="isEditMode ? 0 : -1"
                :readonly="!isEditMode"
                @keydown.enter.prevent="addOrFocusNextRow(rowIdx)"
                @keydown="onArrowKey($event, rowIdx, 'remarks')"
                @focus="handleFieldFocus(rowIdx, 'remarks')"
                :disabled="!isEditMode"
                :class="[
                  cellClass(rowIdx, 'remarks'),
                  { 'disabled-area': !isEditMode }
                ]"
                style="text-align:left;"
              />
            </td>
            <td class="action-cell">
              <button 
                class="btn-delete-m" 
                @click="confirmDeleteRow(rowIdx)" 
                :disabled="displayRows.length === 1 || !isEditMode" 
                title="행 삭제"
                :class="{ 'disabled-area': !isEditMode }"
              >－</button>
            </td>
            <td class="action-cell">
              <button 
                class="btn-add-m" 
                @click="confirmAddRowBelow(rowIdx)" 
                title="아래에 행 추가"
                :disabled="!isEditMode"
                :class="{ 'disabled-area': !isEditMode }"
              >＋</button>
            </td>
          </tr>
        </tbody>
        <tfoot>
          <tr>
            <td colspan="4" style="text-align:right;font-weight:bold;">합계</td>
            <td style="text-align:right;font-weight:bold;">{{ totalQty }}</td>
            <td style="text-align:right;font-weight:bold;">{{ totalAmount }}</td>
            <td colspan="4"></td>
          </tr>
        </tfoot>
      </table>
      
      <div v-if="!selectedSettlementMonth" style="position:absolute;top:0;left:0;width:100%;height:100%;display:flex;align-items:center;justify-content:center;z-index:10;background:rgba(255,255,255,0.85);">
        <div style="font-size:1.3rem;color:#666;text-align:center;">정산월을 선택하세요.</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, nextTick, onUnmounted } from 'vue';
import { onBeforeRouteLeave } from 'vue-router';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Dialog from 'primevue/dialog';
import InputText from 'primevue/inputtext';
import { supabase } from '@/supabase';

// 반응형 데이터
const availableMonths = ref([]); // 선택 가능한 정산월 목록
const selectedSettlementMonth = ref(''); // 선택된 정산월
const selectedMonthInfo = ref(null); // 선택된 정산월 정보
const prescriptionMonth = ref('');
const prescriptionOffset = ref(1); // 1: -1M, 2: -2M, 3: -3M
const prescriptionOptions = ref([]);
const selectedHospitalName = ref('');
const selectedHospitalInfo = ref(null);
const selectedHospitalId = ref(''); // 빈 문자열로 초기화 (전체)
const hospitals = ref([]);

// 실적 데이터
const performanceRecords = ref([]); // DB에서 가져온 실적 데이터
const displayRows = ref([]); // 화면에 표시할 행들
const originalData = ref([]); // 원본 데이터 (변경 감지용)
const hasChanges = ref(false); // 변경사항 여부

// 편집 모드 관련
const isEditMode = ref(false); // 편집 가능 여부
const userType = ref(''); // 사용자 타입
const currentUserCompanyId = ref(''); // 현재 사용자의 회사 ID

// 계산된 속성
const canSave = computed(() => {
  return isEditMode.value && hasChanges.value && displayRows.value.some(row => row.product_id && row.prescription_qty);
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

// 제품 검색 드롭다운이 열려있는지 확인하는 computed
const isProductSearchOpen = computed(() => {
  return productSearchForRow.value.show && productSearchForRow.value.activeRowIndex !== -1;
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

function truncateText(text, maxLength) {
  if (!text) return '';
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength) + '...';
}

function updatePrescriptionOptions() {
  if (!selectedMonthInfo.value) {
    prescriptionOptions.value = [];
    return;
  }
  prescriptionOptions.value = [1, 2, 3].map(offset => ({
    value: offset,
    month: getPrescriptionMonth(selectedMonthInfo.value.settlement_month, offset)
  }));
}

// 편집 모드 확인 함수
function checkEditMode() {
  if (!selectedMonthInfo.value) {
    isEditMode.value = false;
    return;
  }
  
  const today = new Date();
  const todayStr = today.toISOString().slice(0, 10);
  const startDate = new Date(selectedMonthInfo.value.start_date);
  const endDate = new Date(selectedMonthInfo.value.end_date);
  const todayDate = new Date(todayStr);
  
  // 오늘이 제출기간 내에 있는지 확인
  isEditMode.value = todayDate >= startDate && todayDate <= endDate;
}

// 워치어
watch(selectedSettlementMonth, () => {
  const monthInfo = availableMonths.value.find(m => m.settlement_month === selectedSettlementMonth.value);
  selectedMonthInfo.value = monthInfo || null;
  updatePrescriptionOptions();
  prescriptionOffset.value = 1;
  prescriptionMonth.value = getPrescriptionMonth(selectedSettlementMonth.value, 1);
  checkEditMode();
  
  if (selectedSettlementMonth.value) {
    fetchPerformanceRecords();
  } else {
    displayRows.value = [];
    performanceRecords.value = [];
  }
});

watch(prescriptionOffset, (val) => {
  prescriptionMonth.value = getPrescriptionMonth(selectedSettlementMonth.value, val);
  if (selectedSettlementMonth.value) {
    fetchPerformanceRecords();
  }
});

watch(selectedHospitalId, () => {
  if (selectedSettlementMonth.value) {
    fetchPerformanceRecords();
  }
});

// 변경사항 감지
watch(displayRows, () => {
  checkForChanges();
}, { deep: true });

function checkForChanges() {
  if (!originalData.value.length && !displayRows.value.length) {
    hasChanges.value = false;
    return;
  }
  
  // 간단한 변경 감지 (실제로는 더 정교한 비교가 필요할 수 있음)
  const currentDataStr = JSON.stringify(displayRows.value.map(row => ({
    product_id: row.product_id,
    prescription_qty: row.prescription_qty,
    prescription_type: row.prescription_type,
    remarks: row.remarks
  })));
  
  const originalDataStr = JSON.stringify(originalData.value.map(row => ({
    product_id: row.product_id,
    prescription_qty: row.prescription_qty,
    prescription_type: row.prescription_type,
    remarks: row.remarks
  })));
  
  hasChanges.value = currentDataStr !== originalDataStr;
}

// 병원 관련 함수들은 제거됨 (모달 방식에서 드롭다운으로 변경)

// 데이터 fetch 함수들
async function fetchHospitals() {
  try {
    if (userType.value === 'admin') {
      // 관리자는 모든 병원 조회
      const { data } = await supabase.from('clients').select('*').eq('status', 'active');
      hospitals.value = data || [];
    } else {
      // 일반 사용자는 할당된 병원만 조회
      if (!currentUserCompanyId.value) return;
      
      const { data: assignments } = await supabase
        .from('client_company_assignments')
        .select('client_id')
        .eq('company_id', currentUserCompanyId.value);
        
      if (!assignments || assignments.length === 0) {
        hospitals.value = [];
        return;
      }
      
      const clientIds = assignments.map(a => a.client_id);
      const { data } = await supabase
        .from('clients')
        .select('*')
        .in('id', clientIds)
        .eq('status', 'active');
        
      hospitals.value = data || [];
    }
  } catch (err) {
    console.error('병원 조회 오류:', err);
  }
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

// 제품 검색 관련 함수들
function handleProductNameInput(rowIndex, event) {
  if (!isEditMode.value) return;
  const query = event.target.value.toLowerCase();
  displayRows.value[rowIndex].product_name_display = event.target.value;
  displayRows.value[rowIndex].product_id = null;
  displayRows.value[rowIndex].insurance_code = '';
  displayRows.value[rowIndex].price = '';

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
  displayRows.value[rowIndex].product_name_display = product.product_name;
  displayRows.value[rowIndex].product_id = product.id;
  displayRows.value[rowIndex].insurance_code = product.insurance_code;
  displayRows.value[rowIndex].price = product.price;
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
    if (!displayRows.value[rowIndex].product_id) {
      displayRows.value[rowIndex].product_name_display = '';
    }
    productSearchForRow.value.show = false;
    productSearchForRow.value.activeRowIndex = -1;
  }
}

// 제품명 필드 포커스 핸들러
function handleProductNameFocus(rowIdx) {
  if (!isInputEnabled.value) {
    event.target.blur();
    return;
  }
  
  // 다른 행의 제품 검색이 열려있으면 차단
  if (isProductSearchOpen.value && productSearchForRow.value.activeRowIndex !== rowIdx) {
    event.target.blur();
    return;
  }
  
  currentCell.value = { row: rowIdx, col: 'product_name' };
  productSearchForRow.value.activeRowIndex = rowIdx;
}

// 일반 필드 포커스 핸들러
function handleFieldFocus(rowIdx, col) {
  if (!isInputEnabled.value) {
    event.target.blur();
    return;
  }
  
  // 제품 검색 드롭다운이 열려있으면 포커스 차단
  if (isProductSearchOpen.value) {
    event.target.blur();
    return;
  }
  
  currentCell.value = { row: rowIdx, col: col };
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
  const currentRow = displayRows.value[rowIdx];
  
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
    // 제품명과 수량이 모두 입력되어 있어야 새 행 생성
    if (!currentRow.product_id || !currentRow.prescription_qty) {
      return;
    }
    
    // 마지막 행이면 새 행 추가
    if (rowIdx === displayRows.value.length - 1) {
      displayRows.value.push({ 
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
  
  // 비고 입력 중일 때
  if (currentCell.value.col === 'remarks') {
    // 제품명과 수량이 모두 입력되어 있어야 새 행 생성
    if (!currentRow.product_id || !currentRow.prescription_qty) {
      return;
    }
    
    // 마지막 행이면 새 행 추가
    if (rowIdx === displayRows.value.length - 1) {
      displayRows.value.push({ 
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
  const value = displayRows.value[rowIdx].prescription_type;
  for (let i = rowIdx + 1; i < displayRows.value.length; i++) {
    displayRows.value[i].prescription_type = value;
  }
}

function onPrescriptionTypeKeydown(e, rowIdx) {
  if (!["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"].includes(e.key)) return;
  e.preventDefault();
  const cols = ["product_name", "prescription_qty", "prescription_type", "remarks"];
  let currentColIdx = cols.indexOf(currentCell.value.col);
  let newRow = currentCell.value.row;
  let newColIdx = currentColIdx;

  if (e.key === "ArrowUp") newRow = Math.max(0, currentCell.value.row - 1);
  if (e.key === "ArrowDown") {
    // 아래 화살표: 제품명과 수량이 모두 입력된 상태에서 마지막 행이면 새 행 생성
    const currentRow = displayRows.value[currentCell.value.row];
    if (currentRow.product_id && currentRow.prescription_qty && currentCell.value.row === displayRows.value.length - 1) {
      displayRows.value.push({ 
        product_name_display: '', 
        product_id: null, 
        insurance_code: '', 
        price: '', 
        prescription_qty: '', 
        prescription_amount: '', 
        prescription_type: 'EDI',
        remarks: '' 
      });
      newRow = currentCell.value.row + 1;
      newColIdx = 0; // 제품명으로 이동
    } else {
      newRow = Math.min(displayRows.value.length - 1, currentCell.value.row + 1);
    }
  }
  if (e.key === "ArrowLeft") newColIdx = Math.max(0, currentColIdx - 1);
  if (e.key === "ArrowRight") newColIdx = Math.min(cols.length - 1, currentColIdx + 1);

  if (e.key === "ArrowLeft" && currentColIdx === 0) newColIdx = 0;
  if (e.key === "ArrowRight" && currentColIdx === cols.length - 1) newColIdx = cols.length - 1;
  
  currentCell.value = { row: newRow, col: cols[newColIdx] };
  focusField(newRow, cols[newColIdx]);
}

function onQtyInput(rowIdx) {
  const qty = Number(displayRows.value[rowIdx].prescription_qty);
  const price = Number(displayRows.value[rowIdx].price);
  if (!isNaN(qty) && !isNaN(price) && price > 0) {
    displayRows.value[rowIdx].prescription_amount = (qty * price).toLocaleString();
  } else {
    displayRows.value[rowIdx].prescription_amount = '';
  }
}

function onArrowKey(e, rowIdx, col) {
  // 제품 검색 드롭다운이 열려있을 때는 위/아래 화살표만 허용
  if (isProductSearchOpen.value && productSearchForRow.value.activeRowIndex === rowIdx) {
    if (e.key === "ArrowUp" || e.key === "ArrowDown") {
      return; // 제품 검색 리스트 네비게이션은 별도 함수에서 처리
    } else if (e.key === "ArrowLeft" || e.key === "ArrowRight") {
      e.preventDefault();
      return; // 좌우 화살표 차단
    }
    return;
  }
  
  if (!["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"].includes(e.key)) return;
  e.preventDefault();
  const cols = ["product_name", "prescription_qty", "prescription_type", "remarks"];
  let currentColIdx = cols.indexOf(col);
  let newRow = rowIdx;
  let newColIdx = currentColIdx;

  if (e.key === "ArrowUp") newRow = Math.max(0, rowIdx - 1);
  if (e.key === "ArrowDown") {
    // 아래 화살표: 제품명과 수량이 모두 입력된 상태에서 마지막 행이면 새 행 생성
    const currentRow = displayRows.value[rowIdx];
    if (currentRow.product_id && currentRow.prescription_qty && rowIdx === displayRows.value.length - 1) {
      displayRows.value.push({ 
        product_name_display: '', 
        product_id: null, 
        insurance_code: '', 
        price: '', 
        prescription_qty: '', 
        prescription_amount: '', 
        prescription_type: 'EDI',
        remarks: '' 
      });
      newRow = rowIdx + 1;
      newColIdx = 0; // 제품명으로 이동
    } else {
      newRow = Math.min(displayRows.value.length - 1, rowIdx + 1);
    }
  }
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

// 페이지 이탈 시 확인
onBeforeRouteLeave(async (to, from, next) => {
  // 편집 모드에서 변경사항이 있으면 확인
  if (isEditMode.value && hasChanges.value) {
    const shouldLeave = confirm('저장하지 않은 변경사항이 있습니다. 페이지를 떠나시겠습니까?');
    
    if (shouldLeave) {
      next(); // 확인 시 이동
    } else {
      next(false); // 취소 시 이동 취소
    }
  } else {
    next(); // 변경사항이 없으면 바로 이동
  }
});

// 합계 계산
const totalQty = computed(() => {
  return displayRows.value.reduce((sum, row) => sum + (Number(row.prescription_qty) || 0), 0);
});
const totalAmount = computed(() => {
  return displayRows.value.reduce((sum, row) => sum + (Number(row.prescription_amount.toString().replace(/,/g, '')) || 0), 0).toLocaleString();
});

// 행 추가/삭제
function addRowBelow(idx) {
  displayRows.value.splice(idx + 1, 0, {
    product_name_display: '', product_id: null, insurance_code: '', price: '', prescription_qty: '', prescription_amount: '', prescription_type: 'EDI', remarks: ''
  });
  nextTick(() => focusField(idx + 1, 'product_name'));
}
function deleteRow(idx) {
  if (displayRows.value.length === 1) return;
  displayRows.value.splice(idx, 1);
}

// 확인 다이얼로그 함수들을 브라우저 confirm으로 변경
function confirmDeleteRow(idx) {
  // 제품 검색 드롭다운이 열려있으면 차단
  if (isProductSearchOpen.value) {
    return;
  }
  
  if (confirm('선택된 행을 삭제하시겠습니까?')) {
    deleteRow(idx);
  }
}

function confirmAddRowBelow(idx) {
  // 제품 검색 드롭다운이 열려있으면 차단
  if (isProductSearchOpen.value) {
    return;
  }
  
  if (confirm('아래에 새 행을 추가하시겠습니까?')) {
    addRowBelow(idx);
  }
}

// 단축키 처리
function handleGlobalKeydown(e) {
  // 제품 검색 드롭다운이 열려있으면 Insert/Delete 키 차단
  if (isProductSearchOpen.value) {
    if (e.key === 'Delete' || e.key === 'Insert') {
      e.preventDefault();
      return;
    }
  }
  
  if (e.key === 'Delete') {
    e.preventDefault();
    const currentRowIdx = currentCell.value.row;
    if (displayRows.value.length > 1) {
      confirmDeleteRow(currentRowIdx);
    }
  } else if (e.key === 'Insert') {
    e.preventDefault();
    const currentRowIdx = currentCell.value.row;
    confirmAddRowBelow(currentRowIdx);
  }
}

// 기본 정산월 설정 함수
async function setDefaultSettlementMonth() {
  if (availableMonths.value.length === 0) return;
  
  try {
    // 현재 사용자가 제출한 실적 중 가장 최근 정산월 조회
    let query = supabase
      .from('performance_records')
      .select('settlement_month')
      .order('settlement_month', { ascending: false })
      .limit(1);
    
    // 사용자 타입에 따른 필터링
    if (userType.value === 'user' && currentUserCompanyId.value) {
      query = query.eq('company_id', currentUserCompanyId.value);
    }
    
    const { data, error } = await query;
    
    if (error) {
      console.error('최근 정산월 조회 오류:', error);
      // 오류 시 첫 번째 사용 가능한 월로 설정
      if (availableMonths.value.length > 0) {
        selectedSettlementMonth.value = availableMonths.value[0].settlement_month;
      }
      return;
    }
    
    if (data && data.length > 0) {
      // 제출한 실적이 있으면 가장 최근 정산월을 기본값으로 설정
      const lastSubmittedMonth = data[0].settlement_month;
      
      // 사용 가능한 정산월 중에서 해당 월이 있는지 확인
      const matchingMonth = availableMonths.value.find(month => month.settlement_month === lastSubmittedMonth);
      
      if (matchingMonth) {
        selectedSettlementMonth.value = lastSubmittedMonth;
      } else if (availableMonths.value.length > 0) {
        // 해당 월이 사용 가능한 목록에 없으면 가장 최근 월 선택
        selectedSettlementMonth.value = availableMonths.value[0].settlement_month;
      }
    } else {
      // 제출한 실적이 없으면 가장 최근 사용 가능한 월 선택
      if (availableMonths.value.length > 0) {
        selectedSettlementMonth.value = availableMonths.value[0].settlement_month;
      }
    }
  } catch (err) {
    console.error('기본 정산월 설정 오류:', err);
    // 오류 시 첫 번째 사용 가능한 월로 설정
    if (availableMonths.value.length > 0) {
      selectedSettlementMonth.value = availableMonths.value[0].settlement_month;
    }
  }
}

// 라이프사이클
onMounted(async () => {
  await fetchUserInfo();
  await fetchAvailableMonths();
  await fetchHospitals();
  await fetchProducts();
  
  // 기본 정산월 설정 (사용자 정보와 사용 가능한 월 로드 후)
  await setDefaultSettlementMonth();
  
  // 전역 키보드 이벤트 리스너 추가
  document.addEventListener('keydown', handleGlobalKeydown);
});

// 컴포넌트 언마운트 시 이벤트 리스너 제거
onUnmounted(() => {
  document.removeEventListener('keydown', handleGlobalKeydown);
});

// 이벤트 핸들러들
function onSettlementMonthChange() {
  // watch에서 처리됨
}

function onPrescriptionOffsetChange() {
  // watch에서 처리됨
}

function onHospitalChange() {
  const hospital = hospitals.value.find(h => h.id === selectedHospitalId.value);
  selectedHospitalInfo.value = hospital || null;
  selectedHospitalName.value = hospital ? hospital.name : '';
}

// 데이터 fetch 함수들
async function fetchAvailableMonths() {
  try {
    const { data, error } = await supabase
      .from('settlement_months')
      .select('*')
      .eq('status', 'active')
      .order('settlement_month', { ascending: false });
      
    if (error) {
      console.error('정산월 조회 오류:', error);
      return;
    }
    
    availableMonths.value = data || [];
  } catch (err) {
    console.error('정산월 조회 예외:', err);
  }
}

async function fetchUserInfo() {
  try {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session?.user) return;
    
    userType.value = session.user.user_metadata?.user_type || '';
    
    if (userType.value === 'user') {
      const { data: company } = await supabase
        .from('companies')
        .select('id')
        .eq('user_id', session.user.id)
        .single();
        
      currentUserCompanyId.value = company?.id || '';
    }
  } catch (err) {
    console.error('사용자 정보 조회 오류:', err);
  }
}

async function fetchPerformanceRecords() {
  if (!selectedSettlementMonth.value || !prescriptionMonth.value) {
    displayRows.value = [];
    performanceRecords.value = [];
    originalData.value = [];
    return;
  }
  
  try {
    let query = supabase
      .from('performance_records')
      .select(`
        *,
        products!inner(product_name, insurance_code, price),
        clients!inner(name, business_registration_number, owner_name, address)
      `)
      .eq('settlement_month', selectedSettlementMonth.value)
      .eq('prescription_month', prescriptionMonth.value);
    
    // 사용자 타입에 따른 필터링
    if (userType.value === 'user' && currentUserCompanyId.value) {
      query = query.eq('company_id', currentUserCompanyId.value);
    }
    
    // 병원 필터링
    if (selectedHospitalId.value) {
      query = query.eq('client_id', selectedHospitalId.value);
    }
    
    const { data, error } = await query.order('created_at', { ascending: true });
    
    if (error) {
      console.error('실적 조회 오류:', error);
      return;
    }
    
    performanceRecords.value = data || [];
    
    // 화면 표시용 데이터 변환
    const transformedData = performanceRecords.value.map(record => ({
      id: record.id,
      product_name_display: record.products.product_name,
      product_id: record.product_id,
      insurance_code: record.products.insurance_code,
      price: record.products.price,
      prescription_qty: record.prescription_qty,
      prescription_amount: (record.prescription_qty * record.products.price).toLocaleString(),
      prescription_type: record.prescription_type,
      remarks: record.remarks || ''
    }));
    
    // 편집 모드가 아니거나 데이터가 없으면 빈 행 추가하지 않음
    if (transformedData.length === 0 && isEditMode.value) {
      transformedData.push({
        id: null,
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
    
    displayRows.value = transformedData;
    originalData.value = JSON.parse(JSON.stringify(transformedData));
    hasChanges.value = false;
    
  } catch (err) {
    console.error('실적 조회 예외:', err);
  }
}

// 저장 함수
async function onSave() {
  if (!isEditMode.value || !hasChanges.value) return;
  
  try {
    // 기존 데이터 삭제 후 새로 저장하는 방식
    if (performanceRecords.value.length > 0) {
      const recordIds = performanceRecords.value.map(r => r.id);
      const { error: deleteError } = await supabase
        .from('performance_records')
        .delete()
        .in('id', recordIds);
        
      if (deleteError) {
        throw new Error('기존 데이터 삭제 실패');
      }
    }
    
    // 새 데이터 저장
    const validRows = displayRows.value.filter(row => row.product_id && row.prescription_qty);
    
    if (validRows.length > 0) {
      const { data: { session } } = await supabase.auth.getSession();
      const { data: company } = await supabase
        .from('companies')
        .select('id')
        .eq('user_id', session.user.id)
        .single();
      
      const saveData = validRows.map(row => ({
        company_id: company.id,
        settlement_month: selectedSettlementMonth.value,
        prescription_month: prescriptionMonth.value,
        client_id: selectedHospitalId.value,
        product_id: row.product_id,
        prescription_qty: parseInt(row.prescription_qty),
        prescription_type: row.prescription_type,
        remarks: row.remarks || null,
        registered_by: session.user.id
      }));
      
      const { error: insertError } = await supabase
        .from('performance_records')
        .insert(saveData);
        
      if (insertError) {
        throw new Error('데이터 저장 실패');
      }
    }
    
    alert('저장되었습니다.');
    await fetchPerformanceRecords(); // 데이터 다시 로드
    
  } catch (err) {
    console.error('저장 오류:', err);
    alert('저장 중 오류가 발생했습니다: ' + err.message);
  }
}
</script>

<style scoped>
/* 제품 검색 드롭다운 위치 조정 */
.product-search-container {
  position: relative;
}

/* 병원 선택 모달 */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  padding: 20px;
  border-radius: 8px;
  width: 80%;
  max-width: 800px;
  max-height: 80%;
  overflow-y: auto;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  border-bottom: 1px solid #ddd;
  padding-bottom: 10px;
}

.modal-title {
  font-size: 1.2rem;
  font-weight: bold;
}

.close-button {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #666;
}

.close-button:hover {
  color: #000;
}

.modal-body {
  margin-bottom: 20px;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  border-top: 1px solid #ddd;
  padding-top: 10px;
}

/* 병원 목록 테이블 */
.hospital-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 10px;
}

.hospital-table th,
.hospital-table td {
  border: 1px solid #ddd;
  padding: 8px;
  text-align: left;
}

.hospital-table th {
  background: #f5f5f5;
  font-weight: bold;
}

.hospital-table tbody tr {
  cursor: pointer;
}

.hospital-table tbody tr:hover {
  background: #f0f0f0;
}

.hospital-table tbody tr.selected {
  background: #e3f2fd;
}
</style> 