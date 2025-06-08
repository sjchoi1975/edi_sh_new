<template>
  <div class="performance-register-view page-container">
    <div class="page-header-title-area">
      <div class="header-title">실적 등록</div>
    </div>

    <!-- 필터 카드: 거래처 정보 -->
    <div class="filter-card" style="display: flex; align-items: center; gap: 0.5rem; margin-bottom:0rem; padding:0.25rem 0.5rem !important;">
      <Button icon="pi pi-arrow-left" severity="secondary" text rounded @click="goBack" style="margin-bottom:0rem; padding:0rem 0.25rem !important;"/>
      <div>
        <div style="font-size:1.2rem; font-weight:700;">
          {{ route.query.clientName }}
        </div>
        <div style="font-size:0.95rem; color:#555;">
          {{ route.query.businessRegistrationNumber }} / {{ route.query.address }}
        </div>
      </div>
    </div>

    <!-- 데이터 카드: 실적 등록 -->
    <div class="data-card">
      <div class="data-card-header">
        <div class="total-count-display">전체 {{ validRowCount }} 건</div>
        <div class="data-card-buttons">
          <Button label="저장" class="btn-save" @click="saveData" :disabled="!hasChanges || validRowCount === 0" />
        </div>
      </div>
      <DataTable
        :value="rows"
        scrollable
        scrollHeight="calc(100vh - 220px)"
        class="custom-table performance-edit-table"
      >
        <Column header="No" :headerStyle="{ width: columnWidths.no }">
          <template #body="slotProps">{{ slotProps.index + 1 }}</template>
        </Column>
        <Column field="prescriptionMonth" header="처방월" :headerStyle="{ width: columnWidths.prescriptionMonth }">
          <template #body="slotProps">
            <Dropdown v-model="slotProps.data.prescriptionMonth" :options="prescriptionMonths" placeholder="선택" style="width:100%" />
          </template>
        </Column>
        <Column field="productObj" header="제품명" :headerStyle="{ width: columnWidths.product }">
          <template #body="slotProps">
            <div class="p-fluid" style="position: relative;">
              <InputText
                v-model="slotProps.data.productNameQuery"
                @input="onProductSearch(slotProps.data, $event.target.value)"
                @keydown="onProductKeydown($event, slotProps.index, slotProps.data)"
                :class="{ 'cell-focused': isCellFocused(slotProps.index, 'product') }"
                @focus="onProductFocus(slotProps.index, slotProps.data)"
                :id="`product-input-${slotProps.index}`"
                placeholder="제품명/보험코드 검색"
              />
              <ul v-if="productSuggestions.length > 0 && currentCell.row === slotProps.index && currentCell.col === 'product'" class="product-search-dropdown">
                <li v-for="(p, i) in productSuggestions" :key="p.id" @click="onProductSelect(slotProps.data, p, slotProps.index)" :class="{ 'selected': i === productSuggestionIndex }">
                  <span class="product-name">{{ p.product_name }}</span>
                  <span class="insurance-code">{{ p.insurance_code }}</span>
                </li>
              </ul>
            </div>
          </template>
        </Column>
        <Column field="insuranceCode" header="보험코드" :headerStyle="{ width: columnWidths.insuranceCode }">
          <template #body="slotProps">
            <InputText :value="slotProps.data.productObj?.insurance_code || ''" style="width:100%" readonly />
          </template>
        </Column>
        <Column field="price" header="약가" :headerStyle="{ width: columnWidths.price }">
          <template #body="slotProps">
            <InputText :value="slotProps.data.productObj?.price ? Number(slotProps.data.productObj.price).toLocaleString() : ''" style="width:100%" readonly />
          </template>
        </Column>
        <Column field="qty" header="수량" :headerStyle="{ width: columnWidths.qty }">
          <template #body="slotProps">
            <InputText
              v-model="slotProps.data.qty"
              @input="onQtyInput(slotProps.data)"
              :id="`qty-input-${slotProps.index}`"
              @keydown.enter="onQtyKeydown($event, slotProps.index)"
              :class="{ 'cell-focused': isCellFocused(slotProps.index, 'qty') }"
              @focus="() => setCellFocus(slotProps.index, 'qty')"
              style="width:100%"
            />
          </template>
        </Column>
        <Column field="amount" header="처방액" :headerStyle="{ width: columnWidths.amount }">
          <template #body="slotProps">
            <span>{{ slotProps.data.amount }}</span>
          </template>
        </Column>
        <Column field="prescriptionType" header="처방구분" :headerStyle="{ width: columnWidths.prescriptionType }">
          <template #body="slotProps">
            <Dropdown
              v-model="slotProps.data.prescriptionType"
              :options="prescriptionTypeOptions"
              placeholder="선택"
              style="width:100%"
              :class="{ 'cell-focused': isCellFocused(slotProps.index, 'prescriptionType') }"
              @focus="() => setCellFocus(slotProps.index, 'prescriptionType')"
            />
          </template>
        </Column>
        <Column field="remarks" header="비고" :headerStyle="{ width: columnWidths.remarks }">
          <template #body="slotProps">
            <InputText
              v-model="slotProps.data.remarks"
              :class="{ 'cell-focused': isCellFocused(slotProps.index, 'remarks') }"
              @focus="() => setCellFocus(slotProps.index, 'remarks')"
              style="width:100%"
            />
          </template>
        </Column>
        <Column header="작업" :headerStyle="{ width: columnWidths.actions }">
          <template #body="slotProps">
            <Button label="삭제" class="btn-delete-sm" severity="danger" size="small" @click="removeRow(slotProps.index)" style="margin-right:4px;" />
            <Button label="추가" class="btn-add-sm" severity="info" size="small" @click="addRowBelow(slotProps.index)" />
          </template>
        </Column>
        <ColumnGroup type="footer">
          <Row>
            <Column footer="합계" :colspan="5" footerClass="footer-cell" footerStyle="text-align: center !important;"/>
            <Column :footer="totalQty" footerClass="footer-cell" footerStyle="text-align: right !important;" />
            <Column :footer="totalAmount" footerClass="footer-cell" footerStyle="text-align: right !important;" />
            <Column :colspan="3" footerClass="footer-cell" />
          </Row>
        </ColumnGroup>
      </DataTable>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick, watch } from 'vue';
import { supabase } from '@/supabase';
import { useRoute, useRouter, onBeforeRouteLeave } from 'vue-router';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import InputText from 'primevue/inputtext';
import Dropdown from 'primevue/dropdown';
import Button from 'primevue/button';
import AutoComplete from 'primevue/autocomplete';
import ColumnGroup from 'primevue/columngroup';
import Row from 'primevue/row';

const getRowsSnapshot = (rows) => {
  const simplifiedRows = rows.map(row => ({
    pm: row.prescriptionMonth,
    pId: row.productObj ? row.productObj.id : null,
    qty: row.qty,
    pt: row.prescriptionType,
    rm: row.remarks,
  }));
  return JSON.stringify(simplifiedRows);
};

// 1. 컬럼 너비 한 곳에서 관리
const columnWidths = {
  no: '4%',
  prescriptionMonth: '8%',
  product: '20%',
  insuranceCode: '10%',
  price: '8%',
  qty: '8%',
  amount: '8%',
  prescriptionType: '8%',
  remarks: '18%',
  actions: '8%',
};

const route = useRoute();
const router = useRouter();
const selectedSettlementMonth = ref(route.query.settlementMonth || '');
const selectedClientName = ref(route.query.clientName || '');
const selectedClientId = ref(route.query.clientId || '');

const prescriptionMonths = ref([]); // 처방월 드롭다운
const products = ref([]); // 전체 제품 리스트 (보험코드 중복 없이)
const prescriptionTypeOptions = ['EDI', '대한조제', '의료매출', '직거래매입', '차감', '원내매출', '원외매출'];

const rows = ref([]);

// 오토컴플릿용 상태
const productSuggestions = ref([]);
const productSuggestionIndex = ref(-1);

// 변경사항 감지
const hasChanges = ref(false);
const isReady = ref(false); // 데이터 로딩 및 초기화 완료 상태

watch(rows, () => {
  if (isReady.value) {
    hasChanges.value = true;
  }
}, { deep: true });

// 3. 포커스 상태 관리
const currentCell = ref({ row: null, col: null });

function setCellFocus(rowIdx, col) {
  currentCell.value = { row: rowIdx, col };
}
function isCellFocused(rowIdx, col) {
  return currentCell.value.row === rowIdx && currentCell.value.col === col;
}

function getPrescriptionMonthOptions(settlementMonth) {
  if (!settlementMonth) return [];
  const options = [];
  const date = new Date(settlementMonth + '-01');
  for (let i = 1; i <= 3; i++) {
    const m = new Date(date);
    m.setMonth(m.getMonth() - i);
    options.push(m.toISOString().slice(0, 7));
  }
  return options;
}

async function fetchProducts() {
  const { data, error } = await supabase
    .from('products')
    .select('*')
    .eq('status', 'active');
  if (!error && data) {
    // 보험코드 기준 중복 제거
    const seen = new Set();
    products.value = data.filter(p => {
      if (!p.insurance_code || seen.has(p.insurance_code)) return false;
      seen.add(p.insurance_code);
      return true;
    });
  }
}

onMounted(async () => {
  prescriptionMonths.value = getPrescriptionMonthOptions(selectedSettlementMonth.value);
  await fetchProducts();
  await fetchPerformanceData();

  if (rows.value.length === 0) {
    for (let i = 0; i < 100; i++) {
      rows.value.push(createRow());
    }
  }
  // 페이지 로드 시 첫 번째 제품 입력란에 포커스
  nextTick(() => {
    const firstProductInput = document.getElementById('product-input-0');
    if (firstProductInput) {
      firstProductInput.focus();
      setCellFocus(0, 'product');
    }
    // 모든 데이터가 준비된 후, 변경 감지를 시작하도록 상태 설정
    isReady.value = true;
    hasChanges.value = false;
  });
});

async function fetchPerformanceData() {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    console.error('사용자 정보를 찾을 수 없습니다.');
    return;
  }

  const { data: company } = await supabase
    .from('companies')
    .select('id')
    .eq('user_id', user.id)
    .single();

  if (!company) {
    console.error('회사 정보를 찾을 수 없습니다.');
    return;
  }

  const { data: records, error } = await supabase
    .from('performance_records')
    .select('*, products(*)')
    .eq('company_id', company.id)
    .eq('client_id', selectedClientId.value)
    .eq('settlement_month', selectedSettlementMonth.value);

  if (error) {
    console.error('실적 데이터 로딩 오류:', error);
    return;
  }

  if (records && records.length > 0) {
    rows.value = records.map(record => {
      const qty = Number(record.prescription_qty) || 0;
      const price = Number(record.products?.price) || 0;
      return {
        prescriptionMonth: record.prescription_month,
        productObj: record.products,
        qty: qty > 0 ? qty.toLocaleString() : '',
        amount: (qty * price) > 0 ? (qty * price).toLocaleString() : '',
        prescriptionType: record.prescription_type,
        remarks: record.remarks || '',
      };
    });
  }
}

function createRow() {
  return {
    prescriptionMonth: prescriptionMonths.value[0] || '',
    productObj: null, // 제품 객체
    productNameQuery: '', // 제품 검색어
    qty: '',
    amount: '',
    prescriptionType: prescriptionTypeOptions[0],
    remarks: '',
  };
}

function addRowBelow(idx) {
  rows.value.splice(idx + 1, 0, createRow());
}

function removeRow(idx) {
  rows.value.splice(idx, 1);
}

function onProductSelect(row, value, rowIdx) {
  row.productObj = value;
  row.productNameQuery = value.product_name; // 입력창에 제품명 표시
  productSuggestions.value = []; // 드롭다운 숨기기
  productSuggestionIndex.value = -1;

  if (value && value.price && row.qty) {
    const qty = Number(row.qty.toString().replace(/,/g, '')) || 0;
    row.amount = value.price && qty ? (value.price * qty).toLocaleString() : '';
  } else {
    row.amount = '';
  }
  setTimeout(() => {
    const qtyInput = document.getElementById(`qty-input-${rowIdx}`);
    if (qtyInput) qtyInput.focus();
  }, 50);
}

function onProductFocus(rowIdx, rowData) {
  setCellFocus(rowIdx, 'product');
  if (rowData.productNameQuery) {
     onProductSearch(rowData, rowData.productNameQuery);
  }
}

function onProductKeydown(e, rowIdx, rowData) {
  if (e.key === 'ArrowDown') {
    e.preventDefault();
    if (productSuggestionIndex.value < productSuggestions.value.length - 1) {
      productSuggestionIndex.value++;
    }
  } else if (e.key === 'ArrowUp') {
    e.preventDefault();
    if (productSuggestionIndex.value > 0) {
      productSuggestionIndex.value--;
    }
  } else if (e.key === 'Enter') {
    e.preventDefault();
    if (productSuggestionIndex.value !== -1) {
      onProductSelect(rowData, productSuggestions.value[productSuggestionIndex.value], rowIdx);
    } else if (productSuggestions.value.length > 0) {
      onProductSelect(rowData, productSuggestions.value[0], rowIdx);
    }
  } else {
    setCellFocus(rowIdx, 'product');
  }
}

async function onProductSearch(row, query) {
  row.productNameQuery = query;
  if (!query) {
    productSuggestions.value = [];
    return;
  }
  const searchLimit = 50;
  const { data, error } = await supabase
    .from('products')
    .select('*')
    .or(`product_name.ilike.%${query}%,insurance_code.ilike.%${query}%`)
    .eq('status', 'active')
    .limit(searchLimit);

  if (!error && data) {
    productSuggestions.value = data;
    productSuggestionIndex.value = -1; // 검색 결과 변경 시 인덱스 초기화
  } else {
    productSuggestions.value = [];
  }
}

function onQtyInput(row) {
  const price = row.productObj && row.productObj.price ? Number(row.productObj.price) : 0;
  const qty = Number(row.qty.toString().replace(/,/g, '')) || 0;
  row.qty = qty ? qty.toLocaleString() : '';
  row.amount = price && qty ? (price * qty).toLocaleString() : '';
}

function onQtyKeydown(e, rowIdx) {
  if (e.key === 'Enter') {
    e.preventDefault();
    const nextProduct = document.getElementById(`product-input-${rowIdx + 1}`);
    if (nextProduct) {
      nextProduct.focus();
    }
  } else {
    setCellFocus(rowIdx, 'qty');
  }
}

const totalQty = computed(() => {
  return rows.value.reduce((sum, row) => sum + (Number(row.qty?.toString().replace(/,/g, '')) || 0), 0).toLocaleString();
});
const totalAmount = computed(() => {
  return rows.value.reduce((sum, row) => sum + (Number(row.amount?.toString().replace(/,/g, '')) || 0), 0).toLocaleString();
});
const validRowCount = computed(() => {
  return rows.value.filter(row => row.prescriptionMonth && row.productObj && row.qty && row.productObj.price).length;
});

async function saveData() {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    alert('로그인이 필요합니다.');
    return;
  }

  const { data: company, error: companyError } = await supabase
    .from('companies')
    .select('id')
    .eq('user_id', user.id)
    .single();

  if (companyError || !company) {
    console.error('회사 정보 조회 오류:', companyError);
    alert('사용자의 회사 정보를 가져오는 데 실패했습니다. 관리자에게 문의하세요.');
    return;
  }

  // 1. Delete all existing records for this context
  const { error: deleteError } = await supabase
    .from('performance_records')
    .delete()
    .match({
      company_id: company.id,
      client_id: selectedClientId.value,
      settlement_month: selectedSettlementMonth.value
    });

  if (deleteError) {
    console.error('기존 실적 삭제 오류:', deleteError);
    alert(`기존 데이터를 삭제하는 중 오류가 발생했습니다: ${deleteError.message}`);
    return;
  }

  // 2. Prepare and insert the new records from the UI
  const validRows = rows.value.filter(row => row.prescriptionMonth && row.productObj && row.qty && row.productObj.price);

  if (validRows.length === 0) {
    alert('모든 실적이 삭제되었습니다.');
    router.push('/performance/register');
    return;
  }

  const dataToSave = validRows.map(row => ({
    company_id: company.id,
    client_id: selectedClientId.value,
    product_id: row.productObj.id,
    registered_by: user.id,
    settlement_month: selectedSettlementMonth.value,
    prescription_month: row.prescriptionMonth,
    prescription_qty: Number(row.qty.toString().replace(/,/g, '')),
    prescription_type: row.prescriptionType,
    remarks: row.remarks,
  }));

  const { error: insertError } = await supabase.from('performance_records').insert(dataToSave);

  if (insertError) {
    console.error('실적 저장 오류:', insertError);
    alert(`데이터 저장 중 오류가 발생했습니다: ${insertError.message}`);
  } else {
    hasChanges.value = false; // 저장 후 변경상태 초기화
    alert(`${dataToSave.length}건의 실적이 성공적으로 저장되었습니다.`);
    router.push('/performance/register');
  }
}

function goBack() {
  router.push('/performance/register');
}

// 저장하지 않고 이탈 시 경고
onBeforeRouteLeave((to, from, next) => {
  if (hasChanges.value) {
    if (confirm('변경 사항이 있습니다.\n등록하지 않고 이동하시겠습니까?')) {
      next();
    } else {
      next(false);
    }
  } else {
    next();
  }
});
</script>
