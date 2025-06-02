<template>
  <div class="performance-register-view">
    <div class="header-title">실적 등록</div>
    <!-- 선택된 정산월 병원 정보를 상단에 고정 표시 -->
    <div class="filter-card" style="display:flex; align-items:center; margin-bottom:1.5rem;">
      <div>
        <div style="font-size:1.1rem; font-weight:700; margin-bottom:2px;">정산월: {{ selectedSettlementMonth }}</div>
        <div style="font-size:1.2rem; font-weight:700;">{{ route.query.clientName }}</div>
        <div style="font-size:0.95rem; color:#888;">
          {{ route.query.businessRegistrationNumber }} / {{ route.query.address }}
        </div>
      </div>
    </div>
    <div class="data-card">
      <div class="input-table-wrapper">
        <div class="top-bar-row">
          <div class="left-group">
            <label style="font-weight:500; margin-right:0.5rem;">처방월:</label>
            <select v-model="prescriptionOffset" class="select_month">
              <option v-for="opt in prescriptionOptions" :key="opt.value" :value="opt.value">
                {{ opt.month }}
              </option>
            </select>
          </div>
          <button class="btn-primary register-button" @click="onSave" :disabled="!canSave">저장</button>
        </div>
        <!-- 실적 입력 테이블 -->
        <table class="input-table prime-like-table">
          <thead>
            <tr>
              <th style="width:40px;">No</th>
              <th style="width:20%;">제품명</th>
              <th style="width:8%;">보험코드</th>
              <th style="width:8%;">단가</th>
              <th style="width:8%;">처방수량</th>
              <th style="width:10%;">처방액</th>
              <th style="width:10%;">처방구분</th>
              <th style="width:14%;">비고</th>
              <th style="width:40px;">행삭제</th>
              <th style="width:40px;">추가</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(row, rowIdx) in inputRows" :key="rowIdx">
              <td style="text-align:center;">{{ rowIdx + 1 }}</td>
              <td style="position:relative;text-align:left;">
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
                    @click="toggleProductDropdown(rowIdx)"
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
              <td style="text-align:center;">
                <span class="readonly-span">{{ row.insurance_code }}</span>
              </td>
              <td style="text-align:right;">
                <span class="readonly-span">{{ row.price }}</span>
              </td>
              <td style="text-align:right; position:relative;">
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
                />
              </td>
              <td style="text-align:right;">
                <span class="readonly-span">{{ row.prescription_amount }}</span>
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
                  title="행삭제"
                  :class="{ 'disabled-area': !isInputEnabled }"
                >✕</button>
              </td>
              <td class="action-cell">
                <button 
                  class="btn-add-m" 
                  @click="confirmAddRowBelow(rowIdx)" 
                  title="아래행을 추가"
                  :disabled="!isInputEnabled"
                  :class="{ 'disabled-area': !isInputEnabled }"
                >＋</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <!-- 합계 행을 하단 고정 -->
      <div class="table-footer-wrapper"
        style="width:100%;
        background:#f8f9fa;
        border-top:1px solid #dee2e6;
        border-bottom:1px solid #bcc0c4;
        position:sticky;
        bottom:0;
        z-index:2;">
        <table style="width:100%; table-layout:fixed;">
          <tr>
            <td colspan="4" style="text-align:center;font-weight:bold;">합계</td>
            <td style="text-align:right;font-weight:bold;">{{ totalQty }}</td>
            <td style="text-align:right;font-weight:bold;">{{ totalAmount }}</td>
            <td colspan="4"></td>
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
  remarks: '' 
}]);

const isInputEnabled = true;
const canSave = computed(() => {
  return inputRows.value.some(row => row.product_id && row.prescription_qty);
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

function setProductInputRef(rowIdx, el) {
  if (el) productInputRefs.value[rowIdx] = el;
}

function updateProductDropdownPosition(rowIdx) {
  nextTick(() => {
    const el = productInputRefs.value[rowIdx];
    if (!el) return;
    const rect = el.getBoundingClientRect();
    productDropdownStyle.value[rowIdx] = {
      position: 'fixed',
      left: rect.left + 'px',
      top: rect.bottom + 'px',
      width: rect.width + 'px',
      zIndex: 9999,
      maxHeight: '220px',
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
  if (!isInputEnabled) return;
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

function toggleProductDropdown(rowIndex) {
  if (!isInputEnabled) return;
  
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
    // 제품명과 수량이 모두 입력되어 있어야만 다음행 생성
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
    // 제품명과 수량이 모두 입력되어 있어야만 다음행 생성
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
    // 아래 화살표시 제품명과 수량이 모두 입력된 상태에서 마지막 행이면 새행 생성
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
  const qty = Number(inputRows.value[rowIdx].prescription_qty.toString().replace(/,/g, ''));
  const price = Number(inputRows.value[rowIdx].price.toString().replace(/,/g, ''));
  if (!isNaN(qty) && !isNaN(price) && price > 0) {
    inputRows.value[rowIdx].prescription_amount = (qty * price).toLocaleString();
  } else {
    inputRows.value[rowIdx].prescription_amount = '';
  }
}

function onArrowKey(e, rowIdx, col) {
  // 제품 검색 드롭다운이 열려있을 때는 상하 화살표만 허용
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
    // 아래 화살표시 제품명과 수량이 모두 입력된 상태에서 마지막 행이면 새행 생성
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
    prescription_month: prescriptionMonth.value,
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
  // 제품 검색 드롭다운이 열려있으면 차단
  if (isProductSearchOpen.value) {
    return;
  }
  
  // clientId, settlementMonth를 query에서 찾음
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

  // 2. 부족한 정보 행이 있는 경우 사용자 확인
  if (partialRows.length > 0) {
    const partialRowNumbers = partialRows.map(row => `No ${row.rowNumber}`).join(', ');
    const message = `${partialRows.length}건의 실적이 필수 정보(제품, 처방수량)가 누락되었습니다.\n${partialRowNumbers}\n제외하고 저장하시겠습니까?`;
    
    if (!confirm(message)) {
      return; // 취소 시 저장 중단
    }
  }

  try {
    // 3. 저장 처리 (기존 데이터 삭제 후 새로 저장)
    const savedCount = await savePerformanceData();
    
    // 4. 성공 메시지
    alert(`${savedCount}건의 실적이 저장되었습니다.`);

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
        remarks: record.remarks || ''
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

// 행 추가/행 삭제
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
    const lastRowIndex = inputRows.value.length - 1;
    focusField(lastRowIndex, 'product_name');
  });
  
  document.addEventListener('keydown', handleGlobalKeydown);
  document.addEventListener('click', handleGlobalClick);
});

onUnmounted(() => {
  document.removeEventListener('keydown', handleGlobalKeydown);
  document.removeEventListener('click', handleGlobalClick);
});
</script> 