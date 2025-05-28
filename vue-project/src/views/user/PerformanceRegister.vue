<template>
  <div class="performance-register-view">
    <div class="header-title">실적 등록</div>
    <div class="table-container" style="position:relative;">
      <div class="performance-header-row">
        <div class="info-box info-box-settlement">
          <span class="info-box-label">정산월</span>
          <span class="info-box-content">{{ activeMonth ? activeMonth.settlement_month : '' }}</span>
        </div>
        <div class="info-box info-box-period">
          <span class="info-box-label">제출기간</span>
          <span class="info-box-content">{{ activeMonth ? (activeMonth.start_date + ' ~ ' + activeMonth.end_date) : '' }}</span>
        </div>
        <!-- 처방월 박스 -->
        <div class="info-box info-box-prescription">
          <span class="info-box-label">처방월</span>
          <select v-model="prescriptionOffset" class="prescription-select">
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
            <input 
              type="text" 
              v-model="selectedHospitalName" 
              readonly 
              @click="openHospitalModal" 
              @focus="handleHospitalFocus"
              class="hospital-input"
              :class="currentCell.row === -1 && currentCell.col === 'hospital' ? 'hospital-input-focused' : ''"
              placeholder="병원명을 선택하세요" 
              tabindex="0"
            />
          </div>
          <span v-if="selectedHospitalInfo" class="hospital-info">
            ({{ selectedHospitalInfo.business_registration_number }}, {{ selectedHospitalInfo.owner_name }}, {{ selectedHospitalInfo.address }})
          </span>
        </div>
        <button 
          class="btn-primary register-button" 
          @click="onRegister" 
          :disabled="!canRegister" 
          :class="{ 'disabled-area': !isInputEnabled }"
        >등록</button>
      </div>
      
      <table class="input-table" :class="{ 'disabled-area': !isInputEnabled }">
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
          <tr v-for="(row, rowIdx) in inputRows" :key="rowIdx">
            <td style="text-align:center;">{{ rowIdx + 1 }}</td>
            <td style="position:relative;text-align:left;">
              <input
                v-model="row.product_name_display"
                :tabindex="isInputEnabled ? 0 : -1"
                :readonly="!isInputEnabled"
                @input="handleProductNameInput(rowIdx, $event)"
                @keydown.enter.prevent="applySelectedProductFromSearch(rowIdx)"
                @keydown.down.prevent="navigateProductSearchList('down')"
                @keydown.up.prevent="navigateProductSearchList('up')"
                @keydown="onArrowKey($event, rowIdx, 'product_name')"
                @focus="handleProductNameFocus(rowIdx)"
                @blur="setTimeout(() => hideProductSearchList(rowIdx), 200)" 
                :disabled="!isInputEnabled"
                :class="[
                  cellClass(rowIdx, 'product_name'),
                  { 'disabled-area': !isInputEnabled }
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
                :tabindex="isInputEnabled ? 0 : -1"
                :readonly="!isInputEnabled"
                @keydown.enter.prevent="addOrFocusNextRow(rowIdx)"
                @keydown="onArrowKey($event, rowIdx, 'prescription_qty')"
                @input="onQtyInput(rowIdx)"
                @focus="handleFieldFocus(rowIdx, 'prescription_qty')"
                :disabled="!isInputEnabled"
                :class="[
                  cellClass(rowIdx, 'prescription_qty'),
                  { 'disabled-area': !isInputEnabled }
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
                :tabindex="isInputEnabled ? 0 : -1"
                :readonly="!isInputEnabled"
                @change="onPrescriptionTypeInput(rowIdx)"
                @keydown="onPrescriptionTypeKeydown($event, rowIdx)"
                @focus="handleFieldFocus(rowIdx, 'prescription_type')"
                :disabled="!isInputEnabled"
                :class="[
                  cellClass(rowIdx, 'prescription_type'),
                  { 'disabled-area': !isInputEnabled }
                ]"
                style="text-align:center;"
              >
                <option v-for="type in prescriptionTypeOptions" :key="type" :value="type">{{ type }}</option>
              </select>
            </td>
            <td style="text-align:left;">
              <input
                v-model="row.remarks"
                :tabindex="isInputEnabled ? 0 : -1"
                :readonly="!isInputEnabled"
                @keydown.enter.prevent="addOrFocusNextRow(rowIdx)"
                @keydown="onArrowKey($event, rowIdx, 'remarks')"
                @focus="handleFieldFocus(rowIdx, 'remarks')"
                :disabled="!isInputEnabled"
                :class="[
                  cellClass(rowIdx, 'remarks'),
                  { 'disabled-area': !isInputEnabled }
                ]"
                style="text-align:left;"
              />
            </td>
            <td class="action-cell">
              <button 
                class="btn-delete-m" 
                @click="confirmDeleteRow(rowIdx)" 
                :disabled="inputRows.length === 1 || !isInputEnabled" 
                title="행 삭제"
                :class="{ 'disabled-area': !isInputEnabled }"
              >－</button>
            </td>
            <td class="action-cell">
              <button 
                class="btn-add-m" 
                @click="confirmAddRowBelow(rowIdx)" 
                title="아래에 행 추가"
                :disabled="!isInputEnabled"
                :class="{ 'disabled-area': !isInputEnabled }"
              >＋</button>
            </td>
          </tr>
        </tbody>
        <tfoot>
          <tr>
            <td colspan="4" style="text-align:center;font-weight:bold;">합계</td>
            <td style="text-align:right;font-weight:bold;">{{ totalQty }}</td>
            <td style="text-align:right;font-weight:bold;">{{ totalAmount }}</td>
            <td colspan="4"></td>
          </tr>
        </tfoot>
      </table>
      
      <div v-if="!activeMonth" style="position:absolute;top:0;left:0;width:100%;height:100%;display:flex;align-items:center;justify-content:center;z-index:10;background:rgba(255,255,255,0);">
        <div style="font-size:1.8rem;color:#d32f2f;text-align:center;">지금은 실적 입력 기간이 아닙니다.</div>
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
import { ref, computed, onMounted, watch, nextTick, onUnmounted } from 'vue';
import { onBeforeRouteLeave } from 'vue-router';
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

function truncateText(text, maxLength) {
  if (!text) return '';
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength) + '...';
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
  
  // 제품 검색 드롭다운이 열려있으면 차단
  if (isProductSearchOpen.value) {
    return;
  }
  
  hospitalModalVisible.value = true;
}

// 병원 선택 input 포커스 핸들러
function handleHospitalFocus() {
  // 제품 검색 드롭다운이 열려있으면 포커스 차단
  if (isProductSearchOpen.value) {
    event.target.blur();
    return;
  }
  
  currentCell.value = { row: -1, col: 'hospital' };
}

function onHospitalRowSelect(e) {
  const hospital = e.data;
  selectedHospitalName.value = hospital.name;
  selectedHospitalInfo.value = hospital;
  selectedHospitalId.value = hospital.id;
  hospitalModalVisible.value = false;
  // 병원 선택 시 첫 번째 제품명 입력란으로 포커스 이동
  nextTick(() => focusField(0, 'product_name'));
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
  // 병원이 1개일 때만 자동 선택
  if (data && data.length === 1) {
    selectedHospitalName.value = data[0].name;
    selectedHospitalInfo.value = data[0];
    selectedHospitalId.value = data[0].id;
    // 자동 선택 시 첫 번째 제품명 입력란으로 포커스 이동
    nextTick(() => focusField(0, 'product_name'));
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
    productSearchForRow.value.activeRowIndex = -1;
  }
}

// 제품 검색 드롭다운이 열려있는지 확인하는 computed
const isProductSearchOpen = computed(() => {
  return productSearchForRow.value.show && productSearchForRow.value.activeRowIndex !== -1;
});

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
    // 제품명과 수량이 모두 입력되어 있어야 새 행 생성
    if (!currentRow.product_id || !currentRow.prescription_qty) {
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
  
  // 비고 입력 중일 때
  if (currentCell.value.col === 'remarks') {
    // 제품명과 수량이 모두 입력되어 있어야 새 행 생성
    if (!currentRow.product_id || !currentRow.prescription_qty) {
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
    const currentRow = inputRows.value[currentCell.value.row];
    if (currentRow.product_id && currentRow.prescription_qty && currentCell.value.row === inputRows.value.length - 1) {
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
      newRow = currentCell.value.row + 1;
      newColIdx = 0; // 제품명으로 이동
    } else {
      newRow = Math.min(inputRows.value.length - 1, currentCell.value.row + 1);
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
  const qty = Number(inputRows.value[rowIdx].prescription_qty);
  const price = Number(inputRows.value[rowIdx].price);
  if (!isNaN(qty) && !isNaN(price) && price > 0) {
    inputRows.value[rowIdx].prescription_amount = (qty * price).toLocaleString();
  } else {
    inputRows.value[rowIdx].prescription_amount = '';
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
    const currentRow = inputRows.value[rowIdx];
    if (currentRow.product_id && currentRow.prescription_qty && rowIdx === inputRows.value.length - 1) {
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
      newRow = rowIdx + 1;
      newColIdx = 0; // 제품명으로 이동
    } else {
      newRow = Math.min(inputRows.value.length - 1, rowIdx + 1);
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

// 입력 중인 실적이 있는지 체크하는 함수
function hasInputData() {
  return inputRows.value.some(row => 
    row.product_id || 
    row.prescription_qty || 
    row.product_name_display.trim()
  );
}

// 페이지 이탈 시 확인
onBeforeRouteLeave(async (to, from, next) => {
  // 입력 중인 데이터가 없으면 바로 이동
  if (!hasInputData()) {
    next();
    return;
  }

  // 입력 중인 실적이 있으면 사용자에게 확인
  const shouldLeave = confirm('입력중인 실적이 있습니다. 등록하지 않고 이동하시겠습니까?');
  
  if (shouldLeave) {
    next(); // 확인 시 이동
  } else {
    next(false); // 취소 시 이동 취소
  }
});

// 실적 저장 로직을 별도 함수로 분리
async function savePerformanceData() {
  if (!activeMonth.value || !selectedHospitalId.value) {
    throw new Error('정산월 또는 병원이 선택되지 않았습니다.');
  }

  // 1. 행 분류
  const completeRows = [];
  const partialRows = [];

  inputRows.value.forEach((row, index) => {
    const hasProduct = !!row.product_id;
    const hasQty = !!row.prescription_qty;

    if (hasProduct && hasQty) {
      completeRows.push({ ...row, rowNumber: index + 1 });
    } else if (hasProduct || hasQty) {
      partialRows.push({ ...row, rowNumber: index + 1 });
    }
  });

  // 2. 저장할 데이터가 없는 경우
  if (completeRows.length === 0) {
    throw new Error('저장할 실적 데이터가 없습니다.');
  }

  // 3. 현재 사용자 정보 가져오기
  const { data: { session } } = await supabase.auth.getSession();
  const userUid = session?.user?.id;
  if (!userUid) {
    throw new Error('로그인 정보를 확인할 수 없습니다.');
  }

  // 4. 사용자의 회사 정보 가져오기
  const { data: myCompany } = await supabase.from('companies').select('id').eq('user_id', userUid).single();
  if (!myCompany) {
    throw new Error('회사 정보를 찾을 수 없습니다.');
  }

  // 5. 저장할 데이터 준비
  const performanceData = completeRows.map(row => ({
    company_id: myCompany.id,
    settlement_month: activeMonth.value.settlement_month,
    prescription_month: prescriptionMonth.value,
    client_id: selectedHospitalId.value,
    product_id: row.product_id,
    prescription_qty: parseInt(row.prescription_qty),
    prescription_type: row.prescription_type || 'EDI',
    remarks: row.remarks || null,
    registered_by: userUid
  }));

  // 6. 데이터베이스에 저장
  const { error } = await supabase
    .from('performance_records')
    .insert(performanceData);

  if (error) {
    throw new Error('실적 저장 중 오류가 발생했습니다.');
  }

  return completeRows.length;
}

// 기존 onRegister 함수 수정 (savePerformanceData 함수 활용)
async function onRegister() {
  // 제품 검색 드롭다운이 열려있으면 차단
  if (isProductSearchOpen.value) {
    return;
  }
  
  if (!activeMonth.value || !selectedHospitalId.value) {
    alert('정산월 또는 병원이 선택되지 않았습니다.');
    return;
  }

  // 1. 행 분류 (부분 누락 행 확인용)
  const partialRows = [];
  inputRows.value.forEach((row, index) => {
    const hasProduct = !!row.product_id;
    const hasQty = !!row.prescription_qty;

    if ((hasProduct || hasQty) && !(hasProduct && hasQty)) {
      partialRows.push({ ...row, rowNumber: index + 1 });
    }
  });

  // 2. 부분 누락 행이 있는 경우 사용자 확인
  if (partialRows.length > 0) {
    const partialRowNumbers = partialRows.map(row => `No ${row.rowNumber}`).join(', ');
    const message = `${partialRows.length}건의 실적이 필수 정보(제품, 처방수량)가 누락되었습니다.\n${partialRowNumbers}\n제외하고 등록하시겠습니까?`;
    
    if (!confirm(message)) {
      return; // 취소 시 등록 중단
    }
  }

  try {
    // 3. 저장 처리
    const savedCount = await savePerformanceData();
    
    // 4. 성공 메시지
    alert(`${savedCount}건의 실적이 저장되었습니다.`);

    // 5. 화면 초기화
    resetForm();

  } catch (err) {
    console.error('등록 처리 오류:', err);
    alert(err.message || '실적 등록 중 오류가 발생했습니다.');
  }
}

// 화면 초기화 함수
function resetForm() {
  // 병원 선택 초기화
  selectedHospitalName.value = '';
  selectedHospitalInfo.value = null;
  selectedHospitalId.value = null;
  
  // 입력 행 초기화 (1개 빈 행만 남김)
  inputRows.value = [{ 
    product_name_display: '', 
    product_id: null, 
    insurance_code: '', 
    price: '', 
    prescription_qty: '', 
    prescription_amount: '', 
    prescription_type: 'EDI', 
    remarks: '' 
  }];
  
  // 현재 셀 초기화
  currentCell.value = { row: 0, col: 'product_name' };
  
  // 제품 검색 상태 초기화
  productSearchForRow.value = {
    query: '',
    results: [],
    selectedIndex: -1,
    show: false,
    activeRowIndex: -1,
  };
  
  // 병원명 input에 포커스
  nextTick(() => {
    const hospitalInput = document.querySelector('input[placeholder="병원명을 선택하세요"]');
    if (hospitalInput) {
      hospitalInput.focus();
      // 병원명 input 포커스 상태 설정
      currentCell.value = { row: -1, col: 'hospital' };
    }
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
    if (inputRows.value.length > 1) {
      confirmDeleteRow(currentRowIdx);
    }
  } else if (e.key === 'Insert') {
    e.preventDefault();
    const currentRowIdx = currentCell.value.row;
    confirmAddRowBelow(currentRowIdx);
  }
}

// 라이프사이클
onMounted(() => {
  fetchActiveMonth();
  fetchHospitals();
  fetchProducts();
  // 진입 시 병원명 input에 포커스
  nextTick(() => {
    const hospitalInput = document.querySelector('input[placeholder="병원명을 선택하세요"]');
    if (hospitalInput) {
      hospitalInput.focus();
      // 병원명 input 포커스 상태 설정
      currentCell.value = { row: -1, col: 'hospital' };
    }
  });
  // 전역 키보드 이벤트 리스너 추가
  document.addEventListener('keydown', handleGlobalKeydown);
});

// 컴포넌트 언마운트 시 이벤트 리스너 제거
onUnmounted(() => {
  document.removeEventListener('keydown', handleGlobalKeydown);
});
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