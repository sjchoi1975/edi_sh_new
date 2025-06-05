<template>
  <div class="performance-register-view">
    <div class="header-title">실적 등록</div>
    <!-- 선택된 정산월 병원 정보를 상단에 고정 표시 -->
    <div class="filter-card" style="display:flex; align-items:center; margin-bottom:1rem; padding:0.5rem 1rem;">
      <div>
        <div style="font-size:1.0rem; color:#555; font-weight:500; margin-bottom:-0.1rem;">정산월 : {{ selectedSettlementMonth }}</div>
        <div style="font-size:1.2rem; font-weight:700;">{{ route.query.clientName }}</div>
        <div style="font-size:0.95rem; color:#555;">
          {{ route.query.businessRegistrationNumber }} / {{ route.query.address }}
        </div>
      </div>
    </div>
    <div class="data-card">
      <div class="data-card-header">
        <div class="total-count-display">전체 {{ totalCount }} 건</div>
        <div class="data-card-buttons">
          <button 
            class="btn-secondary" 
            @click="downloadExcelTemplate" 
            :disabled="!selectedSettlementMonth"
          >템플릿 다운로드</button>
          <button 
            class="btn-secondary" 
            @click="triggerExcelUpload" 
            :disabled="!selectedSettlementMonth"
          >엑셀 일괄등록</button>
          <input 
            ref="excelFileInput"
            type="file" 
            accept=".xlsx,.xls" 
            @change="handleExcelUpload"
            style="display: none;"
          />
          <button 
            class="btn-primary" 
            @click="onSave" 
            :disabled="!canSave"
          >저장</button>
        </div>
      </div>
      <div class="input-table-wrapper performance-edit-table">
        <!-- 실적 입력 테이블 - 헤더와 바디 분리 -->
        <div class="table-header-fixed">
          <table>
            <thead>
              <tr>
                <th style="width:5%;">No</th>
                <th style="width:10%;">처방월</th>
                <th style="width:20%;">제품명</th>
                <th style="width:9%;">보험코드</th>
                <th style="width:9%;">단가</th>
                <th style="width:9%;">처방수량</th>
                <th style="width:10%;">처방액</th>
                <th style="width:10%;">처방구분</th>
                <th style="width:14%;">비고</th>
                <th style="width:6%;">삭제</th>
                <th style="width:6%;">추가</th>
              </tr>
            </thead>
          </table>
        </div>
        
        <div class="table-body-scroll">
          <table class="input-table prime-like-table">
            <tbody>
              <tr v-for="(row, rowIdx) in inputRows" :key="rowIdx">
                <td style="text-align:center; width:5%;">{{ rowIdx + 1 }}</td>
                <td style="width:12%;">
                  <select v-model="row.prescription_month" :tabindex="isInputEnabled ? 0 : -1" :disabled="!isInputEnabled" style="width:100%;"
                    @change="onPrescriptionMonthChange(rowIdx)">
                    <option v-for="opt in getPrescriptionMonthOptions()" :key="opt" :value="opt">{{ opt }}</option>
                  </select>
                </td>
                <td style="position:relative;text-align:left; width:18%;">
                  <div class="product-input-container">
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
                      :ref="el => setProductInputRef(rowIdx, el)"
                    />
                    <button 
                      type="button"
                      @click="toggleProductDropdown(rowIdx, $event)"
                      @mousedown.prevent
                      class="dropdown-arrow-btn"
                      tabindex="-1"
                      :disabled="!isInputEnabled"
                    >
                      <span class="dropdown-arrow">▼</span>
                    </button>
                  </div>
                  <teleport to="body">
                    <div v-if="productSearchForRow.show && productSearchForRow.activeRowIndex === rowIdx && productSearchForRow.results.length > 0"
                      class="search-dropdown product-search-dropdown"
                      :style="productDropdownStyle[rowIdx]"
                    >
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
                  </teleport>
                </td>
                <td style="text-align:center; width:9%;">
                  <span class="readonly-span">{{ row.insurance_code }}</span>
                </td>
                <td style="text-align:right; width:9%;">
                  <span class="readonly-span">{{ row.price }}</span>
                </td>
                <td style="text-align:right; position:relative; width:9%;">
                  <input
                    v-model="row.prescription_qty"
                    :tabindex="isInputEnabled ? 0 : -1"
                    :readonly="!isInputEnabled"
                    @keydown.enter.prevent="addOrFocusNextRow(rowIdx)"
                    @keydown="onArrowKey($event, rowIdx, 'prescription_qty')"
                    @input="onQtyInput(rowIdx)"
                    @focus="handlePrescriptionQtyFocus(rowIdx)"
                    @blur="row.prescription_qty = row.prescription_qty ? Number(row.prescription_qty.toString().replace(/,/g, '')).toLocaleString() : ''"
                    :disabled="!isInputEnabled"
                    :class="[
                      cellClass(rowIdx, 'prescription_qty'),
                      { 'disabled-area': !isInputEnabled }
                    ]"
                    style="text-align:right;"
                    :ref="el => setQtyInputRef(rowIdx, el)"
                  />
                </td>
                <td style="text-align:right; width:10%;">
                  <span class="readonly-span">{{ row.prescription_amount }}</span>
                </td>
                <td style="text-align:center; width:10%;">
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
                <td style="text-align:left; width:14%;">
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
                <td class="action-cell" style="width:6%;">
                  <button 
                    class="btn-delete-m" 
                    @click="confirmDeleteRow(rowIdx)" 
                    :disabled="inputRows.length === 1 || !isInputEnabled" 
                    title="삭제"
                    :class="{ 'disabled-area': !isInputEnabled }"
                  >✕</button>
                </td>
                <td class="action-cell" style="width:6%;">
                  <button 
                    class="btn-add-m" 
                    @click="confirmAddRowBelow(rowIdx)" 
                    title="추가"
                    :disabled="!isInputEnabled"
                    :class="{ 'disabled-area': !isInputEnabled }"
                  >＋</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
      <!-- 합계 행을 하단 고정 -->
      <div class="table-footer-wrapper"
      style="width:100%;
        background:#f8f9fa;
        height: 38px;
        border:1px solid #dee2e6;
        border-bottom:2px solid #aaa;
        position:sticky;
        bottom:0;
        z-index:2;">
        <table style="width:100%; table-layout:fixed;">
          <tr>
            <td style="width:5%;"></td>
            <td style="width:22%; text-align:center;font-weight:bold;">합계</td>
            <td style="width:9%;"></td>
            <td style="width:9%;"></td>
            <td style="width:9%; text-align:right;font-weight:bold;">{{ totalQty }}</td>
            <td style="width:10%; text-align:right;font-weight:bold;">{{ totalAmount }}</td>
            <td style="width:10%;"></td>
            <td style="width:14%;"></td>
            <td style="width:6%;"></td>
            <td style="width:6%;"></td>
          </tr>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, nextTick, onUnmounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { supabase } from '@/supabase';
import * as XLSX from 'xlsx';

const route = useRoute();
const router = useRouter();

// 정산월 정보를 이전 화면에서 전달받음
const selectedSettlementMonth = ref(route.params.settlementMonth || route.query.settlementMonth || '');

// 처방월 옵션을 설정
const prescriptionOffset = ref(1); // 1: -1M, 2: -2M, 3: -3M
const prescriptionMonth = ref('');
const prescriptionOptions = ref([]);

// 실적 입력행들 (최소 1행은 유지)
const inputRows = ref([{ 
  product_name_display: '', 
  product_id: null, 
  insurance_code: '', 
  price: '', 
  prescription_qty: '', 
  prescription_amount: '', 
  prescription_type: 'EDI', 
  remarks: '',
  prescription_month: getDefaultPrescriptionMonth()
}]);

const isInputEnabled = true;
const canSave = computed(() => {
  return inputRows.value.filter(row => row.product_name_display && row.prescription_qty && !isNaN(Number(row.prescription_qty)) && Number(row.prescription_qty) > 0).length > 0;
});

const currentCell = ref({ row: 0, col: 'product_name' });

const prescriptionTypeOptions = [
  'EDI',
  '대한조제',
  '의료매출',
  '직거래매입',
  '차감',
  '원내매출',
  '원외매출',
];

const products = ref([]);
const productSearchForRow = ref({
  query: '',
  results: [],
  selectedIndex: -1,
  show: false,
  activeRowIndex: -1,
});

const productInputRefs = ref({});
const productDropdownStyle = ref({});
const qtyInputRefs = ref({});

function setProductInputRef(rowIdx, el) {
  if (el) productInputRefs.value[rowIdx] = el;
}

function setQtyInputRef(rowIdx, el) {
  if (el) qtyInputRefs.value[rowIdx] = el;
}

function updateProductDropdownPosition(rowIdx) {
  nextTick(() => {
    const el = productInputRefs.value[rowIdx];
    if (!el) return;
    const rect = el.getBoundingClientRect();
    
    // 화면 높이와 드롭다운 높이 계산
    const windowHeight = window.innerHeight;
    const dropdownHeight = 220; // 드롭다운 예상 높이
    const spaceBelow = windowHeight - rect.bottom;
    const spaceAbove = rect.top;
    
    // 아래쪽 공간이 부족하고 위쪽 공간이 충분하면 위로 표시
    const showAbove = spaceBelow < dropdownHeight && spaceAbove > dropdownHeight;
    
    productDropdownStyle.value[rowIdx] = {
      position: 'fixed',
      left: rect.left + 'px',
      top: showAbove ? (rect.top - dropdownHeight) + 'px' : rect.bottom + 'px',
      width: rect.width + 'px',
      zIndex: 9999,
      maxHeight: showAbove ? Math.min(dropdownHeight, spaceAbove - 10) + 'px' : Math.min(dropdownHeight, spaceBelow - 10) + 'px',
      overflowY: 'auto',
    };
  });
}

watch(() => productSearchForRow.value.activeRowIndex, (rowIdx) => {
  if (productSearchForRow.value.show && rowIdx !== -1) {
    updateProductDropdownPosition(rowIdx);
  }
});

watch(() => productSearchForRow.value.show, (show) => {
  if (show && productSearchForRow.value.activeRowIndex !== -1) {
    updateProductDropdownPosition(productSearchForRow.value.activeRowIndex);
  }
});

watch(inputRows, () => {
  if (productSearchForRow.value.show && productSearchForRow.value.activeRowIndex !== -1) {
    updateProductDropdownPosition(productSearchForRow.value.activeRowIndex);
  }
}, { deep: true });

window.addEventListener('scroll', () => {
  const rowIdx = productSearchForRow.value.activeRowIndex;
  if (productSearchForRow.value.show && rowIdx !== -1) {
    updateProductDropdownPosition(rowIdx);
  }
}, true);

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
  if (!selectedSettlementMonth.value) {
    prescriptionOptions.value = [];
    return;
  }
  prescriptionOptions.value = [1, 2, 3].map(offset => ({
    value: offset,
    month: getPrescriptionMonth(selectedSettlementMonth.value, offset)
  }));
}

watch(selectedSettlementMonth, () => {
  if (selectedSettlementMonth.value) {
    updatePrescriptionOptions();
    prescriptionOffset.value = 1;
    prescriptionMonth.value = getPrescriptionMonth(selectedSettlementMonth.value, 1);
  }
}, { immediate: true });

watch(prescriptionOffset, (val) => {
  prescriptionMonth.value = getPrescriptionMonth(selectedSettlementMonth.value, val);
});

async function fetchProducts() {
  if (!prescriptionMonth.value) {
    products.value = [];
    return;
  }
  const { data, error } = await supabase
    .from('products')
    .select('*')
    .eq('base_month', prescriptionMonth.value)
    .eq('status', 'active');
  if (!error && data) {
    // 보험코드별로 하나씩만 남기기 (가장 먼저 나오는 것)
    const uniqueByInsuranceCode = [];
    const seen = new Set();
    for (const item of data) {
      if (!seen.has(item.insurance_code)) {
        uniqueByInsuranceCode.push(item);
        seen.add(item.insurance_code);
      }
    }
    products.value = uniqueByInsuranceCode;
  } else {
    products.value = [];
  }
}

// 처방월이 바뀔 때마다 제품 목록 재조회
watch(prescriptionMonth, async (newMonth) => {
  await fetchProducts();
});

// 제품 검색 관련 함수들
async function searchProductsForRow(rowIdx, query) {
  console.log('searchProductsForRow 호출', rowIdx, inputRows.value[rowIdx].prescription_month);
  const month = inputRows.value[rowIdx].prescription_month;
  if (!month) {
    productSearchForRow.value.results = [];
    productSearchForRow.value.show = false;
    return;
  }
  try {
    // 1. 반드시 base_month(처방월)로 먼저 필터
    let searchQuery = supabase
      .from('products')
      .select('*')
      .eq('base_month', month)
      .eq('status', 'active')
      .order('product_name');
    if (query && query.trim() !== '') {
      searchQuery = searchQuery.or(`product_name.ilike.%${query.trim()}%,insurance_code.ilike.%${query.trim()}%`);
    }
    const { data, error } = await searchQuery.limit(100);
    if (error) {
      console.error('제품 검색 오류:', error);
      productSearchForRow.value.results = [];
      productSearchForRow.value.show = false;
      return;
    }
    // 2. 쿼리 결과(해당 월의 제품만)에서 보험코드별로 1개만 남김
    const unique = [];
    const seen = new Set();
    for (const item of (data || [])) {
      if (!seen.has(item.insurance_code)) {
        unique.push(item);
        seen.add(item.insurance_code);
      }
    }
    // 3. 드롭다운에는 이 결과만 보여줌
    productSearchForRow.value.results = unique;
    productSearchForRow.value.show = true;
  } catch (err) {
    console.error('제품 검색 예외:', err);
    productSearchForRow.value.results = [];
    productSearchForRow.value.show = false;
  }
}

function handleProductNameInput(rowIdx, event) {
  if (!isInputEnabled) return;
  const query = event.target.value.toLowerCase();
  inputRows.value[rowIdx].product_name_display = event.target.value;
  inputRows.value[rowIdx].product_id = null;
  inputRows.value[rowIdx].insurance_code = '';
  inputRows.value[rowIdx].price = '';
  productSearchForRow.value.activeRowIndex = rowIdx;
  if (query.length < 1) {
    productSearchForRow.value.show = false;
    productSearchForRow.value.results = [];
    return;
  }
  searchProductsForRow(rowIdx, query);
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
  inputRows.value[rowIndex].price = product.price ? Number(product.price).toLocaleString() : '';
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

function clickProductFromSearchList(product, rowIdx) {
  const row = inputRows.value[rowIdx];
  row.product_name_display = product.product_name;
  row.product_id = product.id;
  row.insurance_code = product.insurance_code;
  row.price = Number(product.price).toLocaleString();
  productSearchForRow.value.show = false;
  recalculateRow && recalculateRow(rowIdx);
  markAsChanged && markAsChanged();
  // 자동 이동: 제품명 선택 시 처방수량으로
  nextTick(() => focusField(rowIdx, 'prescription_qty'));
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

function toggleProductDropdown(rowIdx, event) {
  searchProductsForRow(rowIdx, '');
  productSearchForRow.value.activeRowIndex = rowIdx;
  if (event && event.target) {
    const inputElement = event.target.closest('.product-input-container').querySelector('input');
    if (inputElement) {
      productSearchForRow.value.position = calculateDropdownPosition(inputElement);
    }
  }
  productSearchForRow.value.show = true;
}

// 제품 검색 드롭다운이 열려있는지 확인하는 computed
const isProductSearchOpen = computed(() => {
  return productSearchForRow.value.show && productSearchForRow.value.activeRowIndex !== -1;
});

// 제품명 필드 포커스 핸들러
function handleProductNameFocus(rowIdx) {
  if (!isInputEnabled) {
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
  if (!isInputEnabled) {
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
  if (!isInputEnabled) {
    event.target.blur();
    return;
  }
  
  // 제품 검색 드롭다운이 열려있으면 포커스 차단
  if (isProductSearchOpen.value) {
    event.target.blur();
    return;
  }
  
  // 포커스시 콤마 제거
  inputRows.value[rowIdx].prescription_qty = inputRows.value[rowIdx].prescription_qty ? inputRows.value[rowIdx].prescription_qty.toString().replace(/,/g, '') : '';
  
  currentCell.value = { row: rowIdx, col: 'prescription_qty' };
}

// 테이블 네비게이션 함수들
function focusField(rowIdx, col) {
  let el = null;
  if (col === 'product_name') {
    el = productInputRefs.value[rowIdx];
  } else if (col === 'prescription_qty') {
    el = qtyInputRefs.value[rowIdx];
  } else if (col === 'prescription_type') {
    el = prescriptionTypeSelectRefs.value[rowIdx];
  } else if (col === 'remarks') {
    el = remarksInputRefs.value[rowIdx];
  }
  if (el && typeof el.focus === 'function') {
    el.focus();
    console.log('포커스됨', rowIdx, col);
  } else {
    console.log('ref 없음', rowIdx, col, el);
  }
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
    // 제품명과 수량이 모두 입력되어 있어야만 다음행 생성
    if (!currentRow.product_id || !currentRow.prescription_qty) {
      return;
    }
    
    // 마지막 행이면 새 행 추가
    if (rowIdx === inputRows.value.length - 1) {
      inputRows.value.push(createEmptyRow());
    }
    // 다음 행의 제품명으로 이동
    focusField(rowIdx + 1, 'product_name');
  }
  
  // 비고 입력 중일 때
  if (currentCell.value.col === 'remarks') {
    // 제품명과 수량이 모두 입력되어 있어야만 다음행 생성
    if (!currentRow.product_id || !currentRow.prescription_qty) {
      return;
    }
    
    // 마지막 행이면 새 행 추가
    if (rowIdx === inputRows.value.length - 1) {
      inputRows.value.push(createEmptyRow());
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
    // 아래 화살표시 제품명과 수량이 모두 입력된 상태에서 마지막 행이면 새행 생성
    const currentRow = inputRows.value[currentCell.value.row];
    if (currentRow.product_id && currentRow.prescription_qty && currentCell.value.row === inputRows.value.length - 1) {
      inputRows.value.push(createEmptyRow());
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
  nextTick(() => {
    if (rowIdx + 1 < inputRows.value.length) {
      focusField(rowIdx + 1, 'product_name');
    }
  });
}

function onArrowKey(e, rowIdx, col) {
  const cols = ['prescription_month', 'product_name', 'prescription_qty', 'prescription_type', 'remarks'];
  let currentColIdx = cols.indexOf(col);
  let newRow = rowIdx;
  let newColIdx = currentColIdx;
  if (e.key === 'Enter') {
    if (col === 'product_name') {
      newColIdx = 2; // 처방수량
    } else if (col === 'prescription_qty') {
      newRow = Math.min(inputRows.value.length - 1, rowIdx + 1);
      newColIdx = 1; // 다음행 제품명
    }
  } else if (e.key === 'ArrowUp') {
    newRow = Math.max(0, rowIdx - 1);
  } else if (e.key === 'ArrowDown') {
    newRow = Math.min(inputRows.value.length - 1, rowIdx + 1);
  } else if (e.key === 'ArrowLeft') {
    newColIdx = Math.max(0, currentColIdx - 1);
  } else if (e.key === 'ArrowRight') {
    newColIdx = Math.min(cols.length - 1, currentColIdx + 1);
  }
  currentCell.value = { row: newRow, col: cols[newColIdx] };
  nextTick(() => focusField(newRow, cols[newColIdx]));
}

function cellClass(rowIdx, col) {
  return currentCell.value.row === rowIdx && currentCell.value.col === col ? 'cell-focused' : '';
}

// 실적 저장로직 - 기존 데이터를 삭제 후 새로 저장
async function savePerformanceData() {
  // clientId와 settlementMonth를 query에서 찾음
  const clientId = route.query.clientId;
  const settlementMonth = route.query.settlementMonth;
  
  if (!settlementMonth || !clientId) {
    throw new Error('정산월이나 병원이 선택되지 않았습니다.');
  }

  // 1. 행 분류
  const completeRows = [];
  inputRows.value.forEach((row, index) => {
    const hasProduct = !!row.product_id;
    const hasQty = !!row.prescription_qty;

    if (hasProduct && hasQty) {
      completeRows.push({ ...row, rowNumber: index + 1 });
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

  // 5. 기존 데이터 삭제 (해당 정산월 병원의 모든 실적)
  await supabase
    .from('performance_records')
    .delete()
    .eq('company_id', myCompany.id)
    .eq('settlement_month', settlementMonth)
    .eq('client_id', Number(clientId));

  // 6. 새로운 데이터 준비
  const performanceData = completeRows.map(row => ({
    company_id: myCompany.id,
    settlement_month: settlementMonth,
    prescription_month: row.prescription_month || prescriptionMonth.value,
    client_id: Number(clientId),
    product_id: row.product_id,
    prescription_qty: parseInt(row.prescription_qty.toString().replace(/,/g, '')),
    prescription_type: row.prescription_type || 'EDI',
    remarks: row.remarks || null,
    registered_by: userUid
  }));

  // 7. 새로운 데이터 저장
  const { error } = await supabase
    .from('performance_records')
    .insert(performanceData);

  if (error) {
    throw new Error('실적 저장시 오류가 발생했습니다.');
  }

  return completeRows.length;
}

// 저장 버튼 클릭 핸들러 (기존 데이터 삭제 후 새로 저장)
async function onSave() {
  if (isProductSearchOpen.value) {
    return;
  }
  const clientId = route.query.clientId;
  const settlementMonth = route.query.settlementMonth;
  if (!settlementMonth || !clientId) {
    alert('정산월이나 병원이 선택되지 않았습니다.');
    return;
  }
  // 1. 행 분류 (부족한 정보 확인)
  const partialRows = [];
  inputRows.value.forEach((row, index) => {
    const hasProduct = !!row.product_id;
    const hasQty = !!row.prescription_qty;
    if ((hasProduct || hasQty) && !(hasProduct && hasQty)) {
      partialRows.push({ ...row, rowNumber: index + 1 });
    }
  });
  if (partialRows.length > 0) {
    const partialRowNumbers = partialRows.map(row => `No ${row.rowNumber}`).join(', ');
    const message = `${partialRows.length}건의 실적이 필수 정보(제품, 처방수량)가 누락되었습니다.\n${partialRowNumbers}\n제외하고 저장하시겠습니까?`;
    if (!confirm(message)) {
      return;
    }
  }
  try {
    // 3. 저장 처리 (기존 데이터 삭제 후 새로 저장)
    const savedCount = await savePerformanceData();
    // 4. 성공 메시지
    alert(`총 ${savedCount}건이 등록되었습니다.`);
    // 5. 저장 후 실적 목록 화면으로 이동
    router.push('/performance/register');
  } catch (err) {
    console.error('저장 처리 오류:', err);
    alert(err.message || '실적 저장 시 오류가 발생했습니다.');
  }
}

// 기존 실적 데이터 불러오기
async function loadExistingData() {
  const clientId = route.query.clientId;
  const settlementMonth = route.query.settlementMonth;
  
  if (!clientId || !settlementMonth) return;
  
  try {
    // 현재 사용자의 회사 ID 가져오기
    const { data: { session } } = await supabase.auth.getSession();
    const userUid = session?.user?.id;
    if (!userUid) return;

    const { data: myCompany } = await supabase.from('companies').select('id').eq('user_id', userUid).single();
    if (!myCompany) return;

    // 기존 실적 데이터 조회 (products 테이블과 조인)
    const { data, error } = await supabase
      .from('performance_records')
      .select(`
        *,
        products (
          id,
          product_name,
          insurance_code,
          price
        )
      `)
      .eq('company_id', myCompany.id)
      .eq('settlement_month', settlementMonth)
      .eq('client_id', clientId);

    if (error) {
      console.error('기존 실적 조회 오류:', error);
      return;
    }

    if (data && data.length > 0) {
      // 기존 데이터를 inputRows에 설정
      inputRows.value = data.map(record => ({
        product_name_display: record.products?.product_name || '',
        product_id: record.product_id,
        insurance_code: record.products?.insurance_code || '',
        price: record.products?.price ? Number(record.products.price).toLocaleString() : '',
        prescription_qty: record.prescription_qty ? Number(record.prescription_qty).toLocaleString() : '',
        prescription_amount: record.prescription_qty && record.products?.price 
          ? (record.prescription_qty * record.products.price).toLocaleString() 
          : '',
        prescription_type: record.prescription_type || 'EDI',
        remarks: record.remarks || '',
        prescription_month: record.prescription_month || getDefaultPrescriptionMonth()
      }));

      // 처방월도 기존 데이터에서 가져오기
      if (data[0].prescription_month) {
        const prescMonth = data[0].prescription_month;
        const settlementDate = new Date(settlementMonth + '-01');
        const prescDate = new Date(prescMonth + '-01');
        const monthDiff = (settlementDate.getFullYear() - prescDate.getFullYear()) * 12 + 
          (settlementDate.getMonth() - prescDate.getMonth());
        if (monthDiff >= 1 && monthDiff <= 3) {
          prescriptionOffset.value = monthDiff;
        }
      }

      // 마지막에 빈 행 하나 추가
      inputRows.value.push(createEmptyRow());
    }
  } catch (err) {
    console.error('기존 실적 로드 오류:', err);
  }
}

// 합계 계산
const totalQty = computed(() => {
  const total = inputRows.value.reduce((sum, row) => {
    const qty = Number(row.prescription_qty.toString().replace(/,/g, '')) || 0;
    return sum + qty;
  }, 0);
  return total.toLocaleString();
});

const totalAmount = computed(() => {
  return inputRows.value.reduce((sum, row) => sum + (Number(row.prescription_amount.toString().replace(/,/g, '')) || 0), 0).toLocaleString();
});

// 전체 건수 계산: 제품명과 처방수량 모두 값이 있는 행만 카운트
const totalCount = computed(() => {
  return inputRows.value.filter(row => row.product_name_display && row.prescription_qty && !isNaN(Number(row.prescription_qty)) && Number(row.prescription_qty) > 0).length;
});

// 행 추가/행 삭제
function addRowBelow(idx) {
  inputRows.value.splice(idx + 1, 0, createEmptyRow());
  nextTick(() => focusField(idx + 1, 'product_name'));
}

function deleteRow(idx) {
  if (inputRows.value.length === 1) return;
  inputRows.value.splice(idx, 1);
}

// 확인 다이얼로그를 브라우저 confirm으로 변경
function confirmDeleteRow(idx) {
  // 제품 검색 드롭다운이 열려있으면 차단
  if (isProductSearchOpen.value) {
    return;
  }
  
  if (confirm('선택한 행을 삭제하시겠습니까?')) {
    deleteRow(idx);
  }
}

function confirmAddRowBelow(idx) {
  // 제품 검색 드롭다운이 열려있으면 차단
  if (isProductSearchOpen.value) {
    return;
  }
  
  if (confirm('아래에 새 행을 추가하시겠습니까?')) {
    inputRows.value.splice(idx + 1, 0, createEmptyRow());
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

// 전역 클릭 이벤트 처리
function handleGlobalClick(e) {
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

// 라이프사이클
onMounted(async () => {
  if (selectedSettlementMonth.value) {
    updatePrescriptionOptions();
    prescriptionOffset.value = 1;
    prescriptionMonth.value = getPrescriptionMonth(selectedSettlementMonth.value, 1);
  }
  await fetchProducts();
  await loadExistingData(); // 기존 실적 데이터 불러오기
  
  // 마지막 행의 제품명에 포커스
  nextTick(() => {
    let focusIdx = 0;
    if (inputRows.value.length > 1) {
      focusIdx = inputRows.value.length - 1;
    }
    focusField(focusIdx, 'product_name');
  });
  
  document.addEventListener('keydown', handleGlobalKeydown);
  document.addEventListener('click', handleGlobalClick);
});

onUnmounted(() => {
  document.removeEventListener('keydown', handleGlobalKeydown);
  document.removeEventListener('click', handleGlobalClick);
});

// 엑셀 파일 입력 참조
const excelFileInput = ref(null);

// 엑셀 템플릿 다운로드
function downloadExcelTemplate() {
  if (!selectedSettlementMonth.value) {
    alert('정산월을 먼저 선택하세요.');
    return;
  }

  try {
    // 템플릿 헤더
    const headers = [
      '거래처_사업자등록번호',
      '처방월',
      '보험코드',
      '수량',
      '처방구분',
      '비고'
    ];

    // 샘플 데이터
    const sampleData = [
      [
        '123-45-67890',  // 거래처_사업자등록번호
        '2025-05',       // 처방월
        '654321098',     // 보험코드
        100,             // 수량
        'EDI',           // 처방구분
        '샘플 데이터'     // 비고
      ],
      [
        '111-22-33444',
        '2025-04',
        '123456789',
        50,
        '대한조제',
        ''
      ],
      [
        '',  // 빈 행들은 사용자가 입력할 수 있도록
        '',
        '',
        '',
        'EDI',
        ''
      ]
    ];

    // 워크북 생성
    const wb = XLSX.utils.book_new();
    
    // 템플릿 시트 생성
    const templateData = [headers, ...sampleData];
    const templateWs = XLSX.utils.aoa_to_sheet(templateData);
    
    // 컬럼 너비 설정
    const colWidths = [
      { wch: 18 },  // 거래처_사업자등록번호
      { wch: 12 },  // 처방월
      { wch: 15 },  // 보험코드
      { wch: 12 },  // 수량
      { wch: 12 },  // 처방구분
      { wch: 15 }   // 비고
    ];
    templateWs['!cols'] = colWidths;

    // 헤더 스타일 설정
    const headerStyle = {
      font: { bold: true, color: { rgb: "FFFFFF" } },
      fill: { fgColor: { rgb: "4472C4" } },
      alignment: { horizontal: "center", vertical: "center" }
    };

    for (let col = 0; col < headers.length; col++) {
      const cellRef = XLSX.utils.encode_cell({ r: 0, c: col });
      if (!templateWs[cellRef]) templateWs[cellRef] = {};
      templateWs[cellRef].s = headerStyle;
    }

    XLSX.utils.book_append_sheet(wb, templateWs, '일괄등록_템플릿');

    // 파일 다운로드
    const fileName = `실적등록_일괄등록_템플릿_${selectedSettlementMonth.value}.xlsx`;
    XLSX.writeFile(wb, fileName);

    alert('엑셀 템플릿이 다운로드되었습니다.');

  } catch (err) {
    console.error('템플릿 다운로드 오류:', err);
    alert('템플릿 다운로드 중 오류가 발생했습니다: ' + err.message);
  }
}

// 엑셀 일괄등록 트리거
function triggerExcelUpload() {
  if (!selectedSettlementMonth.value) {
    alert('정산월을 먼저 선택하세요.');
    return;
  }
  excelFileInput.value.click();
}

// 엑셀 업로드 핸들러
async function handleExcelUpload(event) {
  const file = event.target.files[0];
  if (!file) return;

  try {
    console.log('=== 엑셀 일괄등록 시작 ===');
    console.log('파일명:', file.name);
    console.log('파일 크기:', file.size);

    // 파일 읽기
    const arrayBuffer = await file.arrayBuffer();
    const workbook = XLSX.read(arrayBuffer, { type: 'array' });
    
    // 첫 번째 시트 선택
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];
    
    // 데이터 파싱 (header 1 사용)
    const jsonData = XLSX.utils.sheet_to_json(worksheet, { header: 1 });
    
    console.log('엑셀 데이터 행 수:', jsonData.length);
    
    if (jsonData.length < 2) {
      alert('엑셀 파일에 데이터가 없습니다.');
      return;
    }
    
    // 헤더 확인 (첫 번째 행)
    const headers = jsonData[0];
    console.log('엑셀 헤더:', headers);

    // 필수 컬럼 확인
    const requiredColumns = ['거래처_사업자등록번호', '처방월', '보험코드', '수량', '처방구분', '비고'];
    const missingColumns = requiredColumns.filter(col => !headers.includes(col));
    if (missingColumns.length > 0) {
      alert(`필수 컬럼이 누락되었습니다: ${missingColumns.join(', ')}`);
      return;
    }

    // 데이터 행들 (두 번째 행부터)
    const dataRows = jsonData.slice(1).filter(row => row && row.length > 0 && row[0]);
    
    console.log('유효한 데이터 행 수:', dataRows.length);
    
    if (dataRows.length === 0) {
      alert('처리할 유효한 데이터가 없습니다.');
      return;
    }
    
    // 엑셀 데이터 파싱 및 변환
    const parsedData = await parseExcelData(dataRows);
    
    console.log('파싱된 데이터:', parsedData.length, '건');
    
    if (parsedData.length === 0) {
      alert('엑셀 일괄등록 완료!\n\n총 0건의 데이터를 불러왔습니다.');
      return;
    }
    
    // 기존 데이터에 추가 (또는 교체)
    if (inputRows.value.filter(row => row.product_name_display && row.prescription_qty && !isNaN(Number(row.prescription_qty)) && Number(row.prescription_qty) > 0).length > 0) {
      const answer = confirm(`기존 ${totalCount.value}건의 데이터가 있습니다.\n\n[확인]: 기존 데이터에 추가\n[취소]: 기존 데이터 교체`);
      if (!answer) {
        // 기존 데이터 교체
        inputRows.value = parsedData;
      } else {
        // 기존 데이터에 추가
        inputRows.value.push(...parsedData);
      }
    } else {
      inputRows.value = parsedData;
    }
    // 마지막에 빈 행 추가
    inputRows.value.push(createEmptyRow());
    alert(`엑셀 일괄등록 완료!\n\n총 ${parsedData.length-1}건의 데이터를 불러왔습니다.`);
    // 마지막 빈 행의 제품명에 포커스
    nextTick(() => {
      focusField(inputRows.value.length - 1, 'product_name');
    });
  } catch (err) {
    console.error('엑셀 업로드 오류:', err);
    alert(err.message);
  } finally {
    event.target.value = '';
  }
}

// 엑셀 데이터 파싱 함수
async function parseExcelData(dataRows) {
  const parsedData = [];
  const errors = [];

  // 허용된 처방월 목록 생성
  const allowedPrescriptionMonths = [];
  const currentMonth = new Date(selectedSettlementMonth.value);
  for (let i = 1; i <= 3; i++) {
    const month = new Date(currentMonth);
    month.setMonth(month.getMonth() - i);
    allowedPrescriptionMonths.push(month.toISOString().slice(0, 7));
  }

  for (let i = 0; i < dataRows.length; i++) {
    const row = dataRows[i];
    const rowNum = i + 2; // 엑셀 행 번호 (헤더 포함)

    try {
      // 엑셀 데이터 구조: 거래처_사업자등록번호 / 처방월 / 보험코드 / 수량 / 처방구분 / 비고
      const clientBusinessNumber = row[0]?.toString().trim();
      const prescriptionMonth = row[1]?.toString().trim();
      const insuranceCode = row[2]?.toString().trim();
      const prescriptionQty = Number(row[3]) || 0;
      let excelPrescriptionType = row[4]?.toString().trim() || prescriptionTypeOptions[0];
      const remarks = row[5]?.toString().trim() || '';

      // 필수 데이터 검증
      if (!clientBusinessNumber || !prescriptionMonth || !insuranceCode) {
        errors.push(`${rowNum}행: 필수 데이터가 누락되었습니다.`);
        continue;
      }

      // 처방월 형식 검증 (YYYY-MM)
      if (!/^\d{4}-\d{2}$/.test(prescriptionMonth)) {
        errors.push(`${rowNum}행: 처방월 형식이 올바르지 않습니다. (예: 2025-05)`);
        continue;
      }

      // 허용된 처방월인지 검증
      if (!allowedPrescriptionMonths.includes(prescriptionMonth)) {
        errors.push(`${rowNum}행: 허용되지 않은 처방월입니다. (허용: ${allowedPrescriptionMonths.join(', ')})`);
        continue;
      }

      // 거래처 정보 매칭
      const client = await matchClientByBusinessNumber(clientBusinessNumber);
      if (!client) {
        errors.push(`${rowNum}행: 거래처를 찾을 수 없습니다. (사업자번호: ${clientBusinessNumber})`);
        continue;
      }

      // 제품 정보 매칭 및 활성화 상태 확인
      const product = await matchProductByInsuranceCode(insuranceCode);
      if (!product) {
        errors.push(`${rowNum}행: 제품을 찾을 수 없습니다. (보험코드: ${insuranceCode})`);
        continue;
      }

      // 해당 처방월에 제품이 활성화되어 있는지 확인
      const isProductActive = await checkProductActiveInMonth(insuranceCode, prescriptionMonth);
      if (!isProductActive) {
        errors.push(`${rowNum}행: 해당 처방월(${prescriptionMonth})에 제품이 활성화되어 있지 않습니다.`);
        continue;
      }

      // 데이터 객체 생성
      const performanceRow = {
        product_name_display: product.product_name,
        product_id: product.id,
        insurance_code: product.insurance_code,
        price: Number(product.price).toLocaleString(),
        prescription_qty: prescriptionQty.toString(),
        prescription_amount: (prescriptionQty * product.price).toLocaleString(),
        prescription_type: excelPrescriptionType,
        remarks: remarks,
        prescription_month: prescriptionMonth
      };

      parsedData.push(performanceRow);

    } catch (err) {
      console.error(`행 ${rowNum} 처리 중 오류:`, err);
      errors.push(`${rowNum}행: 데이터 처리 중 오류가 발생했습니다.`);
    }
  }

  if (errors.length > 0) {
    throw new Error('엑셀 데이터 검증 중 오류가 발생했습니다:\n' + errors.join('\n'));
  }

  return parsedData;
}

// 제품 활성화 상태 확인 함수
async function checkProductActiveInMonth(insuranceCode, prescriptionMonth) {
  try {
    const { data, error } = await supabase
      .from('products')
      .select('id, status')
      .eq('insurance_code', insuranceCode)
      .eq('base_month', prescriptionMonth);

    if (error) throw error;
    // 여러 행 중 하나라도 active면 true
    return Array.isArray(data) && data.some(item => item.status === 'active');
  } catch (err) {
    console.error('제품 활성화 상태 확인 오류:', err);
    return false;
  }
}

// 거래처 매칭 함수
async function matchClientByBusinessNumber(businessNumber) {
  try {
    const { data, error } = await supabase
      .from('clients')
      .select('*')
      .eq('business_registration_number', businessNumber.trim());

    if (error || !data || data.length === 0) {
      console.warn(`거래처 매칭 실패: ${businessNumber}`);
      return null;
    }

    console.log(`거래처 매칭 성공: ${businessNumber} -> ${data[0].name} (총 ${data.length}개 중 첫 번째)`);
    return data[0]; // 여러 개가 있어도 첫 번째 결과 반환
  } catch (err) {
    console.error('거래처 매칭 오류:', err);
    return null;
  }
}

// 제품 매칭 함수
async function matchProductByInsuranceCode(insuranceCode) {
  try {
    // 보험코드 형식 정규화
    let normalizedCode = insuranceCode.toString().trim();
    
    console.log('원본 보험코드:', insuranceCode, '타입:', typeof insuranceCode);
    console.log('정규화된 보험코드:', normalizedCode);
    
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .eq('insurance_code', normalizedCode);

    if (error || !data || data.length === 0) {
      console.warn(`제품 매칭 실패: ${normalizedCode}`);
      
      // 매칭 실패시 앞에 0을 붙여서 다시 시도 (9자리 -> 10자리)
      if (normalizedCode.length === 9) {
        const paddedCode = '0' + normalizedCode;
        console.log('0 추가하여 재시도:', paddedCode);
        
        const { data: retryData, error: retryError } = await supabase
          .from('products')
          .select('*')
          .eq('insurance_code', paddedCode);
          
        if (!retryError && retryData && retryData.length > 0) {
          console.log('0 추가 매칭 성공:', paddedCode, '->', retryData[0].product_name);
          return retryData[0]; // 첫 번째 결과 반환
        }
      }
      
      // 매칭 실패시 10자리에서 앞의 0을 제거하여 다시 시도
      if (normalizedCode.length === 10 && normalizedCode.startsWith('0')) {
        const trimmedCode = normalizedCode.substring(1);
        console.log('0 제거하여 재시도:', trimmedCode);
        
        const { data: retryData, error: retryError } = await supabase
          .from('products')
          .select('*')
          .eq('insurance_code', trimmedCode);
          
        if (!retryError && retryData && retryData.length > 0) {
          console.log('0 제거 매칭 성공:', trimmedCode, '->', retryData[0].product_name);
          return retryData[0]; // 첫 번째 결과 반환
        }
      }
      
      return null;
    }

    console.log(`제품 매칭 성공: ${normalizedCode} -> ${data[0].product_name} (총 ${data.length}개 중 첫 번째)`);
    return data[0]; // 여러 개가 있어도 첫 번째 결과 반환
  } catch (err) {
    console.error('제품 매칭 오류:', err);
    return null;
  }
}

// 처방월 옵션 생성 함수
function getDefaultPrescriptionMonth() {
  if (!selectedSettlementMonth.value) return '';
  const date = new Date(selectedSettlementMonth.value + '-01');
  date.setMonth(date.getMonth() - 1);
  return date.toISOString().slice(0, 7);
}

function getPrescriptionMonthOptions() {
  if (!selectedSettlementMonth.value) return [];
  const options = [];
  const date = new Date(selectedSettlementMonth.value + '-01');
  for (let i = 1; i <= 3; i++) {
    const m = new Date(date);
    m.setMonth(m.getMonth() - i);
    options.push(m.toISOString().slice(0, 7));
  }
  return options;
}

// 새 행 생성 함수 (처방월 기본값 적용)
function createEmptyRow() {
  return {
    product_name_display: '',
    product_id: null,
    insurance_code: '',
    price: '',
    prescription_qty: '',
    prescription_amount: '',
    prescription_type: prescriptionTypeOptions[0],
    remarks: '',
    prescription_month: getDefaultPrescriptionMonth()
  };
}

// onPrescriptionMonthChange 함수 개선: 드롭다운 즉시 초기화, 기존 제품이 해당 월에 없으면 입력값 모두 초기화
async function onPrescriptionMonthChange(rowIdx) {
  console.log('onPrescriptionMonthChange', rowIdx, inputRows.value[rowIdx].prescription_month);
  // 드롭다운 결과 즉시 초기화
  productSearchForRow.value.results = [];
  productSearchForRow.value.show = false;
  // 현재 입력된 제품명/보험코드가 해당 월에 존재하는지 확인
  const month = inputRows.value[rowIdx].prescription_month;
  const currentCode = inputRows.value[rowIdx].insurance_code;
  let found = false;
  if (currentCode) {
    const { data, error } = await supabase
      .from('products')
      .select('id')
      .eq('base_month', month)
      .eq('insurance_code', currentCode)
      .eq('status', 'active');
    if (data && data.length > 0) found = true;
  }
  if (!found) {
    // 입력값 모두 초기화
    inputRows.value[rowIdx].product_name_display = '';
    inputRows.value[rowIdx].product_id = null;
    inputRows.value[rowIdx].insurance_code = '';
    inputRows.value[rowIdx].price = '';
    inputRows.value[rowIdx].prescription_qty = '';
    inputRows.value[rowIdx].prescription_amount = '';
  }
  // 새로 쿼리
  searchProductsForRow(rowIdx, '');
  // 자동 이동: 처방월 변경 시 해당 행 제품명으로
  nextTick(() => focusField(rowIdx, 'product_name'));
}

function calculateDropdownPosition() {
  // TODO: 실제 위치 계산 필요시 구현
  return {};
}

function recalculateRow() {
  // TODO: 실제 로직 필요시 구현
}
</script> 