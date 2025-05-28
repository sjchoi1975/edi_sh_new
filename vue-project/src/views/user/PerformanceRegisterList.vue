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
        <div class="action-buttons">
          <button 
            class="btn-secondary" 
            @click="downloadExcel" 
            :disabled="sortedDisplayRows.length === 0"
            title="엑셀 다운로드"
          >📊 엑셀 다운로드</button>
          <button 
            class="btn-primary register-button" 
            @click="onSave" 
            :disabled="!canSave" 
            :class="{ 'disabled-area': !isEditMode }"
            v-if="isEditMode"
          >{{ isEditMode ? '저장' : '저장' }}</button>
        </div>
      </div>
      
      <div class="table-scroll-wrapper">
        <table class="input-table" :class="{ 'disabled-area': !isEditMode }">
          <thead>
            <tr>
              <th style="width:40px;">No</th>
              <th :style="isEditMode ? 'width:12%;' : 'width:13%;'" @click="sortBy('client_name')" style="cursor:pointer;" v-html="'거래처' + getSortIcon('client_name')"></th>
              <th :style="isEditMode ? 'width:6%;' : 'width:6%;'" @click="sortBy('prescription_month')" style="cursor:pointer;" v-html="'처방월' + getSortIcon('prescription_month')"></th>
              <th :style="isEditMode ? 'width:18%;' : 'width:18%;'" @click="sortBy('product_name_display')" style="cursor:pointer;" v-html="'제품명' + getSortIcon('product_name_display')"></th>
              <th :style="isEditMode ? 'width:8%;' : 'width:8%;'" @click="sortBy('insurance_code')" style="cursor:pointer;" v-html="'보험코드' + getSortIcon('insurance_code')"></th>
              <th :style="isEditMode ? 'width:6%;' : 'width:6%;'" @click="sortBy('price')" style="cursor:pointer;" v-html="'약가' + getSortIcon('price')"></th>
              <th :style="isEditMode ? 'width:6%;' : 'width:6%;'" @click="sortBy('prescription_qty')" style="cursor:pointer;" v-html="'처방수량' + getSortIcon('prescription_qty')"></th>
              <th :style="isEditMode ? 'width:6%;' : 'width:6%;'" @click="sortBy('prescription_amount')" style="cursor:pointer;" v-html="'처방액' + getSortIcon('prescription_amount')"></th>
              <th :style="isEditMode ? 'width:8%;' : 'width:8%;'" @click="sortBy('prescription_type')" style="cursor:pointer;" v-html="'처방구분' + getSortIcon('prescription_type')"></th>
              <th :style="isEditMode ? 'width:10%;' : 'width:11%;'">비고</th>
              <th v-if="isEditMode" style="width:40px;">삭제</th>
              <th v-if="isEditMode" style="width:40px;">추가</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="displayRows.length === 0">
              <td :colspan="isEditMode ? 12 : 10" style="text-align:center;padding:2rem;color:#666;">
                <div v-if="!selectedSettlementMonth">정산월을 선택하세요.</div>
                <div v-else-if="!isEditMode">등록된 실적이 없습니다.</div>
                <div v-else>
                  <div style="margin-bottom:1rem;">등록된 실적이 없습니다.</div>
                  <button class="btn-primary" @click="addNewRow">새 실적 추가</button>
                </div>
              </td>
            </tr>
            <tr v-for="(row, rowIdx) in sortedDisplayRows" :key="rowIdx" v-else>
              <td style="text-align:center;">{{ rowIdx + 1 }}</td>
              <td style="text-align:left;">
                <div v-if="isEditMode" class="product-input-container">
                  <input 
                    v-model="row.client_name" 
                    :tabindex="isEditMode ? 0 : -1"
                    :readonly="!isEditMode"
                    @input="handleClientNameInput(rowIdx, $event)"
                    @keydown.enter.prevent="applySelectedClientFromSearch(rowIdx)"
                    @keydown.down.prevent="navigateClientSearchList('down')"
                    @keydown.up.prevent="navigateClientSearchList('up')"
                    @focus="handleClientNameFocus(rowIdx)"
                    @blur="setTimeout(() => hideClientSearchList(rowIdx), 200)"
                    :class="cellClass(rowIdx, 'client_name')"
                    autocomplete="off"
                    style="text-align:left;"
                  />
                  <button 
                    type="button"
                    @click="toggleClientDropdown(rowIdx)"
                    @mousedown.prevent
                    class="dropdown-arrow-btn"
                    tabindex="-1"
                  >
                    <span class="dropdown-arrow">▼</span>
                  </button>
                  <div v-if="clientSearchForRow.show && clientSearchForRow.activeRowIndex === rowIdx && clientSearchForRow.results.length > 0" class="search-dropdown hospital-search-dropdown">
                    <ul>
                      <li
                        v-for="(client, index) in clientSearchForRow.results"
                        :key="client.id"
                        @click="clickClientFromSearchList(client, rowIdx)"
                        :class="{ 'selected': clientSearchForRow.selectedIndex === index }"
                      >
                        <div class="hospital-info-row">
                          <span class="hospital-name">{{ client.name }}</span>
                          <span class="hospital-reg-number">{{ client.business_registration_number }}</span>
                        </div>
                        <div class="hospital-address">{{ truncateText(client.address, 20) }}</div>
                      </li>
                    </ul>
                  </div>
                </div>
                <input 
                  v-else
                  v-model="row.client_name" 
                  readonly 
                  tabindex="-1" 
                  style="text-align:left; background: #fff !important;"
                />
              </td>
              <td style="text-align:center;">
                <input 
                  v-model="row.prescription_month" 
                  readonly 
                  tabindex="-1" 
                  style="text-align:center; background: #fff !important;"
                />
              </td>
              <td style="position:relative;text-align:left;">
                <div v-if="isEditMode" class="product-input-container">
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
                    :class="cellClass(rowIdx, 'product_name')"
                    autocomplete="off"
                    style="text-align:left;"
                  />
                  <button 
                    type="button"
                    @click="toggleProductDropdown(rowIdx)"
                    @mousedown.prevent
                    class="dropdown-arrow-btn"
                    tabindex="-1"
                  >
                    <span class="dropdown-arrow">▼</span>
                  </button>
                  <div v-if="productSearchForRow.show && productSearchForRow.activeRowIndex === rowIdx && productSearchForRow.results.length > 0" class="search-dropdown product-search-dropdown">
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
                </div>
                <input
                  v-else
                  v-model="row.product_name_display"
                  readonly
                  tabindex="-1"
                  style="text-align:left; background: #fff !important;"
                />
              </td>
              <td style="text-align:center;">
                <input 
                  v-model="row.insurance_code" 
                  readonly 
                  tabindex="-1" 
                  style="text-align:center; background: #fff !important;"
                />
              </td>
              <td style="text-align:right;">
                <input 
                  v-model="row.price" 
                  readonly 
                  tabindex="-1" 
                  style="text-align:right; background: #fff !important;"
                />
              </td>
              <td style="text-align:right; position:relative;">
                <input
                  v-model="row.prescription_qty"
                  :tabindex="isEditMode ? 0 : -1"
                  :readonly="!isEditMode"
                  @keydown.enter.prevent="addOrFocusNextRow(rowIdx)"
                  @keydown="onArrowKey($event, rowIdx, 'prescription_qty')"
                  @input="onQtyInput(rowIdx)"
                  @focus="handlePrescriptionQtyFocus(rowIdx)"
                  @blur="handlePrescriptionQtyBlur(rowIdx)"
                  :disabled="!isEditMode"
                  :class="[
                    cellClass(rowIdx, 'prescription_qty'),
                    { 'disabled-area': !isEditMode }
                  ]"
                  :style="isEditMode ? 'text-align:right;' : 'text-align:right; background: #fff !important;'"
                />
              </td>
              <td style="text-align:right;">
                <input 
                  v-model="row.prescription_amount" 
                  readonly 
                  tabindex="-1" 
                  style="text-align:right; background: #fff !important;"
                />
              </td>
              <td style="text-align:center;">
                <select
                  v-if="isEditMode"
                  v-model="row.prescription_type"
                  :tabindex="isEditMode ? 0 : -1"
                  @change="onPrescriptionTypeInput(rowIdx)"
                  @keydown="onPrescriptionTypeKeydown($event, rowIdx)"
                  @focus="handleFieldFocus(rowIdx, 'prescription_type')"
                  :class="cellClass(rowIdx, 'prescription_type')"
                  style="text-align:center;"
                >
                  <option v-for="type in prescriptionTypeOptions" :key="type" :value="type">{{ type }}</option>
                </select>
                <input
                  v-else
                  v-model="row.prescription_type"
                  readonly
                  tabindex="-1"
                  style="text-align:center; background: #fff !important;"
                />
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
                  :style="isEditMode ? 'text-align:left;' : 'text-align:left; background: #fff !important;'"
                />
              </td>
              <td v-if="isEditMode" :class="isEditMode ? 'action-cell' : 'action-cell-disabled'">
                <button 
                  :class="isEditMode ? 'btn-delete-m' : 'btn-delete-m-d'"
                  @click="isEditMode ? confirmDeleteRow(rowIdx) : null" 
                  :disabled="displayRows.length === 1 || !isEditMode" 
                  title="행 삭제"
                >－</button>
              </td>
              <td v-if="isEditMode" :class="isEditMode ? 'action-cell' : 'action-cell-disabled'">
                <button 
                  :class="isEditMode ? 'btn-add-m' : 'btn-add-m-d'"
                  @click="isEditMode ? confirmAddRowBelow(rowIdx) : null" 
                  title="아래에 행 추가"
                  :disabled="!isEditMode"
                >＋</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      
      <!-- 합계 행을 별도 테이블로 분리하여 하단 고정 -->
      <div class="table-footer-wrapper">
        <table class="input-table footer-table" :class="{ 'disabled-area': !isEditMode }">
          <tfoot>
            <tr>
              <td style="width:40px;"></td>
              <td :style="isEditMode ? 'width:12%;' : 'width:13%;'"></td>
              <td :style="isEditMode ? 'width:6%;' : 'width:6%;'"></td>
              <td :style="isEditMode ? 'width:18%;' : 'width:18%;'"></td>
              <td :style="isEditMode ? 'width:8%;' : 'width:8%;'"></td>
              <td :style="isEditMode ? 'width:6%;' : 'width:6%;'" style="text-align:center;">합계</td>
              <td :style="isEditMode ? 'width:6%;' : 'width:6%;'" style="text-align:right;">{{ totalQty }}</td>
              <td :style="isEditMode ? 'width:6%;' : 'width:6%;'" style="text-align:right;">{{ totalAmount }}</td>
              <td :style="isEditMode ? 'width:8%;' : 'width:8%;'"></td>
              <td :style="isEditMode ? 'width:10%;' : 'width:11%;'"></td>
              <td v-if="isEditMode" style="width:40px;"></td>
              <td v-if="isEditMode" style="width:40px;"></td>
            </tr>
          </tfoot>
        </table>
      </div>
      
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
import * as XLSX from 'xlsx';

// 반응형 데이터
const availableMonths = ref([]); // 선택 가능한 정산월 목록
const selectedSettlementMonth = ref(''); // 선택된 정산월
const selectedMonthInfo = ref(null); // 선택된 정산월 정보
const prescriptionMonth = ref('');
const prescriptionOffset = ref(0); // 0: 전체, 1: -1M, 2: -2M, 3: -3M
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
  if (!isEditMode.value || !hasChanges.value) return false;
  
  // 유효한 행이 있는지 확인 (제품과 수량이 모두 입력된 행)
  const validRows = displayRows.value.filter(row => row.product_id && row.prescription_qty);
  if (validRows.length === 0) return false;
  
  // 모든 유효한 행에 거래처가 선택되어 있는지 확인
  const allRowsHaveClient = validRows.every(row => row.client_name);
  
  return allRowsHaveClient;
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

// 거래처 검색 관련
const clientSearchForRow = ref({
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

// 정렬 관련 변수 추가
const sortField = ref('');
const sortOrder = ref(1); // 1: 오름차순, -1: 내림차순

// 정렬된 데이터를 반환하는 computed 속성
const sortedDisplayRows = computed(() => {
  if (!sortField.value) return displayRows.value;
  
  const sorted = [...displayRows.value].sort((a, b) => {
    let aVal = a[sortField.value];
    let bVal = b[sortField.value];
    
    // 숫자 필드 처리
    if (sortField.value === 'prescription_qty') {
      aVal = Number(aVal) || 0;
      bVal = Number(bVal) || 0;
    } else if (sortField.value === 'price') {
      aVal = Number(aVal.toString().replace(/,/g, '')) || 0;
      bVal = Number(bVal.toString().replace(/,/g, '')) || 0;
    } else if (sortField.value === 'prescription_amount') {
      aVal = Number(aVal.toString().replace(/,/g, '')) || 0;
      bVal = Number(bVal.toString().replace(/,/g, '')) || 0;
    } else {
      // 문자열 필드 처리
      aVal = (aVal || '').toString().toLowerCase();
      bVal = (bVal || '').toString().toLowerCase();
    }
    
    if (aVal < bVal) return -1 * sortOrder.value;
    if (aVal > bVal) return 1 * sortOrder.value;
    return 0;
  });
  
  return sorted;
});

// 정렬 함수
function sortBy(field) {
  if (sortField.value === field) {
    // 같은 필드를 클릭하면 정렬 순서 변경
    sortOrder.value = sortOrder.value * -1;
  } else {
    // 다른 필드를 클릭하면 해당 필드로 오름차순 정렬
    sortField.value = field;
    sortOrder.value = 1;
  }
}

// 정렬 아이콘 반환 함수
function getSortIcon(field) {
  if (sortField.value !== field) return '';
  return sortOrder.value === 1 ? ' <span class="sort-arrow">▲</span>' : ' <span class="sort-arrow">▼</span>';
}

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
  
  // "- 전체 -" 옵션을 첫 번째로 추가
  prescriptionOptions.value = [
    { value: 0, month: '- 전체 -' },
    ...([1, 2, 3].map(offset => ({
      value: offset,
      month: getPrescriptionMonth(selectedMonthInfo.value.settlement_month, offset)
    })))
  ];
}

// 편집 모드 확인 함수
function checkEditMode() {
  const prevEditMode = isEditMode.value;
  
  if (!selectedMonthInfo.value) {
    isEditMode.value = false;
  } else {
    const today = new Date();
    const todayStr = today.toISOString().slice(0, 10);
    const startDate = new Date(selectedMonthInfo.value.start_date);
    const endDate = new Date(selectedMonthInfo.value.end_date);
    const todayDate = new Date(todayStr);
    
    // 오늘이 제출기간 내에 있는지 확인
    isEditMode.value = todayDate >= startDate && todayDate <= endDate;
  }
  
  // 편집 모드가 변경되면 변경사항 초기화
  if (prevEditMode !== isEditMode.value) {
    hasChanges.value = false;
    console.log('편집 모드 변경:', { prevEditMode, newEditMode: isEditMode.value, hasChanges: hasChanges.value });
  }
}

// 워치어
watch(selectedSettlementMonth, () => {
  const monthInfo = availableMonths.value.find(m => m.settlement_month === selectedSettlementMonth.value);
  selectedMonthInfo.value = monthInfo || null;
  updatePrescriptionOptions();
  prescriptionOffset.value = 0; // 기본값을 "- 전체 -"로 설정
  prescriptionMonth.value = ''; // 전체 선택 시 빈 값
  checkEditMode();
  
  if (selectedSettlementMonth.value) {
    fetchPerformanceRecords();
  } else {
    displayRows.value = [];
    performanceRecords.value = [];
  }
});

watch(prescriptionOffset, (val) => {
  if (val === 0) {
    prescriptionMonth.value = ''; // 전체 선택 시 빈 값
  } else {
    prescriptionMonth.value = getPrescriptionMonth(selectedSettlementMonth.value, val);
  }
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
  // 데이터 변경 시 테이블 너비 동기화
  syncTableWidths();
}, { deep: true });

function checkForChanges() {
  // 편집 모드가 아니면 변경사항 없음
  if (!isEditMode.value) {
    hasChanges.value = false;
    return;
  }
  
  // 원본 데이터와 현재 데이터 모두 없으면 변경사항 없음
  if (!originalData.value.length && !displayRows.value.length) {
    hasChanges.value = false;
    return;
  }
  
  // 현재 유효한 행들 (제품과 수량이 모두 입력된 행들)
  const currentValidRows = displayRows.value.filter(row => 
    row.product_id && 
    row.prescription_qty && 
    row.client_name
  );
  
  // 원본 유효한 행들
  const originalValidRows = originalData.value.filter(row => 
    row.product_id && 
    row.prescription_qty && 
    row.client_name
  );
  
  // 원본이 없고 현재도 유효한 행이 없으면 변경사항 없음 (초기 상태)
  if (originalValidRows.length === 0 && currentValidRows.length === 0) {
    hasChanges.value = false;
    return;
  }
  
  // 행 개수가 다르면 변경됨
  if (currentValidRows.length !== originalValidRows.length) {
    hasChanges.value = true;
    return;
  }
  
  // 각 행의 내용 비교 (순서 고려)
  for (let i = 0; i < currentValidRows.length; i++) {
    const current = currentValidRows[i];
    const original = originalValidRows[i];
    
    if (
      current.product_id !== original.product_id ||
      current.prescription_qty !== original.prescription_qty ||
      current.prescription_type !== original.prescription_type ||
      (current.remarks || '') !== (original.remarks || '') ||
      current.client_name !== original.client_name
    ) {
      hasChanges.value = true;
      return;
    }
  }
  
  hasChanges.value = false;
}

// 병원 관련 함수들은 제거됨 (모달 방식에서 드롭다운으로 변경)

// 데이터 fetch 함수들
async function fetchHospitals() {
  try {
    if (userType.value === 'admin') {
      // 관리자는 모든 병원 조회
      const { data, error } = await supabase
        .from('clients')
        .select('*')
        .eq('status', 'active')
        .order('name', { ascending: true });
        
      if (error) {
        console.error('병원 조회 오류 (관리자):', error);
        hospitals.value = [];
        return;
      }
      
      hospitals.value = data || [];
    } else {
      // 일반 사용자는 할당된 병원만 조회
      if (!currentUserCompanyId.value) {
        hospitals.value = [];
        return;
      }
      
      const { data: assignments, error: assignError } = await supabase
        .from('client_company_assignments')
        .select('client_id')
        .eq('company_id', currentUserCompanyId.value);
        
      if (assignError) {
        console.error('병원 할당 조회 오류:', assignError);
        hospitals.value = [];
        return;
      }
      
      if (!assignments || assignments.length === 0) {
        hospitals.value = [];
        return;
      }
      
      const clientIds = assignments.map(a => a.client_id);
      const { data, error } = await supabase
        .from('clients')
        .select('*')
        .in('id', clientIds)
        .eq('status', 'active')
        .order('name', { ascending: true });
        
      if (error) {
        console.error('병원 조회 오류 (사용자):', error);
        hospitals.value = [];
        return;
      }
      
      hospitals.value = data || [];
    }
  } catch (err) {
    console.error('병원 조회 예외:', err);
    hospitals.value = [];
  }
}

async function fetchProducts() {
  try {
    const { data, error } = await supabase
      .from('products')
      .select('id, product_name, insurance_code, price')
      .eq('status', 'active')
      .order('product_name', { ascending: true });
      
    if (error) {
      console.error('제품 조회 오류:', error);
      products.value = [];
      return;
    }
    
    if (!data || data.length === 0) {
      products.value = [];
      return;
    }
    
    // 보험코드별로 중복 제거 (보험코드가 있는 것 우선)
    const uniqByInsurance = {};
    const noInsurance = [];
    
    data.forEach(p => {
      if (p.insurance_code) {
        if (!uniqByInsurance[p.insurance_code]) {
          uniqByInsurance[p.insurance_code] = p;
        }
      } else {
        noInsurance.push(p);
      }
    });
    
    products.value = [...Object.values(uniqByInsurance), ...noInsurance];
  } catch (err) {
    console.error('제품 조회 예외:', err);
    products.value = [];
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
  displayRows.value[rowIndex].price = product.price ? Number(product.price).toLocaleString() : '';
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

function toggleProductDropdown(rowIndex) {
  if (!isEditMode.value) return;
  
  // 다른 행의 제품 검색이 열려있으면 차단
  if (isProductSearchOpen.value && productSearchForRow.value.activeRowIndex !== rowIndex) {
    return;
  }
  
  // 현재 드롭다운이 열려있으면 닫기
  if (productSearchForRow.value.show && productSearchForRow.value.activeRowIndex === rowIndex) {
    productSearchForRow.value.show = false;
    productSearchForRow.value.activeRowIndex = -1;
    return;
  }
  
  // 전체 제품 목록 표시
  productSearchForRow.value.activeRowIndex = rowIndex;
  productSearchForRow.value.results = products.value;
  productSearchForRow.value.selectedIndex = -1;
  productSearchForRow.value.show = productSearchForRow.value.results.length > 0;
  
  // 해당 행의 제품명 입력창에 포커스
  nextTick(() => {
    focusField(rowIndex, 'product_name');
  });
}

// 거래처 검색 관련 함수들
function handleClientNameInput(rowIndex, event) {
  if (!isEditMode.value) return;
  const query = event.target.value.toLowerCase();
  displayRows.value[rowIndex].client_name = event.target.value;
  displayRows.value[rowIndex].client_id = null;

  clientSearchForRow.value.activeRowIndex = rowIndex;
  if (query.length < 1) {
    clientSearchForRow.value.show = false;
    clientSearchForRow.value.results = [];
    return;
  }
  clientSearchForRow.value.results = hospitals.value.filter(h =>
    (h.name && h.name.toLowerCase().includes(query)) ||
    (h.business_registration_number && h.business_registration_number.includes(query))
  );
  clientSearchForRow.value.selectedIndex = -1;
  clientSearchForRow.value.show = clientSearchForRow.value.results.length > 0;
}

function navigateClientSearchList(direction) {
  if (!clientSearchForRow.value.show || clientSearchForRow.value.results.length === 0) return;
  if (direction === 'down') {
    clientSearchForRow.value.selectedIndex = (clientSearchForRow.value.selectedIndex + 1) % clientSearchForRow.value.results.length;
  } else if (direction === 'up') {
    clientSearchForRow.value.selectedIndex = (clientSearchForRow.value.selectedIndex - 1 + clientSearchForRow.value.results.length) % clientSearchForRow.value.results.length;
  }
}

function applySelectedClient(client, rowIndex) {
  displayRows.value[rowIndex].client_name = client.name;
  displayRows.value[rowIndex].client_id = client.id;
  clientSearchForRow.value.show = false;
  clientSearchForRow.value.activeRowIndex = -1;
  nextTick(() => {
    focusField(rowIndex, 'product_name');
  });
}

function applySelectedClientFromSearch(rowIndexToApply) {
  const idx = clientSearchForRow.value.selectedIndex;
  const currentActionRow = clientSearchForRow.value.activeRowIndex;
  if (clientSearchForRow.value.show && idx !== -1 && clientSearchForRow.value.results[idx] && currentActionRow === rowIndexToApply) {
    const client = clientSearchForRow.value.results[idx];
    applySelectedClient(client, currentActionRow);
  } else if (clientSearchForRow.value.show && clientSearchForRow.value.results.length > 0 && currentActionRow === rowIndexToApply) {
    const client = clientSearchForRow.value.results[0];
    applySelectedClient(client, currentActionRow);
  }
  clientSearchForRow.value.show = false;
}

function clickClientFromSearchList(client, rowIndex) {
  applySelectedClient(client, rowIndex);
}

function hideClientSearchList(rowIndex) {
  if (clientSearchForRow.value.activeRowIndex === rowIndex) {
    if (!displayRows.value[rowIndex].client_id) {
      displayRows.value[rowIndex].client_name = '';
    }
    clientSearchForRow.value.show = false;
    clientSearchForRow.value.activeRowIndex = -1;
  }
}

function toggleClientDropdown(rowIndex) {
  if (!isEditMode.value) return;
  
  // 다른 행의 거래처 검색이 열려있으면 차단
  if (clientSearchForRow.value.show && clientSearchForRow.value.activeRowIndex !== rowIndex) {
    return;
  }
  
  // 현재 드롭다운이 열려있으면 닫기
  if (clientSearchForRow.value.show && clientSearchForRow.value.activeRowIndex === rowIndex) {
    clientSearchForRow.value.show = false;
    clientSearchForRow.value.activeRowIndex = -1;
    return;
  }
  
  // 전체 거래처 목록 표시
  clientSearchForRow.value.activeRowIndex = rowIndex;
  clientSearchForRow.value.results = hospitals.value;
  clientSearchForRow.value.selectedIndex = -1;
  clientSearchForRow.value.show = clientSearchForRow.value.results.length > 0;
  
  // 해당 행의 거래처명 입력창에 포커스
  nextTick(() => {
    focusField(rowIndex, 'client_name');
  });
}

function handleClientNameFocus(rowIdx) {
  if (!isEditMode.value) {
    event.target.blur();
    return;
  }
  
  // 다른 행의 거래처 검색이 열려있으면 차단
  if (clientSearchForRow.value.show && clientSearchForRow.value.activeRowIndex !== rowIdx) {
    event.target.blur();
    return;
  }
  
  currentCell.value = { row: rowIdx, col: 'client_name' };
  clientSearchForRow.value.activeRowIndex = rowIdx;
}

// 제품명 필드 포커스 핸들러
function handleProductNameFocus(rowIdx) {
  if (!isEditMode.value) {
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
  if (!isEditMode.value) {
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

// 처방수량 필드 포커스 핸들러
function handlePrescriptionQtyFocus(rowIdx) {
  if (!isEditMode.value) {
    event.target.blur();
    return;
  }
  
  // 제품 검색 드롭다운이 열려있으면 포커스 차단
  if (isProductSearchOpen.value) {
    event.target.blur();
    return;
  }
  
  // 포커스 시 콤마 제거
  displayRows.value[rowIdx].prescription_qty = displayRows.value[rowIdx].prescription_qty ? displayRows.value[rowIdx].prescription_qty.toString().replace(/,/g, '') : '';
  
  currentCell.value = { row: rowIdx, col: 'prescription_qty' };
}

// 처방수량 필드 블러 핸들러
function handlePrescriptionQtyBlur(rowIdx) {
  const qty = displayRows.value[rowIdx].prescription_qty;
  if (qty) {
    displayRows.value[rowIdx].prescription_qty = Number(qty.toString().replace(/,/g, '')).toLocaleString();
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
    if (col === 'product_name') el = row.querySelector('td:nth-child(4) input');
    else if (col === 'prescription_qty') el = row.querySelector('td:nth-child(7) input');
    else if (col === 'prescription_type') el = row.querySelector('td:nth-child(9) select, td:nth-child(9) input');
    else if (col === 'remarks') el = row.querySelector('td:nth-child(10) input');
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
      const clientName = selectedHospitalId.value ? selectedHospitalInfo.value?.name || '' : '';
      displayRows.value.push({ 
        product_name_display: '', 
        product_id: null, 
        insurance_code: '', 
        price: '', 
        prescription_qty: '', 
        prescription_amount: '', 
        prescription_type: 'EDI',
        client_name: clientName,
        prescription_month: prescriptionMonth.value,
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
      const clientName = selectedHospitalId.value ? selectedHospitalInfo.value?.name || '' : '';
      displayRows.value.push({ 
        product_name_display: '', 
        product_id: null, 
        insurance_code: '', 
        price: '', 
        prescription_qty: '', 
        prescription_amount: '', 
        prescription_type: 'EDI',
        client_name: clientName,
        prescription_month: prescriptionMonth.value,
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
      const clientName = selectedHospitalId.value ? selectedHospitalInfo.value?.name || '' : '';
      displayRows.value.push({ 
        product_name_display: '', 
        product_id: null, 
        insurance_code: '', 
        price: '', 
        prescription_qty: '', 
        prescription_amount: '', 
        prescription_type: 'EDI',
        client_name: clientName,
        prescription_month: prescriptionMonth.value,
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
  const qty = Number(displayRows.value[rowIdx].prescription_qty.toString().replace(/,/g, ''));
  const price = Number(displayRows.value[rowIdx].price.toString().replace(/,/g, ''));
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
      const clientName = selectedHospitalId.value ? selectedHospitalInfo.value?.name || '' : '';
      displayRows.value.push({ 
        product_name_display: '', 
        product_id: null, 
        insurance_code: '', 
        price: '', 
        prescription_qty: '', 
        prescription_amount: '', 
        prescription_type: 'EDI',
        client_name: clientName,
        prescription_month: prescriptionMonth.value,
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
  const total = sortedDisplayRows.value.reduce((sum, row) => sum + (Number(row.prescription_qty) || 0), 0);
  return total.toLocaleString();
});
const totalAmount = computed(() => {
  return sortedDisplayRows.value.reduce((sum, row) => sum + (Number(row.prescription_amount.toString().replace(/,/g, '')) || 0), 0).toLocaleString();
});

// 행 추가/삭제
function addRowBelow(idx) {
  const clientName = selectedHospitalId.value ? selectedHospitalInfo.value?.name || '' : '';
  displayRows.value.splice(idx + 1, 0, {
    product_name_display: '', product_id: null, insurance_code: '', price: '', prescription_qty: '', prescription_amount: '', prescription_type: 'EDI', client_name: clientName, prescription_month: prescriptionMonth.value, remarks: ''
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

// 전역 클릭 이벤트 처리
function handleGlobalClick(e) {
  // 거래처 검색 드롭다운 처리
  if (clientSearchForRow.value.show) {
    const clientContainer = e.target.closest('.product-input-container');
    const searchDropdown = e.target.closest('.search-dropdown');
    
    if (!clientContainer && !searchDropdown) {
      const activeRowIndex = clientSearchForRow.value.activeRowIndex;
      if (activeRowIndex !== -1) {
        hideClientSearchList(activeRowIndex);
      }
    }
  }
  
  // 제품 검색 드롭다운 처리
  if (isProductSearchOpen.value) {
    const productContainer = e.target.closest('.product-input-container');
    const searchDropdown = e.target.closest('.search-dropdown');
    
    if (!productContainer && !searchDropdown) {
      const activeRowIndex = productSearchForRow.value.activeRowIndex;
      if (activeRowIndex !== -1) {
        hideProductSearchList(activeRowIndex);
      }
    }
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

// 테이블 너비 동기화 함수
function syncTableWidths() {
  nextTick(() => {
    const mainTable = document.querySelector('.table-scroll-wrapper .input-table');
    const footerTable = document.querySelector('.footer-table');
    
    if (mainTable && footerTable) {
      // 메인 테이블의 실제 너비를 합계 테이블에 적용
      const mainTableWidth = mainTable.offsetWidth;
      footerTable.style.width = `${mainTableWidth}px`;
      
      // 각 컬럼의 실제 너비를 가져와서 합계 테이블에 적용
      const mainHeaders = mainTable.querySelectorAll('thead th');
      const footerCells = footerTable.querySelectorAll('tfoot td');
      
      mainHeaders.forEach((header, index) => {
        if (footerCells[index]) {
          footerCells[index].style.width = `${header.offsetWidth}px`;
        }
      });
    }
  });
}

// 라이프사이클
onMounted(async () => {
  try {
    console.log('컴포넌트 마운트 시작');
    
    // 1. 사용자 정보 먼저 로드
    await fetchUserInfo();
    console.log('사용자 정보 로드 완료:', { userType: userType.value, companyId: currentUserCompanyId.value });
    
    // 2. 기본 데이터들 병렬로 로드
    await Promise.all([
      fetchAvailableMonths(),
      fetchHospitals(),
      fetchProducts()
    ]);
    console.log('기본 데이터 로드 완료');
    
    // 3. 기본 정산월 설정
    await setDefaultSettlementMonth();
    console.log('기본 정산월 설정 완료:', selectedSettlementMonth.value);
    
    // 4. 전역 키보드 이벤트 리스너 추가
    document.addEventListener('keydown', handleGlobalKeydown);
    document.addEventListener('click', handleGlobalClick);
    
    // 5. 테이블 너비 동기화
    syncTableWidths();
    
    // 6. 윈도우 리사이즈 시에도 너비 동기화
    window.addEventListener('resize', syncTableWidths);
    
    console.log('컴포넌트 마운트 완료');
  } catch (err) {
    console.error('컴포넌트 마운트 오류:', err);
  }
});

// 컴포넌트 언마운트 시 이벤트 리스너 제거
onUnmounted(() => {
  document.removeEventListener('keydown', handleGlobalKeydown);
  document.removeEventListener('click', handleGlobalClick);
  window.removeEventListener('resize', syncTableWidths);
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
  if (!selectedSettlementMonth.value) {
    displayRows.value = [];
    performanceRecords.value = [];
    originalData.value = [];
    return;
  }
  
  // prescriptionOffset이 0이면 전체 처방월 조회
  if (prescriptionOffset.value !== 0 && !prescriptionMonth.value) {
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
      .eq('settlement_month', selectedSettlementMonth.value);
    
    // 처방월 필터링 (0이 아닐 때만)
    if (prescriptionOffset.value !== 0) {
      query = query.eq('prescription_month', prescriptionMonth.value);
    }
    
    // 사용자 타입에 따른 필터링
    if (userType.value === 'user' && currentUserCompanyId.value) {
      query = query.eq('company_id', currentUserCompanyId.value);
    }
    
    // 병원 필터링
    if (selectedHospitalId.value) {
      query = query.eq('client_id', selectedHospitalId.value);
    }
    
    const { data, error } = await query.order('prescription_month', { ascending: false }).order('created_at', { ascending: true });
    
    if (error) {
      console.error('실적 조회 오류:', error);
      // 오류가 발생해도 빈 배열로 초기화
      performanceRecords.value = [];
      displayRows.value = [];
      originalData.value = [];
      return;
    }
    
    performanceRecords.value = data || [];
    
    // 화면 표시용 데이터 변환
    let transformedData = [];
    
    if (performanceRecords.value.length > 0) {
      transformedData = performanceRecords.value.map(record => ({
        id: record.id,
        product_name_display: record.products?.product_name || '',
        product_id: record.product_id,
        insurance_code: record.products?.insurance_code || '',
        price: record.products?.price ? Number(record.products.price).toLocaleString() : '',
        prescription_qty: record.prescription_qty,
        prescription_amount: record.products?.price ? (record.prescription_qty * record.products.price).toLocaleString() : '',
        prescription_type: record.prescription_type,
        client_name: record.clients?.name || '',
        prescription_month: record.prescription_month,
        remarks: record.remarks || ''
      }));
    }
    
    displayRows.value = transformedData;
    originalData.value = JSON.parse(JSON.stringify(transformedData));
    
    // 변경사항 플래그 명시적으로 초기화
    hasChanges.value = false;
    
    console.log('실적 데이터 로드 완료:', {
      recordsCount: performanceRecords.value.length,
      displayRowsCount: displayRows.value.length,
      hasChanges: hasChanges.value,
      isEditMode: isEditMode.value,
      prescriptionOffset: prescriptionOffset.value
    });
    
  } catch (err) {
    console.error('실적 조회 예외:', err);
    // 예외 발생 시에도 빈 배열로 초기화
    performanceRecords.value = [];
    displayRows.value = [];
    originalData.value = [];
    hasChanges.value = false;
  }
}

// 저장 함수
async function onSave() {
  if (!isEditMode.value || !hasChanges.value) return;
  
  try {
    // 유효한 행들만 필터링 (제품과 수량이 모두 입력된 행)
    const validRows = displayRows.value.filter(row => row.product_id && row.prescription_qty);
    
    if (validRows.length === 0) {
      alert('저장할 데이터가 없습니다.');
      return;
    }
    
    // 거래처가 선택되지 않은 행이 있는지 확인
    const rowsWithoutClient = validRows.filter(row => !row.client_name);
    if (rowsWithoutClient.length > 0) {
      alert('모든 행에 거래처를 선택해주세요.');
      return;
    }
    
    // 현재 사용자 정보 가져오기
    const { data: { session } } = await supabase.auth.getSession();
    if (!session?.user) {
      alert('로그인이 필요합니다.');
      return;
    }
    
    const { data: company } = await supabase
      .from('companies')
      .select('id')
      .eq('user_id', session.user.id)
      .single();
      
    if (!company) {
      alert('회사 정보를 찾을 수 없습니다.');
      return;
    }
    
    // 기존 데이터 삭제 (현재 조건에 맞는 데이터만)
    let deleteQuery = supabase
      .from('performance_records')
      .delete()
      .eq('company_id', company.id)
      .eq('settlement_month', selectedSettlementMonth.value)
      .eq('prescription_month', prescriptionMonth.value);
    
    // 병원이 선택된 경우 해당 병원 데이터만 삭제
    if (selectedHospitalId.value) {
      deleteQuery = deleteQuery.eq('client_id', selectedHospitalId.value);
    }
    
    const { error: deleteError } = await deleteQuery;
    
    if (deleteError) {
      console.error('기존 데이터 삭제 오류:', deleteError);
      throw new Error('기존 데이터 삭제 실패: ' + deleteError.message);
    }
    
    // 새 데이터 저장을 위한 준비
    const savePromises = [];
    
    for (const row of validRows) {
      // 거래처 ID 찾기
      const client = hospitals.value.find(h => h.name === row.client_name);
      if (!client) {
        throw new Error(`거래처 '${row.client_name}'을 찾을 수 없습니다.`);
      }
      
      const saveData = {
        company_id: company.id,
        settlement_month: selectedSettlementMonth.value,
        prescription_month: prescriptionMonth.value,
        client_id: client.id,
        product_id: row.product_id,
        prescription_qty: parseInt(row.prescription_qty.toString().replace(/,/g, '')),
        prescription_type: row.prescription_type,
        remarks: row.remarks || null,
        registered_by: session.user.id
      };
      
      savePromises.push(
        supabase.from('performance_records').insert(saveData)
      );
    }
    
    // 모든 데이터 저장
    const results = await Promise.all(savePromises);
    
    // 저장 결과 확인
    for (const result of results) {
      if (result.error) {
        console.error('데이터 저장 오류:', result.error);
        throw new Error('데이터 저장 실패: ' + result.error.message);
      }
    }
    
    alert('저장되었습니다.');
    
    // 데이터 다시 로드하여 원본 데이터 갱신
    await fetchPerformanceRecords();
    
    // 변경사항 플래그 명시적으로 초기화
    hasChanges.value = false;
    
  } catch (err) {
    console.error('저장 오류:', err);
    alert('저장 중 오류가 발생했습니다: ' + err.message);
  }
}

function downloadExcel() {
  if (sortedDisplayRows.value.length === 0) {
    alert('다운로드할 데이터가 없습니다.');
    return;
  }

  // 엑셀 데이터 준비 - 숫자 필드는 실제 숫자값으로 변환
  const excelData = sortedDisplayRows.value.map((row, index) => ({
    'No': index + 1,
    '거래처': row.client_name || '',
    '처방월': row.prescription_month || '',
    '제품명': row.product_name_display || '',
    '보험코드': row.insurance_code || '',
    '약가': row.price ? Number(row.price.toString().replace(/,/g, '')) : 0,
    '처방수량': row.prescription_qty ? Number(row.prescription_qty.toString().replace(/,/g, '')) : 0,
    '처방액': row.prescription_amount ? Number(row.prescription_amount.toString().replace(/,/g, '')) : 0,
    '처방구분': row.prescription_type || '',
    '비고': row.remarks || ''
  }));

  // 합계 행 추가 - 숫자값으로 계산
  const totalQtyNum = excelData.reduce((sum, row) => sum + (row['처방수량'] || 0), 0);
  const totalAmountNum = excelData.reduce((sum, row) => sum + (row['처방액'] || 0), 0);
  
  excelData.push({
    'No': '',
    '거래처': '',
    '처방월': '',
    '제품명': '',
    '보험코드': '',
    '약가': '합계',
    '처방수량': totalQtyNum,
    '처방액': totalAmountNum,
    '처방구분': '',
    '비고': ''
  });

  // 워크북 생성
  const wb = XLSX.utils.book_new();
  const ws = XLSX.utils.json_to_sheet(excelData);

  // 컬럼 너비 설정
  const colWidths = [
    { wch: 5 },   // No
    { wch: 20 },  // 거래처
    { wch: 10 },  // 처방월
    { wch: 30 },  // 제품명
    { wch: 12 },  // 보험코드
    { wch: 12 },  // 약가
    { wch: 12 },  // 처방수량
    { wch: 15 },  // 처방액
    { wch: 12 },  // 처방구분
    { wch: 20 }   // 비고
  ];
  ws['!cols'] = colWidths;

  // 숫자 형식 설정 (천단위 구분자 적용)
  const range = XLSX.utils.decode_range(ws['!ref']);
  
  for (let R = range.s.r + 1; R <= range.e.r; R++) { // 헤더 제외하고 시작
    // 약가 컬럼 (F열, 인덱스 5)
    const priceCell = XLSX.utils.encode_cell({ r: R, c: 5 });
    if (ws[priceCell] && typeof ws[priceCell].v === 'number') {
      ws[priceCell].z = '#,##0';
    }
    
    // 처방수량 컬럼 (G열, 인덱스 6)
    const qtyCell = XLSX.utils.encode_cell({ r: R, c: 6 });
    if (ws[qtyCell] && typeof ws[qtyCell].v === 'number') {
      ws[qtyCell].z = '#,##0';
    }
    
    // 처방액 컬럼 (H열, 인덱스 7)
    const amountCell = XLSX.utils.encode_cell({ r: R, c: 7 });
    if (ws[amountCell] && typeof ws[amountCell].v === 'number') {
      ws[amountCell].z = '#,##0';
    }
  }

  // 워크시트를 워크북에 추가
  XLSX.utils.book_append_sheet(wb, ws, '실적 등록 현황');

  // 파일명 생성 (정산월_처방월_병원명_날짜)
  const today = new Date();
  const dateStr = today.toISOString().slice(0, 10).replace(/-/g, '');
  
  let fileName = '실적등록현황';
  if (selectedSettlementMonth.value) {
    fileName += `_${selectedSettlementMonth.value}`;
  }
  if (prescriptionMonth.value && prescriptionOffset.value !== 0) {
    fileName += `_${prescriptionMonth.value}`;
  }
  if (selectedHospitalInfo.value) {
    fileName += `_${selectedHospitalInfo.value.name}`;
  }
  fileName += `_${dateStr}.xlsx`;

  // 파일 다운로드
  XLSX.writeFile(wb, fileName);
}

// 새 행 추가 함수
function addNewRow() {
  if (!isEditMode.value || !selectedSettlementMonth.value || prescriptionOffset.value === 0) return;
  
  const clientName = selectedHospitalId.value && selectedHospitalInfo.value ? selectedHospitalInfo.value.name : '';
  const newRow = {
    id: null,
    product_name_display: '',
    product_id: null,
    insurance_code: '',
    price: '',
    prescription_qty: '',
    prescription_amount: '',
    prescription_type: 'EDI',
    client_name: clientName,
    prescription_month: prescriptionMonth.value,
    remarks: ''
  };
  
  displayRows.value.push(newRow);
  
  // 새 행의 첫 번째 필드에 포커스
  nextTick(() => {
    focusField(displayRows.value.length - 1, 'client_name');
  });
}
</script> 