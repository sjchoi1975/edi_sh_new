<template>
  <div class="performance-review-view page-container" style="display: flex; flex-direction: column; height: 100vh;">
    <div class="page-header-title-area" style="flex-shrink: 0;">
      <div class="header-title">실적 검수</div>
    </div>

    <!-- 필터 카드: 기본 <select> 디자인으로 완전 복원 -->
    <div class="filter-card" style="flex-shrink: 0;">
      <div class="filter-row" style="justify-content: flex-start; align-items: flex-end; gap: 16px; flex-wrap: wrap;">
        
        <div style="display: flex; align-items: center; gap: 8px;">
          <label>정산월</label>
          <select v-model="selectedSettlementMonth" class="select-basic">
            <option v-for="month in availableMonths" :key="month.settlement_month" :value="month.settlement_month">{{ month.settlement_month }}</option>
          </select>
        </div>
        
        <div style="display: flex; align-items: center; gap: 8px;">
          <label>처방월</label>
          <select v-model="prescriptionOffset" class="select-basic">
            <option v-for="opt in prescriptionOptions" :key="opt.value" :value="opt.value">{{ opt.month }}</option>
          </select>
        </div>
        
        <div style="display: flex; align-items: center; gap: 8px;">
          <label>업체</label>
          <select v-model="selectedCompanyId" class="select-wide">
            <option v-for="company in companyOptions" :key="company.id" :value="company.id">{{ company.company_name }}</option>
          </select>
        </div>
        
        <div style="display: flex; align-items: center; gap: 8px;">
          <label>거래처</label>
          <select v-model="selectedHospitalId" class="select-wide">
            <option v-for="hospital in hospitalOptions" :key="hospital.id" :value="hospital.id">{{ hospital.name }}</option>
          </select>
        </div>
        
        <div style="display: flex; align-items: center; gap: 8px;">
          <label>상태</label>
          <select v-model="selectedReviewStatus" class="select-basic">
            <option v-for="opt in reviewStatusOptions" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
          </select>
        </div>

        <div style="display: flex; align-items: center; gap: 8px;">
          <label>작업</label>
          <select v-model="selectedReviewAction" class="select-basic">
            <option v-for="opt in reviewActionOptions" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
          </select>
        </div>

        <div style="display: flex; align-items: center; margin-left: auto;">
          <button 
            class="btn-primary" 
            @click="loadPerformanceData" 
            :disabled="loading"
            style="height: 38px;"
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
          <Column field="client_name" header="거래처명" :headerStyle="{ width: columnWidths.client_name }" :sortable="true" :frozen="true" />
          
          <Column field="prescription_month" header="처방월" :headerStyle="{ width: columnWidths.prescription_month }" :sortable="true">
            <template #body="slotProps">
              <Dropdown v-if="slotProps.data.isEditing" v-model="slotProps.data.prescription_month_modify" :options="availableMonths" optionLabel="settlement_month" optionValue="settlement_month" class="edit-mode-input" />
              <span v-else>{{ slotProps.data.prescription_month }}</span>
            </template>
          </Column>
          <Column field="product_name_display" header="제품명" :headerStyle="{ width: columnWidths.product_name_display }" :sortable="true">
            <template #body="slotProps">
              <Dropdown v-if="slotProps.data.isEditing" v-model="slotProps.data.product_id_modify" :options="allProducts" optionLabel="product_name" optionValue="id" @change="onProductChange(slotProps.data)" filter class="edit-mode-input"/>
              <span v-else>{{ slotProps.data.product_name_display }}</span>
            </template>
          </Column>
          <Column field="insurance_code" header="보험코드" :headerStyle="{ width: columnWidths.insurance_code }" :sortable="true" />
          <Column field="price" header="약가" :headerStyle="{ width: columnWidths.price }" :sortable="true" />
          <Column field="prescription_qty" header="수량" :headerStyle="{ width: columnWidths.prescription_qty }" :sortable="true">
             <template #body="slotProps">
                <InputNumber v-if="slotProps.data.isEditing" v-model="slotProps.data.prescription_qty_modify" :min="0" class="edit-mode-input" />
                <span v-else>{{ slotProps.data.prescription_qty }}</span>
            </template>
          </Column>
          <Column field="prescription_amount" header="처방액" :headerStyle="{ width: columnWidths.prescription_amount }" :sortable="true" />
          <Column field="prescription_type" header="처방구분" :headerStyle="{ width: columnWidths.prescription_type }" :sortable="true">
             <template #body="slotProps">
                <Dropdown v-if="slotProps.data.isEditing" v-model="slotProps.data.prescription_type_modify" :options="prescriptionTypes" class="edit-mode-input"/>
                <span v-else>{{ slotProps.data.prescription_type }}</span>
            </template>
          </Column>
          <Column field="commission_rate" header="수수료율" :headerStyle="{ width: columnWidths.commission_rate }" :sortable="true">
             <template #body="slotProps">
                <InputNumber v-if="slotProps.data.isEditing" v-model="slotProps.data.commission_rate_modify" :min="0" :max="100" suffix="%" class="edit-mode-input"/>
                <span v-else>{{ slotProps.data.commission_rate }}</span>
            </template>
          </Column>
          <Column field="payment_amount" header="지급액" :headerStyle="{ width: columnWidths.payment_amount }" :sortable="true" />
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

// --- 상태 변수 정의 ---
const loading = ref(false);
const displayRows = ref([]);
const availableMonths = ref([]);
const companyOptions = ref([]);
const hospitalOptions = ref([]);
const allProducts = ref([]);

// 필터 선택값
const selectedSettlementMonth = ref('');
const selectedCompanyId = ref('ALL');
const selectedHospitalId = ref('ALL');
const prescriptionOffset = ref(0);
const selectedReviewStatus = ref('ALL');
const selectedReviewAction = ref('ALL');

// 드롭다운 옵션
const prescriptionOptions = ref([]);
const reviewStatusOptions = [ { label: '- 전체 -', value: 'ALL' }, { label: '완료', value: '완료' }, { label: '검수중', value: '검수중' } ];
const reviewActionOptions = [ { label: '- 전체 -', value: 'ALL' }, { label: '추가', value: '추가' }, { label: '수정', value: '수정' }, { label: '삭제', value: '삭제' }];
const prescriptionTypes = ref(['EDI', '대한조제', '의료매출', '직거래매입', '차감', '원내매출', '원외매출']);

// 체크박스 관련
const selectedRows = ref([]);
const selectedRowsMap = ref({});
const selectAllChecked = ref(false);

// --- 초기화 및 데이터 로딩 ---
onMounted(async () => {
  await Promise.all([ fetchAvailableMonths(), fetchAllProducts() ]);
});

async function fetchFilterOptions() {
  await Promise.all([ fetchAvailableMonths(), fetchAllProducts() ]);
  if (selectedSettlementMonth.value) {
    await fetchCompaniesForMonth();
    await fetchClientsForMonth();
  }
}

async function fetchAvailableMonths() {
  try {
    const { data, error } = await supabase.from('settlement_months').select('settlement_month').order('settlement_month', { ascending: false });
    if (error) throw error;
    availableMonths.value = data;
    if (data.length > 0) {
      selectedSettlementMonth.value = data[0].settlement_month;
      await fetchCompaniesForMonth();
      await fetchClientsForMonth();
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

// 전체 업체/거래처 목록 대신 해당 월의 실적 기반으로 목록 생성
async function fetchCompaniesForMonth() {
  if (!selectedSettlementMonth.value) {
    companyOptions.value = [{ id: 'ALL', company_name: '- 전체 -' }];
    return;
  }
  try {
    const { data, error } = await supabase
      .from('performance_records')
      .select('companies!inner(id, company_name)')
      .eq('settlement_month', selectedSettlementMonth.value);
    
    if (error) throw error;

    const uniqueCompanies = Array.from(new Set(data.map(item => JSON.stringify(item.companies))))
                                .map(item => JSON.parse(item))
                                .sort((a, b) => a.company_name.localeCompare(b.company_name));
    
    companyOptions.value = [{ id: 'ALL', company_name: '- 전체 -' }, ...uniqueCompanies];
    selectedCompanyId.value = 'ALL'; // 목록 갱신 후 '전체'로 초기화
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
        let query = supabase
            .from('performance_records')
            .select('clients!inner(id, name)')
            .eq('settlement_month', selectedSettlementMonth.value);

        if (selectedCompanyId.value && selectedCompanyId.value !== 'ALL') {
            query = query.eq('company_id', selectedCompanyId.value);
        }

        const { data, error } = await query;
        if (error) throw error;

        const uniqueClients = Array.from(new Set(data.map(item => JSON.stringify(item.clients))))
                                  .map(item => JSON.parse(item))
                                  .sort((a, b) => a.name.localeCompare(b.name));

        hospitalOptions.value = [{ id: 'ALL', name: '- 전체 -' }, ...uniqueClients];
        selectedHospitalId.value = 'ALL';
    } catch (err) {
        console.error('해당 월의 거래처 조회 오류:', err);
        hospitalOptions.value = [{ id: 'ALL', name: '- 전체 -' }];
    }
}

// --- 핵심 데이터 처리 함수 ---
async function loadPerformanceData() {
  if (!selectedSettlementMonth.value) { alert('정산월을 선택해야 합니다.'); return; }
  
  loading.value = true;
  displayRows.value = [];
  
  try {
    let perfQuery = supabase.from('performance_records').select('id').eq('settlement_month', selectedSettlementMonth.value);
    if (selectedCompanyId.value && selectedCompanyId.value !== 'ALL') perfQuery = perfQuery.eq('company_id', selectedCompanyId.value);
    if (selectedHospitalId.value && selectedHospitalId.value !== 'ALL') perfQuery = perfQuery.eq('client_id', selectedHospitalId.value);
    const prescriptionMonth = getPrescriptionMonth(selectedSettlementMonth.value, prescriptionOffset.value);
    if (prescriptionOffset.value !== 0) perfQuery = perfQuery.eq('prescription_month', prescriptionMonth);

    const { data: perfRecords, error: perfError } = await perfQuery;
    if (perfError) throw perfError;

    const perfRecordIds = perfRecords.map(p => p.id);
    if (perfRecordIds.length === 0) {
      alert('해당 조건의 실적 데이터가 없습니다.');
      loading.value = false;
      return;
    }

    const { data: existingAnalysis, error: existingError } = await supabase.from('absorption_analysis').select('performance_record_id').in('performance_record_id', perfRecordIds);
    if (existingError) throw existingError;

    const existingRecordIds = new Set(existingAnalysis.map(a => a.performance_record_id));
    const newRecordIds = perfRecordIds.filter(id => !existingRecordIds.has(id));

    if (newRecordIds.length > 0) {
      const recordsToInsert = newRecordIds.map(id => ({
        performance_record_id: id,
        review_status: '검수중',
        company_id_add: null
      }));
      const { error: insertError } = await supabase.from('absorption_analysis').insert(recordsToInsert);
      if (insertError) throw insertError;
      
      // 누락된 상태 업데이트 로직 추가
      const { error: statusUpdateError } = await supabase
        .from('performance_records')
        .update({ user_edit_status: '검수중' })
        .in('id', newRecordIds);
      
      if (statusUpdateError) {
        console.error('실적 상태 업데이트 오류:', statusUpdateError);
      }
    }
    
    await fetchFinalData(perfRecordIds);

  } catch (err) {
    console.error('실적 데이터 처리 오류:', err);
    alert(`실적 데이터 처리 중 오류가 발생했습니다: ${err.message}`);
  } finally {
    loading.value = false;
    selectedRows.value = [];
    selectedRowsMap.value = {};
    updateSelectAllState();
  }
}

async function fetchFinalData(perfRecordIds) {
    if (!perfRecordIds || perfRecordIds.length === 0) {
        displayRows.value = [];
        return;
    }

    // 1. absorption_analysis 데이터 조회 (JOIN 없음)
    const { data: analysisData, error: analysisError } = await supabase
      .from('absorption_analysis')
      .select('*')
      .in('performance_record_id', perfRecordIds)
      .order('id');
    if (analysisError) throw analysisError;

    // 2. performance_records 데이터 별도 조회
    const { data: recordsData, error: recordsError } = await supabase
        .from('performance_records')
        .select(`*, companies(id, company_name), clients(id, name), products(id, product_name, insurance_code, price, commission_rate)`)
        .in('id', perfRecordIds);
    if (recordsError) throw recordsError;
    
    const recordsMap = new Map(recordsData.map(r => [r.id, r]));

    // 3. 등록자 정보 조회
    const userIds = [...new Set(recordsData.map(r => r.registered_by).filter(Boolean))];
    const userMap = new Map();
    if (userIds.length > 0) {
      const { data: users } = await supabase.from('users').select('id, user_name').in('id', userIds);
      users?.forEach(user => userMap.set(user.id, user.user_name));
    }

    // 4. 데이터 조합하여 최종 displayRows 생성
    displayRows.value = analysisData.map(row => {
        const pr = recordsMap.get(row.performance_record_id);
        if (!pr) return null;

        const product = pr.products;
        const price = product?.price || 0;
        const qty = pr.prescription_qty || 0;
        const commission_rate = product?.commission_rate || 0;
        
        const finalQty = row.prescription_qty_modify ?? qty;
        const finalCommissionRate = row.commission_rate_modify ?? commission_rate * 100;
        const finalPaymentAmount = Math.round((price * finalQty) * (finalCommissionRate / 100));

        return {
            id: row.id,
            performance_record_id: row.performance_record_id,
            company_id: pr.company_id,
            client_id: pr.client_id,
            review_status: row.review_status,
            review_action: row.review_action,
            company_name: pr.companies?.company_name || 'N/A',
            client_name: pr.clients?.name || 'N/A',
            prescription_month: row.prescription_month_modify || pr.prescription_month,
            product_name_display: product?.product_name || 'N/A',
            insurance_code: product?.insurance_code || 'N/A',
            price: price.toLocaleString(),
            prescription_qty: finalQty,
            prescription_amount: (price * finalQty).toLocaleString(),
            prescription_type: row.prescription_type_modify || pr.prescription_type,
            commission_rate: `${finalCommissionRate.toFixed(2)}%`,
            payment_amount: finalPaymentAmount.toLocaleString(),
            remarks: row.remarks_modify ?? pr.remarks ?? '',
            created_date: formatDateTime(pr.created_at),
            created_by: userMap.get(pr.registered_by) || 'N/A',
            isEditing: false,
            originalData: null,
            ...row,
        };
    }).filter(Boolean);
}

// --- Watchers ---
watch(selectedSettlementMonth, async (newMonth) => {
  if (newMonth) { 
    await fetchCompaniesForMonth();
    await fetchClientsForMonth();
    updatePrescriptionOptions(); 
    prescriptionOffset.value = 0; 
  }
});

watch(selectedCompanyId, async () => {
    await fetchClientsForMonth();
});

// --- 유틸리티 및 UI 헬퍼 함수 ---
function getActionSeverity(action) {
  if (action === '수정') return 'info'; if (action === '추가') return 'success'; if (action === '삭제') return 'danger'; return 'secondary';
}
function getRowClass(data) {
  if (data.review_action === '삭제') return 'deleted-row'; if (data.review_action === '추가') return 'added-row'; if (data.review_action === '수정') return 'modified-row'; return '';
}
function getPrescriptionMonth(settlementMonth, offset) {
  if (!settlementMonth || offset === null) return ''; const [y, m] = settlementMonth.split('-'); let month = parseInt(m, 10) - offset; let year = parseInt(y, 10);
  while (month <= 0) { month += 12; year -= 1; }
  return `${year}-${String(month).padStart(2, '0')}`;
}
function updatePrescriptionOptions() {
  prescriptionOptions.value = [ { value: 0, month: '- 전체 -' }, ...[1, 2, 3].map(offset => ({ value: offset, month: getPrescriptionMonth(selectedSettlementMonth.value, offset) })) ];
}
function formatDateTime(dateTimeString) {
  if (!dateTimeString) return '-'; const date = new Date(dateTimeString); const kstOffset = 9 * 60 * 60 * 1000; const kstDate = new Date(date.getTime() + kstOffset); return kstDate.toISOString().slice(0, 16).replace('T', ' ');
}

// --- 테이블 액션 함수들 ---
function onRowSelectChange(rowData, isSelected) {
  if (isSelected) { selectedRowsMap.value[rowData.id] = true; selectedRows.value.push(rowData); } else { delete selectedRowsMap.value[rowData.id]; selectedRows.value = selectedRows.value.filter(row => row.id !== rowData.id); }
  updateSelectAllState();
}
function updateSelectAllState() {
  const selectableRows = displayRows.value.filter(row => row.review_action !== '삭제');
  selectAllChecked.value = selectableRows.length > 0 && selectableRows.every(row => selectedRowsMap.value[row.id]);
}
function toggleSelectAll() {
  const selectableRows = displayRows.value.filter(row => row.review_action !== '삭제');
  if (selectAllChecked.value) { 
      selectableRows.forEach(row => { 
          if (!selectedRowsMap.value[row.id]) {
            selectedRowsMap.value[row.id] = true; 
            selectedRows.value.push(row); 
          }
      });
  } else { 
      selectedRows.value = []; 
      selectedRowsMap.value = {}; 
  }
}
function selectAll() { selectAllChecked.value = true; toggleSelectAll(); }
function unselectAll() { selectAllChecked.value = false; toggleSelectAll(); }

function startEdit(row) {
  if (row.review_status === '완료') return;
  row.originalData = { ...row };
  row.isEditing = true;
}
function cancelEdit(row) {
  if (row.isNewRow) {
    displayRows.value = displayRows.value.filter(r => r.id !== row.id);
  } else {
    Object.assign(row, row.originalData);
    row.isEditing = false;
  }
}

async function saveEdit(row) {
  try {
    const isNew = row.isNewRow;
    const updateData = {
      prescription_month_modify: row.prescription_month_modify,
      product_id_modify: row.product_id_modify,
      prescription_qty_modify: row.prescription_qty_modify,
      prescription_type_modify: row.prescription_type_modify,
      commission_rate_modify: row.commission_rate_modify,
      remarks_modify: row.remarks_modify,
      review_action: isNew ? '추가' : '수정'
    };

    let error;
    if (isNew) {
      updateData.review_status = '검수중';
      updateData.company_id_add = row.company_id;
      const { data: insertedData, error: insertError } = await supabase.from('absorption_analysis').insert(updateData).select().single();
      if (!insertError) {
        // 새 ID와 정보로 행 업데이트
        const oldId = row.id;
        displayRows.value = displayRows.value.map(r => r.id === oldId ? { ...r, ...insertedData, isNewRow: false, isEditing: false } : r);
      }
      error = insertError;
    } else {
      updateData.company_id_add = null;
      const { error: updateError } = await supabase.from('absorption_analysis').update(updateData).eq('id', row.id);
       error = updateError;
    }
    
    if (error) throw error;
    
    // UI 업데이트
    const targetRow = displayRows.value.find(r => r.id === row.id);
    if(targetRow) {
        targetRow.isEditing = false;
        targetRow.review_action = updateData.review_action;
        const product = allProducts.value.find(p => p.id === targetRow.product_id_modify);
        const price = product?.price || 0;
        targetRow.product_name_display = product?.product_name || 'N/A';
        targetRow.prescription_qty = targetRow.prescription_qty_modify;
        targetRow.commission_rate = `${targetRow.commission_rate_modify ?? 0}%`;
        targetRow.prescription_amount = (price * targetRow.prescription_qty).toLocaleString();
        targetRow.payment_amount = Math.round((price * targetRow.prescription_qty) * ((targetRow.commission_rate_modify ?? 0) / 100)).toLocaleString();
    }
    
  } catch (err) {
    console.error('저장 오류:', err);
    alert('저장 중 오류가 발생했습니다.');
    cancelEdit(row);
  }
}

function onProductChange(row) {
    const product = allProducts.value.find(p => p.id === row.product_id_modify);
    if(product) {
        row.commission_rate_modify = product.commission_rate;
    }
}

async function confirmDeleteRow(row) {
  if (confirm('이 실적을 삭제 처리하시겠습니까? (목록에서만 삭제 처리됩니다)')) {
    if (row.isNewRow) {
      displayRows.value = displayRows.value.filter(r => r.id !== row.id);
      return;
    }
    row.review_action = '삭제';
    await supabase.from('absorption_analysis').update({ review_action: '삭제' }).eq('id', row.id);
  }
}
async function restoreRow(row) {
  row.review_action = null;
  await supabase.from('absorption_analysis').update({ review_action: null }).eq('id', row.id);
}
function addRowBelow(currentRow) { 
  const index = displayRows.value.findIndex(r => r.id === currentRow.id);
  if (index === -1) return;

  const newRow = {
    id: `new_${Date.now()}`,
    isNewRow: true,
    isEditing: true,
    company_id: currentRow.company_id,
    client_id: currentRow.client_id,
    company_name: currentRow.company_name,
    client_name: currentRow.client_name,
    prescription_month_modify: currentRow.prescription_month,
    product_id_modify: null,
    prescription_qty_modify: 0,
    prescription_type_modify: currentRow.prescription_type,
    commission_rate_modify: 0,
    remarks_modify: '',
    prescription_month: currentRow.prescription_month,
    product_name_display: '',
    insurance_code: '',
    price: '0',
    prescription_qty: 0,
    prescription_amount: '0',
    prescription_type: currentRow.prescription_type,
    commission_rate: '0%',
    payment_amount: '0',
    remarks: '',
    review_status: '검수중',
    review_action: '추가',
    created_date: formatDateTime(new Date().toISOString()),
    created_by: '관리자',
  };
  displayRows.value.splice(index + 1, 0, newRow);
}

async function changeReviewStatus() {
  if (selectedRows.value.length === 0) return;

  const reviewingRows = selectedRows.value.filter(r => r.review_status === '검수중');
  const completedRows = selectedRows.value.filter(r => r.review_status === '완료');
  
  let confirmMessage = '선택된 항목들의 검수 상태를 변경하시겠습니까?\n';
  if (reviewingRows.length > 0) confirmMessage += `\n- 검수중 → 완료: ${reviewingRows.length}건`;
  if (completedRows.length > 0) confirmMessage += `\n- 완료 → 검수중: ${completedRows.length}건`;

  if (!confirm(confirmMessage)) return;
  
  loading.value = true;
  try {
    const promises = [];

    if (reviewingRows.length > 0) {
      const ids = reviewingRows.map(r => r.id);
      promises.push(supabase.from('absorption_analysis').update({ review_status: '완료' }).in('id', ids));
      
      const perfIds = reviewingRows.map(r => r.performance_record_id).filter(Boolean);
      if(perfIds.length > 0) {
        promises.push(supabase.from('performance_records').update({ user_edit_status: '완료' }).in('id', perfIds));
      }
    }
    if (completedRows.length > 0) {
      const ids = completedRows.map(r => r.id);
      promises.push(supabase.from('absorption_analysis').update({ review_status: '검수중' }).in('id', ids));

      const perfIds = completedRows.map(r => r.performance_record_id).filter(Boolean);
      if(perfIds.length > 0) {
        promises.push(supabase.from('performance_records').update({ user_edit_status: '검수중' }).in('id', perfIds));
      }
    }

    const results = await Promise.all(promises);
    const errors = results.map(res => res.error).filter(Boolean);

    if (errors.length > 0) {
      throw new Error(`다음 오류 발생: ${errors.map(e => e.message).join(', ')}`);
    }

    alert('상태가 성공적으로 변경되었습니다.');
  } catch (err) {
    alert('상태 변경 중 오류가 발생했습니다.');
    console.error(err);
  } finally {
    await loadPerformanceData();
  }
}

async function removeFromReview() {
  if (selectedRows.value.length === 0) return;
  if (!confirm(`선택된 ${selectedRows.value.length}건을 검수 대상에서 제외하시겠습니까?\n(제외된 데이터는 사용자가 다시 업로드해야 검수 가능합니다)`)) return;

  loading.value = true;
  try {
    const idsToDelete = selectedRows.value.map(r => r.id);
    const perfIdsToUpdate = selectedRows.value.map(r => r.performance_record_id).filter(Boolean);

    // 1. absorption_analysis에서 삭제
    const { error: deleteError } = await supabase.from('absorption_analysis').delete().in('id', idsToDelete);

    if (deleteError) {
      // 삭제 실패 시, 여기서 중단하고 오류 메시지 표시
      throw deleteError;
    }

    // 2. 삭제 성공 시에만 performance_records 상태 업데이트
    if (perfIdsToUpdate.length > 0) {
      const { error: updateError } = await supabase.from('performance_records').update({ user_edit_status: '대기' }).in('id', perfIdsToUpdate);
      if (updateError) {
        // 이 오류는 심각도가 낮으므로 로그만 남김
        console.error('삭제 후 실적 상태 업데이트 오류:', updateError);
      }
    }
    
    alert('선택한 항목들이 검수에서 제외되었습니다.');

  } catch(err) {
     alert('검수 제외 처리 중 오류가 발생했습니다.');
     console.error(err);
  } finally {
    // 작업이 끝난 후, 목록 새로고침
    await loadPerformanceData();
  }
}

</script>

<style scoped>
/* 기본 select 스타일 추가 */
.select-basic, .select-wide {
  height: 38px;
  padding: 4px 8px;
  border: 1px solid #ced4da;
  border-radius: 4px;
  background-color: #fff;
}
.select-basic {
  width: 120px;
}
.select-wide {
  width: 220px;
}

/* 제가 추가했던 스타일을 모두 제거하고 원래 상태로 복원합니다. */
.performance-review-view { padding: 0px; }
.data-card-buttons { display: flex; gap: 8px; }

/* Edit mode styles */
.edit-mode-input { width: 100%; }

/* Row status styles */
.admin-performance-review-table :deep(.added-row td) {
  background-color: #e7f5ff !important; /* 아주 연한 파란색 */
}
.admin-performance-review-table :deep(.modified-row td) {
  background-color: #fffde7 !important; /* 아주 연한 노란색 */
}
.admin-performance-review-table :deep(.deleted-row td) {
  background-color: #fff5f5 !important; /* 아주 연한 붉은색 */
}

/* 삭제된 행의 폰트 색상 및 취소선 조정 */
.admin-performance-review-table :deep(.deleted-row td:nth-child(n+5)) {
    color: #aaa !important;
    text-decoration: line-through;
}

/* 되돌리기 버튼에는 취소선 제거 */
.admin-performance-review-table :deep(.deleted-row td:nth-child(4)) {
  text-decoration: none !important;
}

.btn-restore-sm { 
  background-color: #28a745; 
  color: white; 
  border: none; 
  padding: 0;
  border-radius: 3px; 
  font-size: 18px; /* 아이콘 크기 키움 */
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