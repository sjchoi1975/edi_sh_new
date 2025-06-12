<template>
  <div class="performance-review-view page-container" style="display: flex; flex-direction: column; height: 100vh;">
    <div class="page-header-title-area" style="flex-shrink: 0;">
      <div class="header-title">실적 검수</div>
    </div>

    <!-- 필터 카드 -->
    <div class="filter-card" style="flex-shrink: 0;">
      <div class="filter-row" style="justify-content: flex-start; align-items: flex-end;">
        <div style="display: flex; align-items: center; gap: 8px;">
          <label>정산월</label>
          <select v-model="selectedSettlementMonth" class="select_month">
            <option v-for="month in availableMonths" :key="month.settlement_month" :value="month.settlement_month">{{ month.settlement_month }}</option>
          </select>
        </div>
        <div style="display: flex; align-items: center; gap: 8px;">
          <label>처방월</label>
          <select v-model="prescriptionOffset" class="select_month">
            <option v-for="opt in prescriptionOptions" :key="opt.value" :value="opt.value">{{ opt.month }}</option>
          </select>
        </div>
        <div style="display: flex; align-items: center; gap: 8px;">
          <label>업체</label>
          <select v-model="selectedCompanyId" class="select_200px">
            <option v-for="company in companyOptions" :key="company.id" :value="company.id">{{ company.company_name }}</option>
          </select>
        </div>
        <div style="display: flex; align-items: center; gap: 8px;">
          <label>병의원</label>
          <select v-model="selectedHospitalId" class="select_200px">
            <option v-for="hospital in hospitalOptions" :key="hospital.id" :value="hospital.id">{{ hospital.name }}</option>
          </select>
        </div>
        <div style="display: flex; align-items: center; gap: 8px;">
          <label>상태</label>
          <select v-model="selectedReviewStatus" class="select_100px">
            <option v-for="opt in reviewStatusOptions" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
          </select>
        </div>
        <div style="display: flex; align-items: center; margin-left: auto;">
          <button 
            class="btn-primary" 
            @click="loadPerformanceData" 
            :disabled="loading"
          >
            실적 정보 불러오기
          </button>
        </div>
      </div>
    </div>

    <!-- 데이터 카드 -->
    <div class="data-card" style="flex-grow: 1; display: flex; flex-direction: column; overflow: hidden;">
      <div class="data-card-header" style="flex-shrink: 0;">
        <div class="total-count-display">전체 {{ displayRows.length }} 건</div>
        <div class="data-card-buttons">
           <button class="btn-secondary" @click="selectAll">전체 선택</button>
           <button class="btn-secondary" @click="unselectAll">전체 해제</button>
           <button class="btn-primary" @click="changeReviewStatus" :disabled="selectedRows.length === 0">
             검수 상태 변경 ({{ selectedRows.length }}건)
           </button>
           <button class="btn-warning" @click="removeFromReview" :disabled="selectedRows.length === 0">
             검수 대상 제외 ({{ selectedRows.length }}건)
           </button>
        </div>
      </div>
      
      <div style="flex-grow: 1; overflow: hidden;">
        <DataTable 
          :value="displayRows" 
          :loading="loading"
          scrollable 
          scrollHeight="calc(100vh - 220px)"
          class="admin-performance-review-table"
          :rowClass="getRowClass"
          :pt="{
            wrapper: { style: 'min-width: 2200px;' },
            table: { style: 'min-width: 2200px;' }
          }"
        >
          <template #empty>
            <div v-if="loading">데이터를 불러오는 중입니다.</div>
            <div v-else>필터 조건을 선택하고 '실적 정보 불러오기'를 클릭하세요.</div>
          </template>
          
          <Column header="선택" :headerStyle="{ width: columnWidths.checkbox }" :frozen="true">
            <template #header>
              <Checkbox v-model="selectAllChecked" @change="toggleSelectAll" :binary="true"/>
            </template>
            <template #body="slotProps">
              <Checkbox :modelValue="!!selectedRowsMap[slotProps.data.id]" @update:modelValue="(value) => onRowSelectChange(slotProps.data, value)" :binary="true" :disabled="slotProps.data.review_action === '삭제'"/>
            </template>
          </Column>

          <Column header="상태" field="review_status" :headerStyle="{ width: columnWidths.review_status }" :frozen="true">
            <template #body="slotProps">
              <Tag :value="slotProps.data.review_status" :severity="slotProps.data.review_status === '완료' ? 'success' : 'warning'"/>
            </template>
          </Column>

          <Column header="작업" field="review_action" :headerStyle="{ width: columnWidths.review_action }" :frozen="true">
            <template #body="slotProps">
              <Tag v-if="slotProps.data.review_action" :value="slotProps.data.review_action" :severity="getActionSeverity(slotProps.data.review_action)"/>
            </template>
          </Column>
          
          <Column header="액션" :headerStyle="{ width: columnWidths.actions }" :frozen="true">
             <template #body="slotProps">
              <div style="display: flex; gap: 4px; justify-content: center;">
                <template v-if="slotProps.data.isEditing">
                  <button class="btn-save-sm" @click="saveEdit(slotProps.data)" title="저장">✓</button>
                  <button class="btn-cancel-sm" @click="cancelEdit(slotProps.data)" title="취소">✕</button>
                </template>
                <template v-else-if="slotProps.data.review_action === '삭제'">
                  <button class="btn-restore-sm" @click="restoreRow(slotProps.data)" title="되돌리기">↶</button>
                </template>
                <template v-else>
                  <button class="btn-edit-sm" @click="startEdit(slotProps.data)" title="수정" :disabled="slotProps.data.review_status === '완료'">✎</button>
                  <button class="btn-delete-sm" @click="confirmDeleteRow(slotProps.data)" title="삭제" :disabled="slotProps.data.review_status === '완료'">－</button>
                  <button class="btn-add-sm" @click="addRowBelow(slotProps.data)" title="추가">＋</button>
                </template>
              </div>
            </template>
          </Column>

          <Column field="company_name" header="업체명" :headerStyle="{ width: columnWidths.company_name }" :sortable="true" :frozen="true" />
          <Column field="client_name" header="병의원명" :headerStyle="{ width: columnWidths.client_name }" :sortable="true" :frozen="true" />
          
          <Column field="prescription_month" header="처방월" :headerStyle="{ width: columnWidths.prescription_month }" :sortable="true">
            <template #body="slotProps">
              <Dropdown v-if="slotProps.data.isEditing" v-model="slotProps.data.prescription_month_modify" :options="availableMonths" optionLabel="settlement_month" optionValue="settlement_month" @change="handleEditCalculations(slotProps.data, 'month')" class="edit-mode-input" />
              <span v-else>{{ slotProps.data.prescription_month }}</span>
            </template>
          </Column>
          <Column field="product_name_display" header="제품명" :headerStyle="{ width: columnWidths.product_name_display }" :sortable="true">
            <template #body="slotProps">
              <Dropdown v-if="slotProps.data.isEditing" v-model="slotProps.data.product_id_modify" :options="slotProps.data.availableProducts" optionLabel="product_name" optionValue="id" @change="handleEditCalculations(slotProps.data, 'product')" filter class="edit-mode-input" placeholder="제품 선택"/>
              <span v-else>{{ slotProps.data.product_name_display }}</span>
            </template>
          </Column>
          <Column field="insurance_code" header="보험코드" :headerStyle="{ width: columnWidths.insurance_code }" :sortable="true" />
          <Column field="price" header="약가" :headerStyle="{ width: columnWidths.price }" :sortable="true">
            <template #body="slotProps">
                <span v-if="slotProps.data.isEditing">{{ slotProps.data.price_for_calc?.toLocaleString() }}</span>
                <span v-else>{{ slotProps.data.price }}</span>
            </template>
          </Column>
          <Column field="prescription_qty" header="수량" :headerStyle="{ width: columnWidths.prescription_qty }" :sortable="true">
             <template #body="slotProps">
                <InputNumber v-if="slotProps.data.isEditing" v-model="slotProps.data.prescription_qty_modify" @update:modelValue="handleEditCalculations(slotProps.data)" :min="0" class="edit-mode-input" />
                <span v-else>{{ slotProps.data.prescription_qty }}</span>
            </template>
          </Column>
          <Column field="prescription_amount" header="처방액" :headerStyle="{ width: columnWidths.prescription_amount }" :sortable="true">
            <template #body="slotProps">
              <span v-if="slotProps.data.isEditing">{{ slotProps.data.prescription_amount_modify?.toLocaleString() }}</span>
              <span v-else>{{ slotProps.data.prescription_amount }}</span>
            </template>
          </Column>
          <Column field="prescription_type" header="처방구분" :headerStyle="{ width: columnWidths.prescription_type }" :sortable="true">
             <template #body="slotProps">
                <Dropdown v-if="slotProps.data.isEditing" v-model="slotProps.data.prescription_type_modify" :options="prescriptionTypes" class="edit-mode-input"/>
                <span v-else>{{ slotProps.data.prescription_type }}</span>
            </template>
          </Column>
          <Column field="commission_rate" header="수수료율" :headerStyle="{ width: columnWidths.commission_rate }" :sortable="true">
             <template #body="slotProps">
                <InputNumber v-if="slotProps.data.isEditing" v-model="slotProps.data.commission_rate_modify" @update:modelValue="handleEditCalculations(slotProps.data)" :min="0" :max="100" suffix=" %" :maxFractionDigits="1" class="edit-mode-input"/>
                <span v-else>{{ slotProps.data.commission_rate }}</span>
            </template>
          </Column>
          <Column field="payment_amount" header="지급액" :headerStyle="{ width: columnWidths.payment_amount }" :sortable="true">
            <template #body="slotProps">
                <span v-if="slotProps.data.isEditing">{{ slotProps.data.payment_amount_modify?.toLocaleString() }}</span>
                <span v-else>{{ slotProps.data.payment_amount }}</span>
            </template>
          </Column>
          <Column field="remarks" header="비고" :headerStyle="{ width: columnWidths.remarks }" :sortable="true">
            <template #body="slotProps">
                <InputText v-if="slotProps.data.isEditing" v-model="slotProps.data.remarks_modify" class="edit-mode-input"/>
                <span v-else>{{ slotProps.data.remarks }}</span>
            </template>
          </Column>
          <Column field="created_date" header="등록일시" :headerStyle="{ width: columnWidths.created_date }" :sortable="true" />
          <Column field="created_by" header="등록자" :headerStyle="{ width: columnWidths.created_by }" :sortable="true" />
        </DataTable>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Checkbox from 'primevue/checkbox';
import Tag from 'primevue/tag';
import Dropdown from 'primevue/dropdown';
import InputNumber from 'primevue/inputnumber';
import InputText from 'primevue/inputtext';
import { supabase } from '@/supabase';

const columnWidths = {
  checkbox: '3%',
  review_status: '4%',
  review_action: '4%',
  actions: '6%',
  company_name: '8%',
  client_name: '10%',
  prescription_month: '5%',
  product_name_display: '12%',
  insurance_code: '6%',
  price: '5%',
  prescription_qty: '5%',
  prescription_amount: '6%',
  prescription_type: '6%',
  commission_rate: '5%',
  payment_amount: '6%',
  remarks: '10%',
  created_date: '7%',
  created_by: '8%'
};

// --- 상태 변수 ---
const loading = ref(false);
const displayRows = ref([]);
const availableMonths = ref([]);
const companyOptions = ref([]);
const hospitalOptions = ref([]);
const allProducts = ref([]);

// --- 필터 ---
const selectedSettlementMonth = ref('');
const selectedCompanyId = ref('ALL');
const selectedHospitalId = ref('ALL');
const prescriptionOffset = ref(0);
const selectedReviewStatus = ref('신규');

const prescriptionOptions = ref([]);
const reviewStatusOptions = [
  { label: '- 전체 -', value: 'ALL' },
  { label: '완료', value: '완료' },
  { label: '검수중', value: '검수중' },
  { label: '신규', value: '신규' },
];
const prescriptionTypes = ref(['EDI', '대한조제', '의료매출', '직거래매입', '차감', '원내매출', '원외매출']);

// --- 선택 관련 ---
const selectedRows = ref([]);
const selectedRowsMap = ref({});
const selectAllChecked = ref(false);

// --- 초기화 ---
onMounted(async () => {
  await fetchAvailableMonths();
  await fetchAllProducts();
});

// --- 데이터 조회 로직 ---
async function loadPerformanceData() {
  if (!selectedSettlementMonth.value) {
    alert('정산월을 선택해야 합니다.');
    return;
  }
  loading.value = true;
  displayRows.value = [];

  try {
    let query = supabase.from('v_review_details').select('*')
      .eq('settlement_month', selectedSettlementMonth.value);

    if (selectedCompanyId.value !== 'ALL') query.eq('company_id', selectedCompanyId.value);
    if (selectedHospitalId.value !== 'ALL') query.eq('client_id', selectedHospitalId.value);
    
    const prescriptionMonth = getPrescriptionMonth(selectedSettlementMonth.value, prescriptionOffset.value);
    if (prescriptionOffset.value !== 0) {
      query.eq('prescription_month', prescriptionMonth);
    }

    if (selectedReviewStatus.value === '신규') {
      const newRecordIds = await syncNewRecordsToAnalysis();
      if (newRecordIds.length === 0) {
        alert('처리할 신규 데이터가 없습니다.');
        loading.value = false;
        return;
      }
      query.in('performance_record_id', newRecordIds);

    } else if (selectedReviewStatus.value === 'ALL') {
      await syncNewRecordsToAnalysis();
    
    } else {
      query.eq('review_status', selectedReviewStatus.value);
    }
    
    const { data, error } = await query.order('id');
    if (error) throw error;
    
    displayRows.value = data.map(row => {
      const payment_amount = Math.round((row.price * row.prescription_qty) * row.commission_rate);
      return {
        ...row,
        price: row.price?.toLocaleString() || 0,
        prescription_qty: row.prescription_qty || 0,
        prescription_amount: row.prescription_amount?.toLocaleString() || 0,
        commission_rate: `${(row.commission_rate * 100).toFixed(1)}%`,
        payment_amount: payment_amount.toLocaleString(),
        created_date: formatDateTime(row.created_at),
      };
    });

    if (displayRows.value.length === 0) {
      alert('해당 조건에 맞는 데이터가 없습니다.');
    }

  } catch (err) {
    console.error('데이터 조회 오류:', err);
    alert('데이터 조회 중 오류가 발생했습니다.');
    displayRows.value = [];
  } finally {
    loading.value = false;
    selectedRows.value = [];
    selectedRowsMap.value = {};
    updateSelectAllState();
  }
}

async function syncNewRecordsToAnalysis() {
    let query = supabase
        .from('performance_records')
        .select('id')
        .eq('settlement_month', selectedSettlementMonth.value)
        .eq('user_edit_status', '대기');

    if (selectedCompanyId.value !== 'ALL') {
      query = query.eq('company_id', selectedCompanyId.value);
    }
    if (selectedHospitalId.value !== 'ALL') {
      query = query.eq('client_id', selectedHospitalId.value);
    }

    const { data: waitingRecords, error } = await query;
    
    if (error) throw error;
    if (!waitingRecords || waitingRecords.length === 0) {
      return [];
    }

    const newRecordIds = waitingRecords.map(r => r.id);
    const recordsToInsert = newRecordIds.map(id => ({ 
      performance_record_id: id, 
      review_status: '검수중',
      company_id_add: null 
    }));

    await supabase.from('absorption_analysis').insert(recordsToInsert).throwOnError();
    await supabase.from('performance_records').update({ user_edit_status: '검수중' }).in('id', newRecordIds).throwOnError();

    return newRecordIds;
}

// --- 필터 옵션 로딩 ---
async function fetchAvailableMonths() {
  try {
    const { data, error } = await supabase.from('settlement_months').select('settlement_month').order('settlement_month', { ascending: false });
    if (error) throw error;
    availableMonths.value = data;
    if (data.length > 0) {
      selectedSettlementMonth.value = data[0].settlement_month;
      await fetchCompaniesForMonth();
      updatePrescriptionOptions();
    }
  } catch (err) { console.error('정산월 조회 오류:', err); }
}

async function fetchAllProducts() {
    try {
        const { data, error } = await supabase.from('products').select('*').order('product_name');
        if (error) throw error;
        allProducts.value = data;
    } catch (e) { console.error('제품정보 로딩 오류', e)}
}

async function fetchCompaniesForMonth() {
  if (!selectedSettlementMonth.value) { companyOptions.value = [{ id: 'ALL', company_name: '- 전체 -' }]; return; }
  try {
    const { data, error } = await supabase.rpc('get_companies_for_review_filter', { 
      p_settlement_month: selectedSettlementMonth.value 
    });
    if (error) throw error;
    const uniqueCompanies = Array.from(new Set(data.map(item => JSON.stringify(item))))
                                .map(item => JSON.parse(item))
                                .sort((a, b) => a.company_name.localeCompare(b.company_name));
    companyOptions.value = [{ id: 'ALL', company_name: '- 전체 -' }, ...uniqueCompanies];
    selectedCompanyId.value = 'ALL';
    await fetchClientsForMonth();
  } catch (err) { console.error('해당 월의 업체 조회 오류:', err); companyOptions.value = [{ id: 'ALL', company_name: '- 전체 -' }]; }
}

async function fetchClientsForMonth() {
    if (!selectedSettlementMonth.value) { hospitalOptions.value = [{ id: 'ALL', name: '- 전체 -' }]; return; }
    try {
        const { data, error } = await supabase.rpc('get_clients_for_review_filter', { 
            p_settlement_month: selectedSettlementMonth.value,
            p_company_id: selectedCompanyId.value === 'ALL' ? null : selectedCompanyId.value
        });
        if (error) throw error;
        const uniqueClients = Array.from(new Set(data.map(item => JSON.stringify(item))))
                                  .map(item => JSON.parse(item))
                                  .sort((a, b) => a.name.localeCompare(b.name));
        hospitalOptions.value = [{ id: 'ALL', name: '- 전체 -' }, ...uniqueClients];
        selectedHospitalId.value = 'ALL';
    } catch (err) { console.error('해당 월의 병의원 조회 오류:', err); hospitalOptions.value = [{ id: 'ALL', name: '- 전체 -' }]; }
}

watch(selectedSettlementMonth, async (newMonth) => {
  if (newMonth) { 
    await fetchCompaniesForMonth(); 
    updatePrescriptionOptions(); 
    prescriptionOffset.value = 0;
  }
});
watch(selectedCompanyId, async () => { await fetchClientsForMonth(); });

// --- Helper Functions ---
function getActionSeverity(action) { return action === '수정' ? 'info' : action === '추가' ? 'success' : action === '삭제' ? 'danger' : 'secondary'; }
function getRowClass(data) { return data.review_action === '삭제' ? 'deleted-row' : data.review_action === '추가' ? 'added-row' : data.review_action === '수정' ? 'modified-row' : ''; }
function getPrescriptionMonth(settlementMonth, offset) { if (!settlementMonth || offset === null) return ''; let [y, m] = settlementMonth.split('-'); let month = parseInt(m, 10) - offset; let year = parseInt(y, 10); while (month <= 0) { month += 12; year -= 1; } return `${year}-${String(month).padStart(2, '0')}`; }
function updatePrescriptionOptions() { 
  prescriptionOptions.value = [
    { value: 0, month: '- 전체 -' },
    ...[1, 2, 3].map(offset => ({ 
      value: offset, 
      month: getPrescriptionMonth(selectedSettlementMonth.value, offset) 
    }))
  ];
}
function formatDateTime(dateTimeString) { if (!dateTimeString) return '-'; const date = new Date(dateTimeString); const kstOffset = 9 * 60 * 60 * 1000; const kstDate = new Date(date.getTime() + kstOffset); return kstDate.toISOString().slice(0, 16).replace('T', ' '); }

// --- Table Row Selection ---
function onRowSelectChange(rowData, isSelected) { if (isSelected) { selectedRowsMap.value[rowData.id] = true; selectedRows.value.push(rowData); } else { delete selectedRowsMap.value[rowData.id]; selectedRows.value = selectedRows.value.filter(row => row.id !== rowData.id); } updateSelectAllState(); }
function updateSelectAllState() { const selectableRows = displayRows.value.filter(row => row.review_action !== '삭제'); selectAllChecked.value = selectableRows.length > 0 && selectableRows.every(row => selectedRowsMap.value[row.id]); }
function toggleSelectAll() { const selectableRows = displayRows.value.filter(row => row.review_action !== '삭제'); if (selectAllChecked.value) { selectableRows.forEach(row => { if (!selectedRowsMap.value[row.id]) { selectedRowsMap.value[row.id] = true; selectedRows.value.push(row); } }); } else { selectedRows.value = []; selectedRowsMap.value = {}; } }
function selectAll() { selectAllChecked.value = true; toggleSelectAll(); }
function unselectAll() { selectAllChecked.value = false; toggleSelectAll(); }

// --- Table Row Actions (No Reload) ---
function getUniqueProductsByMonth(month) {
  const monthProducts = allProducts.value.filter(p => p.base_month === month);
  const uniqueProducts = new Map();
  monthProducts.forEach(p => {
    if (!uniqueProducts.has(p.insurance_code)) {
      uniqueProducts.set(p.insurance_code, p);
    }
  });
  return Array.from(uniqueProducts.values());
}

function startEdit(row) {
  if (row.review_status === '완료') return;
  row.originalData = JSON.parse(JSON.stringify(row));
  
  row.availableProducts = getUniqueProductsByMonth(row.prescription_month);

  const currentFullProduct = allProducts.value.find(p => p.id === row.product_id);
  if (currentFullProduct) {
    const representativeProduct = row.availableProducts.find(p => p.insurance_code === currentFullProduct.insurance_code);
    row.product_id_modify = representativeProduct ? representativeProduct.id : null;
  } else {
    row.product_id_modify = null;
  }
  
  row.prescription_month_modify = row.prescription_month;
  row.prescription_qty_modify = parseFloat(String(row.prescription_qty).replace(/,/g, '')) || 0;
  row.prescription_type_modify = row.prescription_type;
  row.remarks_modify = row.remarks;
  
  row.commission_rate_modify = parseFloat(String(row.commission_rate).replace('%', '')) || 0;
  
  row.price_for_calc = parseFloat(String(row.price).replace(/,/g, ''));
  row.prescription_amount_modify = parseFloat(String(row.prescription_amount).replace(/,/g, ''));
  row.payment_amount_modify = parseFloat(String(row.payment_amount).replace(/,/g, ''));

  row.isEditing = true;
}

function handleEditCalculations(row, changedField = '') {
  if (changedField === 'month') {
    const currentProductInfo = allProducts.value.find(p => p.id === row.product_id_modify);
    const currentInsuranceCode = currentProductInfo ? currentProductInfo.insurance_code : null;

    row.availableProducts = getUniqueProductsByMonth(row.prescription_month_modify);
    
    if (currentInsuranceCode) {
        const newRepresentativeProduct = row.availableProducts.find(p => p.insurance_code === currentInsuranceCode);
        if (newRepresentativeProduct) {
            row.product_id_modify = newRepresentativeProduct.id;
        } else {
            row.product_id_modify = null;
        }
    }
  }

  if (changedField === 'month' || changedField === 'product') {
    if (row.product_id_modify) {
        const product = allProducts.value.find(p => p.id === row.product_id_modify);
        if (product) {
            row.price_for_calc = product.price;
            row.insurance_code = product.insurance_code;
            const commissionGrade = (row.company_commission_grade || 'a').toLowerCase();
            const rateKey = `commission_rate_${commissionGrade}`;
            row.commission_rate_modify = (product[rateKey] || 0) * 100;
        }
    } else {
        row.insurance_code = '';
        row.price_for_calc = 0;
        row.commission_rate_modify = 0;
    }
  }

  const price = row.price_for_calc || 0;
  const qty = row.prescription_qty_modify || 0;
  const rate = (row.commission_rate_modify || 0) / 100;
  
  const prescriptionAmount = price * qty;
  const paymentAmount = prescriptionAmount * rate;

  row.prescription_amount_modify = Math.round(prescriptionAmount);
  row.payment_amount_modify = Math.round(paymentAmount);
}

function cancelEdit(row) {
    if (row.isNewRow) {
        displayRows.value = displayRows.value.filter(r => r.id !== row.id);
    } else {
        const originalRow = row.originalData;
        const index = displayRows.value.findIndex(r => r.id === originalRow.id);
        if (index !== -1) {
            displayRows.value.splice(index, 1, originalRow);
        }
    }
}

async function saveEdit(row) {
    try {
        if (row.isNewRow) {
            const recordData = {
                company_id_add: row.company_id,
                client_id_add: row.client_id,
                settlement_month_add: selectedSettlementMonth.value,
                prescription_month_modify: row.prescription_month_modify,
                product_id_modify: row.product_id_modify,
                prescription_qty_modify: row.prescription_qty_modify,
                prescription_type_modify: row.prescription_type_modify,
                commission_rate_modify: (row.commission_rate_modify || 0) / 100,
                remarks_modify: row.remarks_modify,
                review_status: '검수중',
                review_action: '추가',
            };
            const { data: insertedData, error } = await supabase.from('absorption_analysis').insert(recordData).select().single();
            if (error) throw error;
            
            const { data: newRowData, error: fetchError } = await supabase.from('v_review_details').select('*').eq('id', insertedData.id).single();
            if (fetchError) throw fetchError;
            
            const index = displayRows.value.findIndex(r => r.id === row.id);
            if (index !== -1) {
              const formattedData = {
                ...newRowData,
                price: newRowData.price?.toLocaleString() || 0,
                prescription_qty: newRowData.prescription_qty || 0,
                prescription_amount: newRowData.prescription_amount?.toLocaleString() || 0,
                commission_rate: `${(newRowData.commission_rate * 100).toFixed(1)}%`,
                payment_amount: Math.round((newRowData.price * newRowData.prescription_qty) * newRowData.commission_rate).toLocaleString(),
                created_date: formatDateTime(newRowData.created_at),
              };
              displayRows.value.splice(index, 1, formattedData);
            }
        } else {
            // Existing update logic
            const recordData = {
                prescription_month_modify: row.prescription_month_modify,
                product_id_modify: row.product_id_modify,
                prescription_qty_modify: row.prescription_qty_modify,
                prescription_type_modify: row.prescription_type_modify,
                commission_rate_modify: (row.commission_rate_modify || 0) / 100,
                remarks_modify: row.remarks_modify,
                review_action: '수정',
            };

            if (row.performance_record_id) {
                recordData.company_id_add = null;
            }

            const { error } = await supabase.from('absorption_analysis').update(recordData).eq('id', row.id);
            if (error) throw error;
            
            const finalProduct = allProducts.value.find(p => p.id === row.product_id_modify);

            const updatedRowInPlace = {
                ...row.originalData,
                product_id: row.product_id_modify,
                product_name_display: finalProduct ? finalProduct.product_name : '제품 없음',
                insurance_code: finalProduct ? finalProduct.insurance_code : '',
                price: (row.price_for_calc || 0).toLocaleString(),
                prescription_month: row.prescription_month_modify,
                prescription_qty: row.prescription_qty_modify,
                prescription_type: row.prescription_type_modify,
                commission_rate: `${(row.commission_rate_modify || 0).toFixed(1)}%`,
                prescription_amount: (row.prescription_amount_modify || 0).toLocaleString(),
                payment_amount: (row.payment_amount_modify || 0).toLocaleString(),
                remarks: row.remarks_modify,
                review_action: '수정',
                isEditing: false,
            };
            
            if (updatedRowInPlace.performance_record_id) {
                updatedRowInPlace.company_id_add = null;
            }

            const index = displayRows.value.findIndex(r => r.id === row.id);
            if (index !== -1) {
              displayRows.value.splice(index, 1, updatedRowInPlace);
            }
        }
    } catch (err) {
        console.error('저장 오류:', err);
        alert('저장 중 오류가 발생했습니다.');
        cancelEdit(row);
    }
}

function addRowBelow(currentRow) {
  const newRowId = `new_${Date.now()}`;
  const newRow = {
    id: newRowId,
    isEditing: true,
    isNewRow: true,
    
    company_id: currentRow.company_id,
    company_name: currentRow.company_name,
    client_id: currentRow.client_id,
    client_name: currentRow.client_name,
    company_commission_grade: currentRow.company_commission_grade,
    prescription_month_modify: currentRow.prescription_month,
    prescription_type_modify: currentRow.prescription_type,
    
    product_id_modify: null,
    insurance_code: '',
    price_for_calc: 0,
    prescription_qty_modify: 0,
    commission_rate_modify: 0,
    remarks_modify: '',
    prescription_amount_modify: 0,
    payment_amount_modify: 0,
    review_status: '검수중',
    review_action: '추가',
    availableProducts: [], 
  };
  
  newRow.availableProducts = getUniqueProductsByMonth(newRow.prescription_month_modify);

  const currentIndex = displayRows.value.findIndex(r => r.id === currentRow.id);
  if (currentIndex !== -1) {
    displayRows.value.splice(currentIndex + 1, 0, newRow);
  }
}

async function confirmDeleteRow(row) {
    if (confirm('이 실적을 삭제 처리하시겠습니까? (목록에서만 삭제 처리됩니다)')) {
        try {
            const { error } = await supabase.from('absorption_analysis').update({ review_action: '삭제' }).eq('id', row.id);
            if (error) throw error;
            const index = displayRows.value.findIndex(r => r.id === row.id);
            if (index !== -1) {
                displayRows.value[index].review_action = '삭제';
            }
        } catch (err) {
            console.error('삭제 처리 오류:', err);
            alert(`삭제 처리 중 오류가 발생했습니다: ${err.message}`);
        }
    }
}

async function restoreRow(row) {
    if (confirm('이 실적의 삭제를 취소하시겠습니까?')) {
        try {
            const { error } = await supabase.from('absorption_analysis').update({ review_action: null }).eq('id', row.id);
            if (error) throw error;
            const index = displayRows.value.findIndex(r => r.id === row.id);
            if (index !== -1) {
                displayRows.value[index].review_action = null;
            }
        } catch (err) {
            console.error('삭제 취소 오류:', err);
            alert(`삭제 취소 처리 중 오류가 발생했습니다: ${err.message}`);
        }
    }
}

async function changeReviewStatus() {
  if (selectedRows.value.length === 0) return;
  const reviewingRows = selectedRows.value.filter(r => r.review_status === '검수중');
  const completedRows = selectedRows.value.filter(r => r.review_status === '완료');
  if (!confirm('선택된 항목들의 검수 상태를 변경하시겠습니까?')) return;
  loading.value = true;
  
  try {
    const promises = [];
    if (reviewingRows.length > 0) {
      const ids = reviewingRows.map(r => r.id);
      promises.push(supabase.from('absorption_analysis').update({ review_status: '완료' }).in('id', ids));
      const perfIds = reviewingRows.map(r => r.performance_record_id).filter(Boolean);
      if(perfIds.length > 0) promises.push(supabase.from('performance_records').update({ user_edit_status: '완료' }).in('id', perfIds));
    }
    if (completedRows.length > 0) {
      const ids = completedRows.map(r => r.id);
      promises.push(supabase.from('absorption_analysis').update({ review_status: '검수중' }).in('id', ids));
      const perfIds = completedRows.map(r => r.performance_record_id).filter(Boolean);
      if(perfIds.length > 0) promises.push(supabase.from('performance_records').update({ user_edit_status: '검수중' }).in('id', perfIds));
    }
    await Promise.all(promises);
    alert('상태가 성공적으로 변경되었습니다.');

    const reviewingIds = new Set(reviewingRows.map(r => r.id));
    const completedIds = new Set(completedRows.map(r => r.id));

    displayRows.value.forEach(row => {
      if (reviewingIds.has(row.id)) {
        row.review_status = '완료';
      } else if (completedIds.has(row.id)) {
        row.review_status = '검수중';
      }
    });
    
    selectedRows.value = [];
    selectedRowsMap.value = {};
    updateSelectAllState();

  } catch (err) {
    alert(`상태 변경 중 오류가 발생했습니다: ${err.message}`);
    console.error(err);
  } finally {
    loading.value = false;
  }
}

async function removeFromReview() {
  if (selectedRows.value.length === 0) return;
  if (!confirm(`선택된 ${selectedRows.value.length}건을 검수 대상에서 제외하시겠습니까?`)) return;
  loading.value = true;
  try {
    const idsToDelete = selectedRows.value.map(r => r.id);
    const perfIdsToUpdate = selectedRows.value.map(r => r.performance_record_id).filter(Boolean);
    if (perfIdsToUpdate.length > 0) await supabase.from('performance_records').update({ user_edit_status: '대기' }).in('id', perfIdsToUpdate).throwOnError();
    await supabase.from('absorption_analysis').delete().in('id', idsToDelete).throwOnError();
    
    const idsToDeleteSet = new Set(idsToDelete);
    displayRows.value = displayRows.value.filter(row => !idsToDeleteSet.has(row.id));
    selectedRows.value = [];
    selectedRowsMap.value = {};
    updateSelectAllState();
    alert('선택한 항목들이 검수에서 제외되었습니다.');
  } catch(err) {
     alert(`검수 제외 처리 중 오류가 발생했습니다: ${err.message}`);
     console.error(err);
  } finally {
    loading.value = false;
  }
}
</script>

<style scoped>
/* 기본 select 스타일 추가 */

.performance-review-view { padding: 0px; }
.data-card-buttons { display: flex; gap: 8px; }

/* Edit mode styles */
.edit-mode-input { width: 100%; }

/* Row status styles */
.admin-performance-review-table :deep(.added-row td) {
  background-color: #e7f5ff !important;
}
.admin-performance-review-table :deep(.modified-row td) {
  background-color: #fffde7 !important;
}
.admin-performance-review-table :deep(.deleted-row td) {
  background-color: #fff5f5 !important;
}

.admin-performance-review-table :deep(.deleted-row td:nth-child(n+5)) {
    color: #aaa !important;
    text-decoration: line-through;
}

.admin-performance-review-table :deep(.deleted-row td:nth-child(4)) {
  text-decoration: none !important;
}

.btn-restore-sm { 
  background-color: #28a745; 
  color: white; 
  border: none; 
  padding: 0;
  border-radius: 3px; 
  font-size: 18px;
  line-height: 1;
  cursor: pointer; 
  width: 26px; 
  height: 24px; 
  min-width: 26px; 
  text-align: center; 
  display: inline-flex; 
  align-items: center; 
  justify-content: center; 
}
.btn-restore-sm:hover { background-color: #218838; }
</style>
