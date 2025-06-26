<template>
  <div class="performance-review-view page-container" style="display: flex; flex-direction: column; height: 100vh;">
    <div class="page-header-title-area" style="flex-shrink: 0;">
      <div class="header-title">실적 검수</div>
    </div>

    <!-- 필터 카드 -->
    <div class="filter-card" style="flex-shrink: 0;" :class="{ 'disabled-area': isAnyEditing }">
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
      </div>
    </div>

    <!-- 데이터 카드 -->
    <div class="data-card" style="flex-grow: 1; display: flex; flex-direction: column; overflow: hidden;">
      <div class="data-card-header" style="flex-shrink: 0;">
        <div class="total-count-display">전체 {{ displayRows.length }} 건</div>
        <div v-if="!loading && displayRows.length === 0" class="header-center-message">
          필터 조건을 선택하고 '실적 정보 불러오기'를 클릭하세요.
        </div>
        <div class="data-card-buttons" style="margin-left: auto;">
           <button 
            class="btn-primary" 
            @click="loadPerformanceData" 
            :disabled="loading || isAnyEditing"
          >
            실적 정보 불러오기
          </button>
           <button class="btn-secondary" @click="selectAll" :disabled="isAnyEditing">전체 선택</button>
           <button class="btn-secondary" @click="unselectAll" :disabled="isAnyEditing">전체 해제</button>
           <button class="btn-primary" @click="changeReviewStatus" :disabled="selectedRows.length === 0 || isAnyEditing">
             검수 상태 변경 ({{ selectedRows.length }}건)
           </button>
           <button class="btn-warning" @click="removeFromReview" :disabled="selectedRows.length === 0 || isAnyEditing">
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
            wrapper: { style: 'min-width: 2400px;' },
            table: { style: 'min-width: 2400px;' }
          }"
          dataKey="id"
        >
          <template #empty>
            <div v-if="loading">데이터를 불러오는 중입니다.</div>
            <div v-else>필터 조건을 선택하고 '실적 정보 불러오기'를 클릭하세요.</div>
          </template>
          
          <Column :headerStyle="{ width: columnWidths.checkbox }">
            <template #header>
              <span style="font-weight: 500 !important; text-align: center !important; margin-left: 10px !important;">선택</span>
            </template>
            <template #body="slotProps">
              <Checkbox v-model="selectedRows" :value="slotProps.data" :disabled="slotProps.data.review_action === '삭제'" />
            </template>
          </Column>

          <Column header="상태" field="user_edit_status" :headerStyle="{ width: columnWidths.review_status }" :frozen="true">
            <template #body="slotProps">
              <Tag :value="slotProps.data.user_edit_status" :severity="slotProps.data.user_edit_status === '완료' ? 'success' : 'warning'"/>
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
                  <button class="btn-restore-sm" @click="restoreRow(slotProps.data)" title="되돌리기" :disabled="isAnyEditing">↶</button>
                </template>
                <template v-else>
                  <button class="btn-edit-sm" @click="startEdit(slotProps.data)" title="수정" :disabled="slotProps.data.user_edit_status === '완료' || isAnyEditing">✎</button>
                  <button class="btn-delete-sm" @click="confirmDeleteRow(slotProps.data)" title="삭제" :disabled="slotProps.data.user_edit_status === '완료' || isAnyEditing">－</button>
                  <button class="btn-add-sm" @click="addRowBelow(slotProps.data)" title="추가" :disabled="isAnyEditing">＋</button>
                </template>
              </div>
            </template>
          </Column>

          <Column field="company_name" header="업체명" :headerStyle="{ width: columnWidths.company_name }" :sortable="true" />
          <Column field="client_name" header="병의원명" :headerStyle="{ width: columnWidths.client_name }" :sortable="true" />
          
          <Column field="prescription_month" header="처방월" :headerStyle="{ width: columnWidths.prescription_month }" :sortable="true">
            <template #body="slotProps">
              <select v-if="slotProps.data.isEditing"
                      v-model="slotProps.data.prescription_month_modify"
                      class="edit-mode-input"
                      :ref="el => setFieldRef(slotProps.data.id, 'prescription_month', el)"
                      @keydown.enter.prevent="handlePrescriptionMonthSelect(slotProps.data)"
                      @keydown.tab.prevent="handleTabNavigation(slotProps.data, 'prescription_month', $event)"
                      @keydown.down.prevent="handlePrescriptionMonthDownKey(slotProps.data, $event)"
                      @keydown.up.prevent="handlePrescriptionMonthUpKey(slotProps.data, $event)"
                      @keydown.left.prevent="handleArrowNavigation(slotProps.data, 'prescription_month', 'left')"
                      @keydown.right.prevent="handleArrowNavigation(slotProps.data, 'prescription_month', 'right')"
                      @focus="handlePrescriptionMonthFocus(slotProps.data)"
                      @change="handleEditCalculations(slotProps.data, 'month')"
              >
                <option v-for="month in prescriptionMonthOptionsForEdit" :key="month" :value="month">{{ month }}</option>
              </select>
              <span v-else>{{ slotProps.data.prescription_month }}</span>
            </template>
          </Column>
          <Column field="product_name_display" header="제품명" :headerStyle="{ width: columnWidths.product_name_display }" :sortable="true"  :frozen="true">
            <template #body="slotProps">
              <template v-if="slotProps.data.isEditing">
                <div class="product-input-container">
                  <input
                    v-model="slotProps.data.product_name_search"
                    @input="handleProductNameInput(slotProps.data, $event)"
                    @keydown.enter.prevent="applySelectedProductFromSearch(slotProps.data)"
                    @keydown.tab.prevent="handleTabNavigation(slotProps.data, 'product_name', $event)"
                    @keydown.down.prevent="handleProductNameDownKey(slotProps.data, $event)"
                    @keydown.up.prevent="handleProductNameUpKey(slotProps.data, $event)"
                    @keydown.left.prevent="handleArrowNavigation(slotProps.data, 'product_name', 'left')"
                    @keydown.right.prevent="handleArrowNavigation(slotProps.data, 'product_name', 'right')"
                    @focus="handleProductNameFocus(slotProps.data)"
                    @blur="setTimeout(() => hideProductSearchList(slotProps.data), 200)"
                    autocomplete="off"
                    class="edit-mode-input"
                    :class="cellClass(rowIdx, 'product_name')"
                    :ref="el => setProductInputRef(slotProps.data.id, el)"
                  />
                  <button 
                    type="button" 
                    @click="toggleProductDropdown(slotProps.data)"
                    @mousedown.prevent
                    class="dropdown-arrow-btn"
                    tabindex="-1"
                  >
                    <span class="dropdown-arrow">▼</span>
                  </button>
                  <teleport to="body">
                    <div v-if="slotProps.data.showProductSearchList && productDropdownStyle[slotProps.data.id]"
                      class="product-search-list"
                      :style="{ ...productDropdownStyle[slotProps.data.id], zIndex: 1002 }"
                    >
                      <div
                        v-for="(product, idx) in slotProps.data.productSearchResults"
                        :key="product.id"
                        :class="['product-search-item', { selected: idx === slotProps.data.productSearchSelectedIndex }]"
                        @mousedown.prevent="applySelectedProduct(product, slotProps.data)"
                      >
                        {{ product.product_name }} ({{ product.insurance_code }})
                      </div>
                    </div>
                  </teleport>
                </div>
              </template>
              <template v-else>
                <span>{{ slotProps.data.product_name_display }}</span>
              </template>
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
              <input
                v-if="slotProps.data.isEditing"
                v-model="slotProps.data.prescription_qty_modify"
                type="number"
                class="edit-mode-input"
                :class="cellClass(rowIdx, 'prescription_qty')"
                :ref="el => setFieldRef(slotProps.data.id, 'prescription_qty', el)"
                @keydown.enter.prevent="handleTabNavigation(slotProps.data, 'prescription_qty', $event)"
                @keydown.tab.prevent="handleTabNavigation(slotProps.data, 'prescription_qty', $event)"
                @keydown.left.prevent="handleArrowNavigation(slotProps.data, 'prescription_qty', 'left')"
                @keydown.right.prevent="handleArrowNavigation(slotProps.data, 'prescription_qty', 'right')"
                @change="handleEditCalculations(slotProps.data, 'qty')"
              />
              <span v-else>{{ Number(slotProps.data.prescription_qty).toLocaleString() }}</span>
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
              <select
                v-if="slotProps.data.isEditing"
                v-model="slotProps.data.prescription_type_modify"
                class="edit-mode-input"
                :ref="el => setFieldRef(slotProps.data.id, 'prescription_type', el)"
                @keydown.enter.prevent="handlePrescriptionTypeSelect(slotProps.data)"
                @keydown.tab.prevent="handleTabNavigation(slotProps.data, 'prescription_type', $event)"
                @keydown.down.prevent="handlePrescriptionTypeDownKey(slotProps.data, $event)"
                @keydown.up.prevent="handlePrescriptionTypeUpKey(slotProps.data, $event)"
                @keydown.left.prevent="handleArrowNavigation(slotProps.data, 'prescription_type', 'left')"
                @keydown.right.prevent="handleArrowNavigation(slotProps.data, 'prescription_type', 'right')"
                @focus="handlePrescriptionTypeFocus(slotProps.data)"
              >
                <option v-for="type in prescriptionTypeOptions" :key="type" :value="type">{{ type }}</option>
              </select>
              <span v-else>{{ slotProps.data.prescription_type }}</span>
            </template>
          </Column>
          <Column field="commission_rate" header="수수료율" :headerStyle="{ width: columnWidths.commission_rate }" :sortable="true">
            <template #body="slotProps">
              <input
                v-if="slotProps.data.isEditing"
                v-model="slotProps.data.commission_rate_modify"
                type="number"
                step="0.1"
                class="edit-mode-input"
                :class="cellClass(rowIdx, 'commission_rate')"
                :ref="el => setFieldRef(slotProps.data.id, 'commission_rate', el)"
                @keydown.enter.prevent="handleTabNavigation(slotProps.data, 'commission_rate', $event)"
                @keydown.tab.prevent="handleTabNavigation(slotProps.data, 'commission_rate', $event)"
                @keydown.left.prevent="handleArrowNavigation(slotProps.data, 'commission_rate', 'left')"
                @keydown.right.prevent="handleArrowNavigation(slotProps.data, 'commission_rate', 'right')"
                @change="handleEditCalculations(slotProps.data, 'rate')"
              />
              <span v-else>{{ String(slotProps.data.commission_rate).replace('%','') }}%</span>
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
              <input
                v-if="slotProps.data.isEditing"
                v-model="slotProps.data.remarks_modify"
                class="edit-mode-input"
                :class="cellClass(rowIdx, 'remarks')"
                :ref="el => setFieldRef(slotProps.data.id, 'remarks', el)"
                @keydown.enter.prevent="handleTabNavigation(slotProps.data, 'remarks', $event)"
                @keydown.tab.prevent="handleTabNavigation(slotProps.data, 'remarks', $event)"
                @keydown.left.prevent="handleArrowNavigation(slotProps.data, 'remarks', 'left')"
                @keydown.right.prevent="handleArrowNavigation(slotProps.data, 'remarks', 'right')"
              />
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
import { ref, computed, onMounted, watch, getCurrentInstance, onBeforeUnmount, nextTick } from 'vue';
import { useRouter } from 'vue-router';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Checkbox from 'primevue/checkbox';
import Tag from 'primevue/tag';
import Dropdown from 'primevue/dropdown';
import InputNumber from 'primevue/inputnumber';
import InputText from 'primevue/inputtext';
import { supabase } from '@/supabase';

const router = useRouter();

const columnWidths = {
  checkbox: '2.5%',
  review_status: '2.5%',
  review_action: '2.5%',
  actions: '5%',
  company_name: '7%',
  client_name: '10%',
  prescription_month: '4.5%',
  product_name_display: '12%',
  insurance_code: '4.5%',
  price: '3.5%',
  prescription_qty: '3.5%',
  prescription_amount: '4%',
  prescription_type: '5%',
  commission_rate: '4%',
  payment_amount: '4%',
  remarks: '10%',
  created_date: '6%',
  created_by: '7%'
};

// --- 상태 변수 ---
const loading = ref(false);
const displayRows = ref([]);
const availableMonths = ref([]);
const companyOptions = ref([]);
const hospitalOptions = ref([]);
const allProducts = ref([]);

const prescriptionMonthOptionsForEdit = computed(() => {
  if (!selectedSettlementMonth.value) return [];
  const options = [];
  const [year, month] = selectedSettlementMonth.value.split('-').map(Number);
  // 현재 월의 -1, -2, -3개월을 계산
  for (let i = 1; i <= 3; i++) {
    const d = new Date(year, month - 1 - i, 15); // 일을 15일로 설정하여 월 계산 오류 방지
    options.push(`${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`);
  }
  return options;
});

// 현재 열려있는 드롭다운 추적
const activeDropdown = ref({ rowId: null, type: null });

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

const statusOptions = ['전체', '대기', '검수중', '완료'];

const prescriptionTypeOptions = [
  'EDI',
  'ERP직거래자료',
  '매출자료',
  '약국조제',
  '원내매출',
  '원외매출',
  '차감',
];

// --- 선택 관련 ---
const selectedRows = ref([]); // PrimeVue DataTable의 v-model:selection에 연결
const selectAllChecked = ref(false);

const productInputRefs = ref({});
const productDropdownStyle = ref({});
const fieldRefs = ref({});

// 1. currentCell 구조 추가
const currentCell = ref({ row: null, col: null });

// --- 초기화 ---
onMounted(async () => {
  await fetchAvailableMonths();
  await fetchAllProducts();
  document.addEventListener('click', handleGlobalClick);
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
    let query = supabase.from('review_details_view').select('*')
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
      // 동기화 후 '검수중' 상태로 데이터를 다시 조회
      query.in('performance_record_id', newRecordIds).eq('user_edit_status', '검수중');

    } else if (selectedReviewStatus.value === 'ALL') {
      // '전체'일 경우, 먼저 신규 데이터를 동기화
      await syncNewRecordsToAnalysis();
    
    } else {
      // '완료' 또는 '검수중'
      query.eq('user_edit_status', selectedReviewStatus.value);
    }
    
    const { data, error } = await query;
    if (error) throw error;
    
    let mappedData = data.map(row => {
      const payment_amount = Math.round((row.price * row.prescription_qty) * (row.commission_rate || 0));
      return {
        ...row,
        id: row.absorption_analysis_id, // Ensure consistent ID for all operations
        price: row.price?.toLocaleString() || 0,
        prescription_qty: row.prescription_qty || 0,
        prescription_amount: row.prescription_amount?.toLocaleString() || 0,
        commission_rate: `${((row.commission_rate || 0) * 100).toFixed(1)}%`,
        payment_amount: payment_amount.toLocaleString(),
        created_date: formatDateTime(row.created_at),
      };
    });

    const statusOrder = { '검수중': 1, '완료': 2 };
    const actionOrder = { '추가': 2, '수정': 3, '삭제': 4 };

    mappedData.sort((a, b) => {
      const orderA_status = statusOrder[a.user_edit_status] || 99;
      const orderB_status = statusOrder[b.user_edit_status] || 99;
      if (orderA_status !== orderB_status) return orderA_status - orderB_status;

      const orderA_action = actionOrder[a.review_action] || 1;
      const orderB_action = actionOrder[b.review_action] || 1;
      if (orderA_action !== orderB_action) return orderA_action - orderB_action;

      if (a.company_name !== b.company_name) return a.company_name.localeCompare(b.company_name, 'ko');
      if (a.client_name !== b.client_name) return a.client_name.localeCompare(b.client_name, 'ko');
      if (a.product_name_display !== b.product_name_display) return a.product_name_display.localeCompare(b.product_name_display, 'ko');

      return (b.prescription_qty || 0) - (a.prescription_qty || 0);
    });

    displayRows.value = mappedData;

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
      company_id_add: null,
      client_id_add: null
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
    const { data, error } = await supabase
      .from('products')
      .select('id, product_name, insurance_code, price, base_month, status, commission_rate_a, commission_rate_b')
      .eq('status', 'active');
    if (error) throw error;
    allProducts.value = data;
  } catch (e) {
    console.error('제품정보 로딩 오류', e);
  }
}

async function fetchCompaniesForMonth() {
  if (!selectedSettlementMonth.value) { 
    companyOptions.value = [{ id: 'ALL', company_name: '- 전체 -' }]; 
    return; 
  }
  try {
    const { data, error } = await supabase.rpc('get_companies_for_review_filters', { 
      p_settlement_month: selectedSettlementMonth.value 
    });
    if (error) throw error;
    companyOptions.value = [{ id: 'ALL', company_name: '- 전체 -' }, ...data];
    selectedCompanyId.value = 'ALL';
    await fetchClientsForMonth();
  } catch (err) { 
    console.error('해당 월의 업체 조회 오류:', err); 
    companyOptions.value = [{ id: 'ALL', company_name: '- 전체 -' }]; 
  }
}

async function fetchClientsForMonth() {
    if (!selectedSettlementMonth.value) { 
      hospitalOptions.value = [{ id: 'ALL', name: '- 전체 -' }]; 
      return; 
    }
    try {
        const { data, error } = await supabase.rpc('get_clients_for_review_filters', { 
            p_settlement_month: selectedSettlementMonth.value,
            p_company_id: selectedCompanyId.value === 'ALL' ? null : selectedCompanyId.value
        });
        if (error) throw error;
        hospitalOptions.value = [{ id: 'ALL', name: '- 전체 -' }, ...data];
        selectedHospitalId.value = 'ALL';
    } catch (err) { 
      console.error('해당 월의 병의원 조회 오류:', err); 
      hospitalOptions.value = [{ id: 'ALL', name: '- 전체 -' }]; 
    }
}

watch(selectedSettlementMonth, async (newMonth, oldMonth) => {
  if (newMonth !== oldMonth) {
    await fetchAllProducts();
    updatePrescriptionOptions();
  }
});

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
function selectAll() { 
  const selectableRows = displayRows.value.filter(row => row.review_action !== '삭제');
  selectedRows.value = [...selectableRows];
}
function unselectAll() { 
  selectedRows.value = [];
}

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
  if (row.user_edit_status === '완료') return;
  row.originalData = JSON.parse(JSON.stringify(row));
  
  const currentProduct = allProducts.value.find(p => p.id === row.product_id);
  
  row.product_name_search = row.product_name_display || '';
  row.product_id_modify = row.product_id; // Keep original product ID initially
  row.productSearchResults = [];
  row.productSearchSelectedIndex = -1;
  row.showProductSearchList = false;
  
  row.availableProducts = getUniqueProductsByMonth(row.prescription_month);

  // 수정모드 진입 시, 현재 제품이 해당 처방월의 대표제품 ID와 다를 수 있으므로 보험코드로 동기화
  if (currentProduct) {
    const representativeProduct = row.availableProducts.find(p => p.insurance_code === currentProduct.insurance_code);
    row.product_id_modify = representativeProduct ? representativeProduct.id : row.product_id;
  }
  
  row.prescription_month_modify = row.prescription_month;
  row.prescription_qty_modify = parseFloat(String(row.prescription_qty).replace(/,/g, '')) || 0;
  row.prescription_type_modify = row.prescription_type;
  row.remarks_modify = row.remarks;
  
  row.commission_rate_modify = parseFloat(String(row.commission_rate).replace('%', '')) || 0;
  
  row.price_for_calc = currentProduct ? currentProduct.price : parseFloat(String(row.price).replace(/,/g, ''));
  row.prescription_amount_modify = parseFloat(String(row.prescription_amount).replace(/,/g, ''));
  row.payment_amount_modify = parseFloat(String(row.payment_amount).replace(/,/g, ''));

  row.isEditing = true;
  nextTick(() => {
    if (productInputRefs.value[row.id]) productInputRefs.value[row.id].focus();
  });
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
            
            const { data: newRowData, error: fetchError } = await supabase.from('review_details_view').select('*').eq('absorption_analysis_id', insertedData.id).single();
            if (fetchError) throw fetchError;
            
            const index = displayRows.value.findIndex(r => r.id === row.id);
            if (index !== -1) {
              const formattedData = {
                ...newRowData,
                id: newRowData.absorption_analysis_id, // Ensure new row also uses consistent ID
                price: newRowData.price?.toLocaleString() || 0,
                prescription_qty: newRowData.prescription_qty || 0,
                prescription_amount: newRowData.prescription_amount?.toLocaleString() || 0,
                commission_rate: `${((newRowData.commission_rate || 0) * 100).toFixed(1)}%`,
                payment_amount: Math.round((newRowData.price * newRowData.prescription_qty) * (newRowData.commission_rate || 0)).toLocaleString(),
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
    prescription_month: currentRow.prescription_month,
    prescription_type_modify: currentRow.prescription_type,
    
    product_id_modify: null,
    insurance_code: '',
    price_for_calc: 0,
    prescription_qty_modify: 0,
    commission_rate_modify: 0,
    remarks_modify: '',
    prescription_amount_modify: 0,
    payment_amount_modify: 0,
    user_edit_status: '검수중',
    review_action: '추가',
    availableProducts: [], 
  };
  
  newRow.availableProducts = getUniqueProductsByMonth(newRow.prescription_month_modify);

  const currentIndex = displayRows.value.findIndex(r => r.id === currentRow.id);
  if (currentIndex !== -1) {
    displayRows.value.splice(currentIndex + 1, 0, newRow);
  }
  nextTick(() => {
    if (productInputRefs.value[newRowId]) productInputRefs.value[newRowId].focus();
  });
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
  const reviewingRows = selectedRows.value.filter(r => r.user_edit_status === '검수중');
  const completedRows = selectedRows.value.filter(r => r.user_edit_status === '완료');
  if (!confirm('선택된 항목들의 검수 상태를 변경하시겠습니까?')) return;
  loading.value = true;
  
  try {
    const promises = [];

    // '검수중' -> '완료'로 변경
    if (reviewingRows.length > 0) {
      const absorptionIds = reviewingRows.map(r => r.id);
      promises.push(supabase.from('absorption_analysis').update({ review_status: '완료' }).in('id', absorptionIds));
      
      const performanceRecordIds = reviewingRows.map(r => r.performance_record_id).filter(Boolean);
      if (performanceRecordIds.length > 0) {
        promises.push(supabase.from('performance_records').update({ user_edit_status: '완료' }).in('id', performanceRecordIds));
      }
    }

    // '완료' -> '검수중'으로 변경
    if (completedRows.length > 0) {
      const absorptionIds = completedRows.map(r => r.id);
      promises.push(supabase.from('absorption_analysis').update({ review_status: '검수중' }).in('id', absorptionIds));

      const performanceRecordIds = completedRows.map(r => r.performance_record_id).filter(Boolean);
      if (performanceRecordIds.length > 0) {
        promises.push(supabase.from('performance_records').update({ user_edit_status: '검수중' }).in('id', performanceRecordIds));
      }
    }

    await Promise.all(promises);
    alert('상태가 성공적으로 변경되었습니다.');

    const reviewingIds = new Set(reviewingRows.map(r => r.id));
    const completedIds = new Set(completedRows.map(r => r.id));

    displayRows.value.forEach(row => {
      if (reviewingIds.has(row.id)) {
        row.user_edit_status = '완료';
      } else if (completedIds.has(row.id)) {
        row.user_edit_status = '검수중';
      }
    });
    
    selectedRows.value = [];

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
    const idsToDelete = selectedRows.value.map(r => r.id).filter(Boolean);
    const perfIdsToUpdate = selectedRows.value.map(r => r.performance_record_id).filter(Boolean);
    
    if (perfIdsToUpdate.length > 0) {
      await supabase.from('performance_records').update({ user_edit_status: '대기' }).in('id', perfIdsToUpdate).throwOnError();
    }
    
    if (idsToDelete.length > 0) {
      await supabase.from('absorption_analysis').delete().in('id', idsToDelete).throwOnError();
    }
    
    const idsToDeleteSet = new Set(idsToDelete);
    displayRows.value = displayRows.value.filter(row => !idsToDeleteSet.has(row.id));
    selectedRows.value = [];
    alert('선택한 항목들이 검수에서 제외되었습니다.');
  } catch(err) {
     alert(`검수 제외 처리 중 오류가 발생했습니다: ${err.message}`);
     console.error(err);
  } finally {
    loading.value = false;
  }
}

const isAnyEditing = computed(() => displayRows.value.some(row => row.isEditing));
let pendingRoute = null;

// 메뉴 이동 시 경고창 처리
router.beforeEach((to, from, next) => {
  if (isAnyEditing.value) {
    if (confirm('완료하지 않은 작업이 있습니다. 작업을 취소하고 다른 메뉴로 이동하시겠습니까?')) {
      // 모든 편집 취소
      displayRows.value.forEach(row => { if (row.isEditing) cancelEdit(row); });
      next();
    } else {
      next(false);
    }
  } else {
    next();
  }
});

onBeforeUnmount(() => {
  // 라우터 가드 해제(핫리로드 등 대비)
  router.beforeEach(() => {});
  document.removeEventListener('click', handleGlobalClick);
});

function handleProductNameInput(row, event) {
  const query = (event && event.target && event.target.value ? event.target.value : row.product_name_search || '').toLowerCase();
  row.product_name_search = event && event.target ? event.target.value : row.product_name_search;
  const candidates = getUniqueProductsByMonth(row.prescription_month).filter(
    p =>
      (p.product_name && p.product_name.toLowerCase().includes(query)) ||
      (p.insurance_code && p.insurance_code.toLowerCase().includes(query))
  );
  row.productSearchResults = candidates;
  row.productSearchSelectedIndex = -1;
  row.showProductSearchList = row.productSearchResults.length > 0;
  if (row.showProductSearchList) {
    activeDropdown.value = { rowId: row.id, type: 'product' };
    updateProductDropdownPosition(row);
  }
}

function navigateProductSearchList(direction, row) {
  if (!row.showProductSearchList || row.productSearchResults.length === 0) return;
  if (direction === 'down') {
    row.productSearchSelectedIndex = (row.productSearchSelectedIndex + 1) % row.productSearchResults.length;
  } else if (direction === 'up') {
    row.productSearchSelectedIndex = (row.productSearchSelectedIndex - 1 + row.productSearchResults.length) % row.productSearchResults.length;
  }
}

function applySelectedProduct(product, row) {
  row.product_name_display = product.product_name;
  row.product_id_modify = product.id;
  row.insurance_code = product.insurance_code;
  row.price_for_calc = product.price;
  row.product_name_search = product.product_name;
  row.showProductSearchList = false;
  // 보험코드와 기준월로 제품을 찾아 수수료율 반영
  const baseMonth = row.prescription_month_modify || row.prescription_month;
  const commissionGrade = (row.company_commission_grade || 'a').toLowerCase();
  const rateKey = `commission_rate_${commissionGrade}`;
  const matchedProduct = allProducts.value.find(p => p.insurance_code === product.insurance_code && p.base_month === baseMonth);
  row.commission_rate_modify = matchedProduct && matchedProduct[rateKey] ? matchedProduct[rateKey] * 100 : 0;
  activeDropdown.value = { rowId: null, type: null };
  nextTick(() => {
    focusNextField(row, 'product_name');
  });
}

function hideProductSearchList(row) {
  if (activeDropdown.value.rowId === row.id && activeDropdown.value.type === 'product') {
    row.showProductSearchList = false;
    activeDropdown.value = { rowId: null, type: null };
  }
}

function toggleProductDropdown(row) {
  if (activeDropdown.value.rowId === row.id && activeDropdown.value.type === 'product') {
    row.showProductSearchList = false;
    activeDropdown.value = { rowId: null, type: null };
  } else {
    // 다른 드롭다운이 열려있으면 닫기
    if (activeDropdown.value.rowId) {
      const otherRow = displayRows.value.find(r => r.id === activeDropdown.value.rowId);
      if (otherRow) {
        otherRow.showProductSearchList = false;
      }
    }
    
    const allProducts = getUniqueProductsByMonth(row.prescription_month);
    row.productSearchResults = allProducts;
    row.productSearchSelectedIndex = -1;
    row.showProductSearchList = allProducts.length > 0;
    if (row.showProductSearchList) {
      activeDropdown.value = { rowId: row.id, type: 'product' };
      updateProductDropdownPosition(row);
    }
  }
}

function setProductInputRef(rowId, el) {
  if (el) productInputRefs.value[rowId] = el;
}

function updateProductDropdownPosition(row) {
  nextTick(() => {
    const el = productInputRefs.value[row.id];
    if (!el) return;
    const rect = el.getBoundingClientRect();
    const windowHeight = window.innerHeight;
    const dropdownHeight = 220;
    const spaceBelow = windowHeight - rect.bottom;
    const spaceAbove = rect.top;
    const showAbove = spaceBelow < dropdownHeight && spaceAbove > dropdownHeight;
    productDropdownStyle.value[row.id] = {
      position: 'fixed',
      left: rect.left + 'px',
      top: showAbove ? (rect.top - dropdownHeight) + 'px' : rect.bottom + 'px',
      width: rect.width + 'px',
      zIndex: 99999,
      maxHeight: showAbove ? Math.min(dropdownHeight, spaceAbove - 10) + 'px' : Math.min(dropdownHeight, spaceBelow - 10) + 'px',
      overflowY: 'auto',
    };
  });
}

watch(() => displayRows.value.map(r => r.isEditing), () => {
  displayRows.value.forEach(row => {
    if (row.isEditing && row.showProductSearchList) updateProductDropdownPosition(row);
  });
});

window.addEventListener('scroll', () => {
  displayRows.value.forEach(row => {
    if (row.isEditing && row.showProductSearchList) updateProductDropdownPosition(row);
  });
}, true);

function setFieldRef(rowId, field, el) {
  if (!fieldRefs.value[rowId]) fieldRefs.value[rowId] = {};
  if (el) fieldRefs.value[rowId][field] = el;
}
function focusNextField(row, currentField) {
  const order = ['product_name', 'prescription_qty', 'prescription_type', 'commission_rate', 'remarks', 'prescription_month'];
  const idx = order.indexOf(currentField);
  if (idx !== -1) {
    const next = order[(idx + 1) % order.length];
    nextTick(() => {
      setCurrentCell(row, next);
      const refEl = fieldRefs.value[row.id] && fieldRefs.value[row.id][next];
      if (refEl) {
        if (refEl.focus) refEl.focus();
        else if (refEl.focusInput) refEl.focusInput();
        else if (refEl.$el) refEl.$el.focus();
      }
    });
  }
}
function focusPrevField(row, currentField) {
  const order = ['product_name', 'prescription_qty', 'prescription_type', 'commission_rate', 'remarks', 'prescription_month'];
  const idx = order.indexOf(currentField);
  if (idx !== -1) {
    const prev = order[(idx - 1 + order.length) % order.length];
    nextTick(() => {
      setCurrentCell(row, prev);
      const refEl = fieldRefs.value[row.id] && fieldRefs.value[row.id][prev];
      if (refEl) {
        if (refEl.focus) refEl.focus();
        else if (refEl.focusInput) refEl.focusInput();
        else if (refEl.$el) refEl.$el.focus();
      }
    });
  }
}

// 4. setCurrentCell 함수 추가
function setCurrentCell(row, col) {
  currentCell.value = { row: displayRows.value.findIndex(r => r.id === row.id), col };
  // 셀 포커스 시 드롭다운 닫기
  if (activeDropdown.value.rowId && activeDropdown.value.rowId !== row.id) {
    const otherRow = displayRows.value.find(r => r.id === activeDropdown.value.rowId);
    if (otherRow) {
      otherRow.showProductSearchList = false;
    }
    activeDropdown.value = { rowId: null, type: null };
  }
}

// 2. cellClass 함수 추가
function cellClass(rowIdx, col) {
  return currentCell.value.row === rowIdx && currentCell.value.col === col ? 'cell-focused' : '';
}

// 드롭다운 관련 함수 추가
function togglePrescriptionMonthDropdown(row) {
  if (activeDropdown.value.rowId === row.id && activeDropdown.value.type === 'prescription_month') {
    activeDropdown.value = { rowId: null, type: null };
  } else {
    // 다른 드롭다운이 열려있으면 닫기
    if (activeDropdown.value.rowId) {
      const otherRow = displayRows.value.find(r => r.id === activeDropdown.value.rowId);
      if (otherRow) {
        otherRow.showProductSearchList = false;
      }
    }
    activeDropdown.value = { rowId: row.id, type: 'prescription_month' };
    nextTick(() => {
      const refEl = fieldRefs.value[row.id] && fieldRefs.value[row.id]['prescription_month'];
      if (refEl) {
        refEl.focus();
        refEl.click();
      }
    });
  }
}

function togglePrescriptionTypeDropdown(row) {
  if (activeDropdown.value.rowId === row.id && activeDropdown.value.type === 'prescription_type') {
    activeDropdown.value = { rowId: null, type: null };
  } else {
    // 다른 드롭다운이 열려있으면 닫기
    if (activeDropdown.value.rowId) {
      const otherRow = displayRows.value.find(r => r.id === activeDropdown.value.rowId);
      if (otherRow) {
        otherRow.showProductSearchList = false;
      }
    }
    activeDropdown.value = { rowId: row.id, type: 'prescription_type' };
    nextTick(() => {
      const refEl = fieldRefs.value[row.id] && fieldRefs.value[row.id]['prescription_type'];
      if (refEl) {
        refEl.focus();
        refEl.click();
      }
    });
  }
}

// 전역 클릭 이벤트 핸들러 수정
function handleGlobalClick(event) {
  // 드롭다운 영역 외 클릭 시 모든 드롭다운 닫기
  if (!event.target.closest('.product-input-container') && 
      !event.target.closest('.product-search-list') &&
      !event.target.closest('select')) {
    displayRows.value.forEach(row => {
      if (row.showProductSearchList) {
        row.showProductSearchList = false;
      }
    });
    activeDropdown.value = { rowId: null, type: null };
  }
}

function handleProductNameFocus(row) {
  if (row.productSearchResults && row.productSearchResults.length > 0) {
    row.showProductSearchList = true;
    activeDropdown.value = { rowId: row.id, type: 'product' };
    updateProductDropdownPosition(row);
  }
}

function handleTabNavigation(row, currentField, event) {
  const fields = ['product_name', 'prescription_qty', 'prescription_type', 'commission_rate', 'remarks', 'prescription_month'];
  const currentIndex = fields.indexOf(currentField);
  let nextIndex;
  
  if (event.shiftKey) {
    nextIndex = currentIndex > 0 ? currentIndex - 1 : fields.length - 1;
  } else {
    nextIndex = currentIndex < fields.length - 1 ? currentIndex + 1 : 0;
  }
  
  const nextField = fields[nextIndex];
  const nextRef = fieldRefs.value[row.id]?.[nextField];
  
  if (nextRef) {
    // 드롭다운이 열려있으면 닫기
    if (row.showProductSearchList) row.showProductSearchList = false;
    if (row.showPrescriptionMonthDropdown) row.showPrescriptionMonthDropdown = false;
    if (row.showPrescriptionTypeDropdown) row.showPrescriptionTypeDropdown = false;
    
    nextRef.focus();
  }
}

function handlePrescriptionMonthSelect(row) {
  if (row.showPrescriptionMonthDropdown) {
    row.prescription_month_modify = availableMonths.value[row.prescriptionMonthSelectedIndex].settlement_month;
    row.showPrescriptionMonthDropdown = false;
    handleEditCalculations(row, 'month');
    // 다음 셀로 이동
    const nextField = 'product_name';
    const nextRef = fieldRefs.value[row.id]?.[nextField];
    if (nextRef) {
      nextRef.focus();
    }
  }
}

function handlePrescriptionTypeSelect(row) {
  if (row.showPrescriptionTypeDropdown) {
    row.prescription_type_modify = prescriptionTypeOptions[row.prescriptionTypeSelectedIndex];
    row.showPrescriptionTypeDropdown = false;
    // 다음 셀로 이동
    const nextField = 'commission_rate';
    const nextRef = fieldRefs.value[row.id]?.[nextField];
    if (nextRef) {
      nextRef.focus();
    }
  }
}

function applySelectedProductFromSearch(row) {
  if (row.showProductSearchList && row.productSearchResults.length > 0) {
    const selectedProduct = row.productSearchResults[row.productSearchSelectedIndex];
    // 콘솔 로그 추가
    // 보험코드와 기준월로 제품을 찾아 수수료율 반영
    const baseMonth = row.prescription_month_modify || row.prescription_month;
    const commissionGrade = (row.company_commission_grade || 'a').toLowerCase();
    const rateKey = `commission_rate_${commissionGrade}`;
    const matchedProduct = allProducts.value.find(p => p.insurance_code === selectedProduct.insurance_code && p.base_month === baseMonth);
    row.commission_rate_modify = matchedProduct && matchedProduct[rateKey] ? matchedProduct[rateKey] * 100 : 0;
    applySelectedProduct(selectedProduct, row);
    row.showProductSearchList = false;
    // 다음 셀로 이동
    const nextField = 'prescription_qty';
    const nextRef = fieldRefs.value[row.id]?.[nextField];
    if (nextRef) {
      nextRef.focus();
    }
  }
}

function handlePrescriptionMonthFocus(row) {
  setCurrentCell(row, 'prescription_month');
  activeDropdown.value = { rowId: row.id, type: 'prescription_month' };
  nextTick(() => {
    const refEl = fieldRefs.value[row.id] && fieldRefs.value[row.id]['prescription_month'];
    if (refEl) {
      refEl.click();
    }
  });
}

function handleArrowNavigation(row, currentField, direction) {
  const fields = ['product_name', 'prescription_qty', 'prescription_type', 'commission_rate', 'remarks', 'prescription_month'];
  const currentIndex = fields.indexOf(currentField);
  let nextIndex;

  if (direction === 'left') {
    nextIndex = currentIndex > 0 ? currentIndex - 1 : fields.length - 1;
  } else {
    nextIndex = currentIndex < fields.length - 1 ? currentIndex + 1 : 0;
  }

  const nextField = fields[nextIndex];
  const nextRef = fieldRefs.value[row.id]?.[nextField];
  
  if (nextRef) {
    // 드롭다운이 열려있으면 닫기
    if (row.showProductSearchList) row.showProductSearchList = false;
    if (row.showPrescriptionMonthDropdown) row.showPrescriptionMonthDropdown = false;
    if (row.showPrescriptionTypeDropdown) row.showPrescriptionTypeDropdown = false;
    
    nextRef.focus();
  }
}

function handlePrescriptionMonthDownKey(row, event) {
  if (!row.showPrescriptionMonthDropdown) {
    // 드롭다운이 닫혀있을 때는 드롭다운을 열고 첫 번째 항목 선택
    row.showPrescriptionMonthDropdown = true;
    row.prescriptionMonthSelectedIndex = 0;
  } else {
    // 드롭다운이 열려있을 때는 다음 항목으로 이동
    row.prescriptionMonthSelectedIndex = Math.min(
      row.prescriptionMonthSelectedIndex + 1,
      availableMonths.value.length - 1
    );
  }
}

function handlePrescriptionMonthUpKey(row, event) {
  if (!row.showPrescriptionMonthDropdown) {
    // 드롭다운이 닫혀있을 때는 드롭다운을 열고 마지막 항목 선택
    row.showPrescriptionMonthDropdown = true;
    row.prescriptionMonthSelectedIndex = availableMonths.value.length - 1;
  } else {
    // 드롭다운이 열려있을 때는 이전 항목으로 이동
    row.prescriptionMonthSelectedIndex = Math.max(row.prescriptionMonthSelectedIndex - 1, 0);
  }
}

function handlePrescriptionTypeDownKey(row, event) {
  if (!row.showPrescriptionTypeDropdown) {
    // 드롭다운이 닫혀있을 때는 드롭다운을 열고 첫 번째 항목 선택
    row.showPrescriptionTypeDropdown = true;
    row.prescriptionTypeSelectedIndex = 0;
  } else {
    // 드롭다운이 열려있을 때는 다음 항목으로 이동
    row.prescriptionTypeSelectedIndex = Math.min(
      row.prescriptionTypeSelectedIndex + 1,
      prescriptionTypeOptions.length - 1
    );
  }
}

function handlePrescriptionTypeUpKey(row, event) {
  if (!row.showPrescriptionTypeDropdown) {
    // 드롭다운이 닫혀있을 때는 드롭다운을 열고 마지막 항목 선택
    row.showPrescriptionTypeDropdown = true;
    row.prescriptionTypeSelectedIndex = prescriptionTypeOptions.length - 1;
  } else {
    // 드롭다운이 열려있을 때는 이전 항목으로 이동
    row.prescriptionTypeSelectedIndex = Math.max(row.prescriptionTypeSelectedIndex - 1, 0);
  }
}

const handleProductNameDownKey = (row, event) => {
  if (!row.showProductSearchList) {
    // 드롭다운이 닫혀있을 때는 드롭다운을 열고 첫 번째 항목 선택
    row.showProductSearchList = true;
    row.productSearchSelectedIndex = 0;
    updateProductDropdownPosition(row);
  } else {
    // 드롭다운이 열려있을 때는 다음 항목으로 이동
    row.productSearchSelectedIndex = Math.min(
      row.productSearchSelectedIndex + 1,
      row.productSearchResults.length - 1
    );
  }
};

const handleProductNameUpKey = (row, event) => {
  if (!row.showProductSearchList) {
    // 드롭다운이 닫혀있을 때는 드롭다운을 열고 마지막 항목 선택
    row.showProductSearchList = true;
    row.productSearchSelectedIndex = row.productSearchResults.length - 1;
    updateProductDropdownPosition(row);
  } else {
    // 드롭다운이 열려있을 때는 이전 항목으로 이동
    row.productSearchSelectedIndex = Math.max(row.productSearchSelectedIndex - 1, 0);
  }
};

</script>

<style scoped>
/* 기본 select 스타일 추가 */

.performance-review-view { padding: 0px; }
.data-card-buttons { display: flex; gap: 8px; }

/* Edit mode styles */
.edit-mode-input {
  background: #fff !important;
  border: 1px solid #d0d7de !important;
  border-radius: 4px !important;
  box-shadow: none !important;
  transition: all 0.2s ease;
  width: 100%;
  box-sizing: border-box;
}

.edit-mode-input:focus {
  border-color: #1976d2 !important;
  box-shadow: 0 0 0 2px rgba(25, 118, 210, 0.2) !important;
  outline: none !important;
}

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

/* 포커스 스타일 */
.cell-focused {
  outline: 2px solid #1976d2 !important;
  outline-offset: -2px !important;
  z-index: 2;
  background: #eaf4ff !important;
  position: relative;
}

/* Product Search Dropdown */
.product-input-container {
  position: relative;
  display: flex;
  align-items: center;
  width: 100%;
}

.dropdown-arrow-btn {
  position: absolute;
  right: 1px;
  top: 50%;
  transform: translateY(-50%);
  height: calc(100% - 2px);
  border: none;
  background: transparent;
  cursor: pointer;
  padding: 0 8px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.dropdown-arrow {
  color: #555;
  font-size: 10px;
}

.product-search-list {
  position: absolute;
  background-color: white;
  border: 1px solid #ccc;
  border-radius: 4px;
  max-height: 220px;
  overflow-y: auto;
  z-index: 1000;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.product-search-item {
  padding: 8px 12px;
  cursor: pointer;
  font-size: 14px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.product-search-item:hover {
  background-color: #f0f0f0;
}

.product-search-item.selected {
  background-color: #1976d2;
  color: white;
}
</style>
