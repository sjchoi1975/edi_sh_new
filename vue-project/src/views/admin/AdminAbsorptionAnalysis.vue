<template>
  <div class="performance-register-view page-container absorption-analysis" style="display: flex; flex-direction: column; height: 100vh;">
    <div class="page-header-title-area" style="flex-shrink: 0;">
    <div class="header-title">흡수율 분석</div>
    </div>

    <!-- 필터 카드 -->
    <div class="filter-card" style="flex-shrink: 0;">
      <div class="filter-row" style="justify-content: flex-start; align-items: flex-end;">
        <div style="display: flex; align-items: center; gap: 8px;">
          <label style="font-weight:400;">정산월</label>
          <select v-model="selectedSettlementMonth" class="select_month">
            <option value="">- 선택 -</option>
            <option v-for="month in availableMonths" :key="month.settlement_month" :value="month.settlement_month">
              {{ month.settlement_month }}
            </option>
          </select>
        </div>
        <div style="display: flex; align-items: center; gap: 8px;">
          <label style="font-weight:400;">처방월</label>
          <select v-model="prescriptionOffset" class="select_month">
            <option v-for="opt in prescriptionOptions" :key="opt.value" :value="opt.value">
              {{ opt.month }}
            </option>
          </select>
        </div>
        <div style="display: flex; align-items: center; gap: 8px;">
          <label style="font-weight:400;">업체</label>
          <select v-model="selectedCompanyId" class="select_240px">
            <option value="">- 전체 -</option>
            <option v-for="company in companies" :key="company.id" :value="company.id">{{ company.company_name }}</option>
          </select>
        </div>
        <div style="display: flex; align-items: center; gap: 8px;">
          <label style="font-weight:400;">거래처</label>
          <select v-model="selectedHospitalId" class="select_240px">
            <option value="">- 전체 -</option>
            <option v-for="hospital in hospitals" :key="hospital.id" :value="hospital.id">{{ hospital.name }}</option>
          </select>
        </div>
        </div>
      </div>
      
    <!-- 데이터 카드 -->
    <div class="data-card" style="flex-grow: 1; display: flex; flex-direction: column; overflow: hidden;">
      <div class="data-card-header" style="flex-shrink: 0;">
        <div class="total-count-display">전체 {{ displayRows.length }} 건</div>
        <div class="data-card-buttons" style="display: flex; gap: 0.5rem;">
          <button 
            class="btn-upload" 
            @click="loadPerformanceData" 
            :disabled="!selectedSettlementMonth"
          >실적 정보 불러오기</button>
          <button 
            class="btn-primary" 
            @click="runAbsorptionAnalysis" 
            :disabled="displayRows.length === 0"
          >흡수율 분석</button>
          <button 
            class="btn-delete" 
            @click="confirmDeleteAllData" 
            :disabled="displayRows.length === 0"
          >전체 삭제</button>
          <button 
            class="btn-excell-download" 
            @click="downloadExcel" 
            :disabled="displayRows.length === 0"
          >엑셀 다운로드</button>
          <button 
            class="btn-save" 
            @click="saveAnalysisData" 
            :disabled="displayRows.length === 0 || !hasUnsavedChanges"
          >저장</button>
        </div>
      </div>
      
      <div style="flex-grow: 1; overflow: auto;">
      <DataTable 
        :value="displayRows" 
        scrollable 
        scrollHeight="calc(100vh - 220px)"
        scrollDirection="both"
        class="admin-absorption-analysis-table"
        dataKey="id"
        :pt="{
          wrapper: { style: 'min-width: 2800px;' },
          table: { style: 'min-width: 2800px;' }
        }"
      >
        <template #empty>
          <div style="text-align:center;padding:2rem;color:#666;">
                <div v-if="!selectedSettlementMonth" style="margin-bottom:1rem;">
                  정산월을 선택하세요.
                </div>
                <div v-else style="margin-bottom:1rem;">
                  흡수율 분석 데이터가 없습니다.<br>
                  실적 정보를 불러와서 분석을 시작하세요.
                </div>
                <button 
                  v-if="selectedSettlementMonth" 
                  class="btn-primary" 
                  @click="loadPerformanceData"
            >실적 정보 불러오기</button>
          </div>
        </template>
        <template #loading>흡수율 분석 데이터를 불러오는 중입니다...</template>
        
        <Column header="No" :headerStyle="{ width: columnWidths.no }" >
          <template #body="slotProps">
            {{ slotProps.index + 1 }}
          </template>
        </Column>
        
          <Column field="company_group" header="구분" :headerStyle="{ width: columnWidths.company_group }" :sortable="true" />
        
        <Column field="company_name" header="업체명" :headerStyle="{ width: columnWidths.company_name }" :sortable="true">
          <template #body="slotProps">
                <Dropdown v-if="slotProps.data.isEditing" v-model="slotProps.data.company_id" :options="allCompanies" optionLabel="company_name" optionValue="id" @change="onCompanyChange(slotProps.data)" style="width:100%" placeholder="업체 선택" :filter="true" />
                <span v-else>{{ slotProps.data.company_name }}</span>
          </template>
        </Column>
        
        <Column field="client_name" header="거래처" :headerStyle="{ width: columnWidths.client_name }" :sortable="true">
          <template #body="slotProps">
                <Dropdown v-if="slotProps.data.isEditing" v-model="slotProps.data.client_id" :options="allClients" optionLabel="name" optionValue="id" @change="onClientChange(slotProps.data)" style="width:100%" placeholder="거래처 선택" :filter="true" />
                <span v-else>{{ slotProps.data.client_name }}</span>
          </template>
        </Column>
        
        <Column field="prescription_month" header="처방월" :headerStyle="{ width: columnWidths.prescription_month }" :sortable="true">
          <template #body="slotProps">
              <Dropdown v-if="slotProps.data.isEditing" v-model="slotProps.data.prescription_month" :options="prescriptionMonthOptions" style="width:100%" @change="onPrescriptionMonthChange(slotProps.data)"/>
              <span v-else>{{ slotProps.data.prescription_month }}</span>
          </template>
        </Column>
        
        <Column field="product_name_display" header="제품명" :headerStyle="{ width: columnWidths.product_name_display }" :sortable="true">
          <template #body="slotProps">
                <Dropdown v-if="slotProps.data.isEditing" v-model="slotProps.data.product_id" :options="getFilteredProducts(slotProps.data)" optionLabel="product_name" optionValue="id" @change="onProductChange(slotProps.data)" style="width:100%" placeholder="제품 선택" :filter="true" />
                <span v-else>{{ slotProps.data.product_name_display }}</span>
          </template>
        </Column>
        
          <Column field="insurance_code" header="보험코드" :headerStyle="{ width: columnWidths.insurance_code }" :sortable="true" />
          <Column field="price" header="약가" :headerStyle="{ width: columnWidths.price }" :sortable="true" />
        
        <Column field="prescription_qty" header="처방수량" :headerStyle="{ width: columnWidths.prescription_qty }" :sortable="true">
          <template #body="slotProps">
              <InputText v-if="slotProps.data.isEditing" type="number" v-model.number="slotProps.data.prescription_qty" @input="onValueChange(slotProps.data)" style="width:100%; text-align:right;" />
              <span v-else>{{ slotProps.data.prescription_qty?.toLocaleString() }}</span>
          </template>
        </Column>
        
          <Column field="prescription_amount" header="처방액" :headerStyle="{ width: columnWidths.prescription_amount }" :sortable="true" />
        
        <Column field="prescription_type" header="처방구분" :headerStyle="{ width: columnWidths.prescription_type }" :sortable="true">
          <template #body="slotProps">
                <Dropdown v-if="slotProps.data.isEditing" v-model="slotProps.data.prescription_type" :options="prescriptionTypeOptions" @change="onValueChange(slotProps.data)" style="width:100%" />
                <span v-else>{{ slotProps.data.prescription_type }}</span>
          </template>
        </Column>
              
          <Column field="wholesale_sales" header="도매매출" :headerStyle="{ width: columnWidths.wholesale_sales }" :sortable="true" />
          <Column field="direct_sales" header="직거래매출" :headerStyle="{ width: columnWidths.direct_sales }" :sortable="true" />
          <Column field="total_sales" header="합산액" :headerStyle="{ width: columnWidths.total_sales }" :sortable="true" />
          <Column field="absorption_rate" header="흡수율" :headerStyle="{ width: columnWidths.absorption_rate }" :sortable="true" />
        
        <Column field="commission_rate" header="수수료율" :headerStyle="{ width: columnWidths.commission_rate }" :sortable="true">
          <template #body="slotProps">
                <InputText v-if="slotProps.data.isEditing" type="number" v-model.number="slotProps.data.commission_rate" @input="onValueChange(slotProps.data)" style="width:100%; text-align:right;" />
                <span v-else>{{ slotProps.data.commission_rate }}%</span>
          </template>
        </Column>
        
          <Column field="payment_amount" header="지급액" :headerStyle="{ width: columnWidths.payment_amount }" :sortable="true" />
        
        <Column field="remarks" header="비고" :headerStyle="{ width: columnWidths.remarks }" :sortable="true">
          <template #body="slotProps">
                <InputText v-if="slotProps.data.isEditing" v-model="slotProps.data.remarks" @input="onValueChange(slotProps.data)" style="width:100%" />
                <span v-else>{{ slotProps.data.remarks }}</span>
          </template>
        </Column>
        
        <Column field="orig_created_at" header="등록일시" :headerStyle="{ width: columnWidths.orig_created_at }" :sortable="true">
          <template #body="slotProps">
              {{ formatDateTime(slotProps.data.orig_created_at) }}
          </template>
        </Column>
          <Column field="orig_registered_by" header="등록자" :headerStyle="{ width: columnWidths.orig_registered_by }" :sortable="true" />
          <Column field="assigned_pharmacist_contact" header="관리자" :headerStyle="{ width: columnWidths.assigned_pharmacist_contact }" :sortable="true" />
        
        <Column header="작업" :headerStyle="{ width: columnWidths.actions }" frozen frozenPosition="right" >
          <template #body="slotProps">
            <div style="display: flex; gap: 4px; justify-content: center;">
                <button v-if="!slotProps.data.isEditing" class="btn-edit-sm" @click="startEdit(slotProps.data)" title="수정">✎</button>
                <button v-if="slotProps.data.isEditing" class="btn-save-sm" @click="saveEdit(slotProps.data)" title="저장">✓</button>
                <button v-if="slotProps.data.isEditing" class="btn-cancel-sm" @click="cancelEdit(slotProps.data)" title="취소">✕</button>
                <button class="btn-delete-sm" @click="confirmDeleteRow(slotProps.index)" title="삭제">－</button>
                <button class="btn-add-sm" @click="addRowBelow(slotProps.index)" title="추가">＋</button>
            </div>
          </template>
        </Column>

            <ColumnGroup type="footer">
                <Row>
                    <Column footer="합계" :colspan="8" footerClass="footer-cell" footerStyle="text-align:center !important;" />
                    <Column :footer="totalPrescriptionQty" footerClass="footer-cell" footerStyle="text-align:right !important;" />
                    <Column :footer="totalPrescriptionAmount" footerClass="footer-cell" footerStyle="text-align:right !important;" />
                    <Column footer="" footerClass="footer-cell" />
                    <Column :footer="totalWholesaleSales" footerClass="footer-cell" footerStyle="text-align:right !important;" />
                    <Column :footer="totalDirectSales" footerClass="footer-cell" footerStyle="text-align:right !important;" />
                    <Column :footer="totalSales" footerClass="footer-cell" footerStyle="text-align:right !important;" />
                    <Column footer="" footerClass="footer-cell" />
                    <Column footer="" footerClass="footer-cell" />
                    <Column :footer="totalPaymentAmount" footerClass="footer-cell" footerStyle="text-align:right !important;" />
                    <Column :colspan="4" footerClass="footer-cell" />
                    <Column footer="" footerClass="footer-cell" frozen frozenPosition="right" />
                </Row>
            </ColumnGroup>
        </DataTable>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, nextTick, onUnmounted } from 'vue';
import { onBeforeRouteLeave } from 'vue-router';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import ColumnGroup from 'primevue/columngroup';
import Row from 'primevue/row';
import { supabase } from '@/supabase';
import * as XLSX from 'xlsx';
import Dropdown from 'primevue/dropdown';
import InputText from 'primevue/inputtext';

const columnWidths = {
  no: '3%',
  company_group: '4%',
  company_name: '6%',
  client_name: '8%',
  prescription_month: '4%',
  product_name_display: '8%',
  insurance_code: '4%',
  price: '3%',
  prescription_qty: '4%',
  prescription_amount: '4%',
  prescription_type: '4%',
  wholesale_sales: '4%',
  direct_sales: '4%',
  total_sales: '4%',
  absorption_rate: '4%',
  commission_rate: '4%',
  payment_amount: '4%',
  remarks: '6%',
  orig_created_at: '6%',
  orig_registered_by: '8%',
  assigned_pharmacist_contact: '4%',
  actions: '5%'
};

// 반응형 데이터
const availableMonths = ref([]);
const selectedSettlementMonth = ref('');
const prescriptionMonth = ref('');
const prescriptionOffset = ref(0);
const prescriptionOptions = ref([]);

// 업체/거래처 관련
const selectedCompanyId = ref('');
const selectedHospitalId = ref('');

// 필터링된 업체/거래처 목록 (computed)
const companies = computed(() => {
  if (displayRows.value.length === 0) return [];
  const uniqueCompanies = [...new Map(displayRows.value.map(item => [item.company_id, {id: item.company_id, company_name: item.company_name}])).values()];
  return uniqueCompanies.sort((a,b) => a.company_name.localeCompare(b.company_name));
});

const hospitals = computed(() => {
  if (displayRows.value.length === 0) return [];
  const uniqueHospitals = [...new Map(displayRows.value.map(item => [item.client_id, {id: item.client_id, name: item.client_name}])).values()];
  return uniqueHospitals.sort((a,b) => a.name.localeCompare(b.name));
});

// 분석 데이터
const displayRows = ref([]);
const editingRows = ref([]);

// 전체 업체/거래처/제품 목록
const allCompanies = ref([]);
const allClients = ref([]);
const allProducts = ref([]);

// 처방구분 옵션
const prescriptionTypeOptions = ref(['EDI', '대한조제', '의료매출', '직거래매입', '차감', '원내매출', '원외매출']);

// 처방월 옵션 (편집용)
const prescriptionMonthOptions = ref([]);

// 변경사항 추적
const hasUnsavedChanges = ref(false);
const hasExistingData = ref(false); // 기존 데이터 존재 여부 추적

// 검색 드롭다운 관련
const clientSearchForRow = ref({
  show: false,
  activeRowIndex: -1,
  results: [],
  selectedIndex: -1,
  position: { top: 0, left: 0, width: 250 }
});

const productSearchForRow = ref({
  show: false,
  activeRowIndex: -1,
  results: [],
  selectedIndex: -1,
  position: { top: 0, left: 0, width: 250 }
});

const companySearchForRow = ref({
  show: false,
  activeRowIndex: -1,
  results: [],
  selectedIndex: -1,
  position: { top: 0, left: 0, width: 250 }
});

// 처방월 옵션 업데이트
function updatePrescriptionOptions() {
  if (!selectedSettlementMonth.value) {
    prescriptionOptions.value = [];
    return;
  }
  
  prescriptionOptions.value = [
    { value: 0, month: '- 전체 -' },
    ...([1, 2, 3].map(offset => ({
      value: offset,
      month: getPrescriptionMonth(selectedSettlementMonth.value, offset)
    })))
  ];
}

// 편집용 처방월 옵션 업데이트 (-3M ~ -1M)
function updatePrescriptionMonthOptions() {
  if (!selectedSettlementMonth.value) {
    prescriptionMonthOptions.value = [];
    return;
  }
  
  prescriptionMonthOptions.value = [1, 2, 3].map(offset => 
    getPrescriptionMonth(selectedSettlementMonth.value, offset)
  );
}

function getPrescriptionMonth(settlementMonth, offset) {
  if (!settlementMonth) return '';
  const [y, m] = settlementMonth.split('-');
  let mm = parseInt(m, 10) - offset;
  let yy = parseInt(y, 10);
  while (mm <= 0) { mm += 12; yy -= 1; }
  return `${yy}-${String(mm).padStart(2, '0')}`;
}

// 워치어
watch(selectedSettlementMonth, () => {
  updatePrescriptionOptions();
  updatePrescriptionMonthOptions(); // 편집용 처방월 옵션도 업데이트
  prescriptionOffset.value = 0;
  prescriptionMonth.value = '';
  selectedCompanyId.value = '';
  selectedHospitalId.value = '';
  hasExistingData.value = false; // 기존 데이터 존재 여부 초기화
  
  // 정산월 선택 시 흡수율 분석 데이터 자동 조회
  if (selectedSettlementMonth.value) {
    loadAbsorptionAnalysisData();
    fetchAllMasterData();
  } else {
    displayRows.value = [];
  }
});

watch(prescriptionOffset, (val) => {
  if (val === 0) {
    prescriptionMonth.value = '';
  } else {
    prescriptionMonth.value = getPrescriptionMonth(selectedSettlementMonth.value, val);
  }
  filterData();
});

watch(selectedCompanyId, () => {
  filterData();
});

watch(selectedHospitalId, () => {
  filterData();
});

// PrimeVue DataTable row editing 관련 함수들
function isRowEditing(rowData) {
  return editingRows.value.some(row => row.id === rowData.id);
}

function onRowEditInit(rowData) {
  editingRows.value.push({ ...rowData });
}

function onRowEditSave(rowData) {
  const index = editingRows.value.findIndex(row => row.id === rowData.id);
  if (index !== -1) {
    editingRows.value.splice(index, 1);
  }
  
  // 저장 후 재계산
  const rowIndex = displayRows.value.findIndex(row => row.id === rowData.id);
  if (rowIndex !== -1) {
    recalculateRow(rowIndex);
  }
}

function onRowEditCancel(rowData) {
  const index = editingRows.value.findIndex(row => row.id === rowData.id);
  if (index !== -1) {
    // 원래 데이터로 복원
    const originalData = editingRows.value[index];
    const rowIndex = displayRows.value.findIndex(row => row.id === rowData.id);
    if (rowIndex !== -1) {
      Object.assign(displayRows.value[rowIndex], originalData);
    }
    editingRows.value.splice(index, 1);
  }
}

// 드롭다운 위치 계산 함수
function calculateDropdownPosition(targetElement) {
  if (!targetElement) return { top: 200, left: 200, width: 250 };
  
  const rect = targetElement.getBoundingClientRect();
  const dropdownWidth = Math.max(rect.width, 250);
  const dropdownHeight = 200;
  
  // 기본 위치 (input 바로 아래)
  let top = rect.bottom + window.scrollY;
  let left = rect.left + window.scrollX;
  
  // 화면 오른쪽 경계 체크
  if (left + dropdownWidth > window.innerWidth) {
    left = window.innerWidth - dropdownWidth - 10;
  }
  
  // 화면 왼쪽 경계 체크
  if (left < 10) {
    left = 10;
  }
  
  // 화면 아래쪽 경계 체크 (드롭다운이 화면 밖으로 나가면 input 위에 표시)
  if (top + dropdownHeight > window.innerHeight + window.scrollY) {
    top = rect.top + window.scrollY - dropdownHeight;
  }
  
  return {
    top: top,
    left: left,
    width: dropdownWidth
  };
}

function getDropdownStyle(rowIndex, type) {
  let position;
  
  if (type === 'company') {
    position = companySearchForRow.value.position;
  } else if (type === 'client') {
    position = clientSearchForRow.value.position;
  } else if (type === 'product') {
    position = productSearchForRow.value.position;
  } else {
    position = { top: 200, left: 200, width: 250 };
  }

  return {
    position: 'fixed',
    top: position.top + 'px',
    left: position.left + 'px',
    width: position.width + 'px',
    zIndex: 9999,
    maxHeight: '200px',
    overflowY: 'auto',
  };
}

// 데이터 필터링
function filterData() {
  // 필터링 로직 구현
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

async function fetchAllMasterData() {
  try {
    await fetchCompanies();
    await fetchHospitals();
    await fetchAllCompanies();
    await fetchAllClients();
    await fetchAllProducts();
  } catch (err) {
    console.error('전체 마스터 데이터 로드 오류:', err);
  }
}

// 전체 업체 목록 조회 (편집용)
async function fetchAllCompanies() {
  try {
    const { data, error } = await supabase
      .from('companies')
      .select('*')
      .eq('status', 'approved')
      .order('company_name');
    
    if (!error && data) {
      allCompanies.value = data;
    }
  } catch (err) {
    console.error('전체 업체 조회 오류:', err);
  }
}

// 전체 거래처 목록 조회 (편집용)
async function fetchAllClients() {
  try {
    const { data, error } = await supabase
      .from('clients')
      .select('*')
      .order('name');
    
    if (!error && data) {
      allClients.value = data;
    }
  } catch (err) {
    console.error('전체 거래처 조회 오류:', err);
  }
}

// 전체 제품 목록 조회 (편집용)
async function fetchAllProducts() {
  try {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .order('product_name');
    
    if (!error && data) {
      allProducts.value = data;
    }
  } catch (err) {
    console.error('전체 제품 조회 오류:', err);
  }
}

async function fetchCompanies() {
  if (!selectedSettlementMonth.value) {
    companies.value = [];
    return;
  }
  
  try {
    let query = supabase
      .from('performance_records')
      .select('company_id, companies!inner(*)')
      .eq('settlement_month', selectedSettlementMonth.value);
    
    if (prescriptionOffset.value !== 0) {
      query = query.eq('prescription_month', prescriptionMonth.value);
    }
      
    const { data, error } = await query;
      
    if (error) {
      console.error('업체 조회 오류:', error);
      return;
    }
    
    const uniqueCompanies = [];
    const companyIds = new Set();
    
    data?.forEach(record => {
      if (record.companies && !companyIds.has(record.companies.id)) {
        companyIds.add(record.companies.id);
        uniqueCompanies.push({
          id: record.companies.id,
          company_name: record.companies.company_name,
        });
      }
    });
    
    companies.value = uniqueCompanies.sort((a, b) => a.company_name.localeCompare(b.company_name));
  } catch (err) {
    console.error('업체 목록 조회 예외:', err);
  }
}

async function fetchHospitals() {
  if (!selectedSettlementMonth.value) {
    hospitals.value = [];
    return;
  }
  
  try {
    let query = supabase
      .from('performance_records')
      .select('client_id, clients!inner(*)')
      .eq('settlement_month', selectedSettlementMonth.value);

    if (prescriptionOffset.value !== 0) {
      query = query.eq('prescription_month', prescriptionMonth.value);
    }

    if (selectedCompanyId.value) {
      query = query.eq('company_id', selectedCompanyId.value);
    }
      
    const { data, error } = await query;
      
    if (error) {
      console.error('거래처 목록 조회 오류:', error);
      return;
    }
    
    const uniqueHospitals = [];
    const seenIds = new Set();
    
    data?.forEach(record => {
      if (record.clients && !seenIds.has(record.clients.id)) {
        seenIds.add(record.clients.id);
        uniqueHospitals.push({
          id: record.clients.id,
          name: record.clients.name
        });
      }
    });
    
    hospitals.value = uniqueHospitals.sort((a, b) => a.name.localeCompare(b.name));
  } catch (err) {
    console.error('거래처 목록 조회 예외:', err);
    hospitals.value = [];
  }
}

// 정산월 선택 시 흡수율 분석 데이터 조회
async function loadAbsorptionAnalysisData() {
  if (!selectedSettlementMonth.value) {
    displayRows.value = [];
    return;
  }

  try {
    console.log('=== 흡수율 분석 데이터 조회 시작 ===');
    console.log('정산월:', selectedSettlementMonth.value);

    const { data, error } = await supabase
      .from('absorption_analysis')
      .select('*')
      .eq('settlement_month', selectedSettlementMonth.value)
      .order('created_at', { ascending: true });

    console.log('조회 결과:', data?.length || 0, '건');
    console.log('조회 오류:', error);
    
    if (data && data.length > 0) {
      console.log('첫 번째 데이터 샘플:', data[0]);
      console.log('company_group 필드:', data[0].company_group);
      console.log('assigned_pharmacist_contact 필드:', data[0].assigned_pharmacist_contact);
    }

    if (error) {
      console.error('흡수율 분석 데이터 조회 오류:', error);
      displayRows.value = [];
      hasExistingData.value = false; // 기존 데이터 없음
      return;
    }

    if (!data || data.length === 0) {
      console.log('조회된 데이터 없음');
      displayRows.value = [];
      hasExistingData.value = false; // 기존 데이터 없음
      return;
    }

    // 기존 데이터가 있음을 표시
    hasExistingData.value = true;

    displayRows.value = data.map(record => ({
      id: record.id,
      original_id: record.id,
      company_id: record.company_id,
      client_id: record.client_id,
      product_id: record.product_id,
      company_group: record.company_group,
      company_name: record.company_name,
      client_name: record.client_name,
      prescription_month: record.prescription_month,
      product_name: record.product_name,
      product_name_display: record.product_name,
      insurance_code: record.insurance_code,
      price: record.price ? Number(record.price).toLocaleString() : '',
      prescription_qty: record.prescription_qty,
      prescription_amount: record.prescription_amount ? Number(record.prescription_amount).toLocaleString() : '',
      prescription_type: record.prescription_type,
      wholesale_sales: record.wholesale_sales,
      direct_sales: record.direct_sales,
      total_sales: record.total_sales,
      absorption_rate: record.absorption_rate,
      commission_rate: record.commission_rate,
      payment_amount: record.payment_amount,
      remarks: record.remarks || '',
      orig_created_at: record.orig_created_at,
      orig_registered_by: record.orig_registered_by || '알 수 없음', // 원본 registered_by 값 사용
      assigned_pharmacist_contact: record.assigned_pharmacist_contact,
      isEditing: false
    }));
    
    console.log('매핑된 displayRows:', displayRows.value.length, '건');
    if (displayRows.value.length > 0) {
      console.log('첫 번째 매핑된 데이터:', displayRows.value[0]);
      console.log('매핑된 company_group:', displayRows.value[0].company_group);
      console.log('매핑된 assigned_pharmacist_contact:', displayRows.value[0].assigned_pharmacist_contact);
    }
    
    console.log(`${data.length}건의 흡수율 분석 데이터를 불러왔습니다.`);

  } catch (err) {
    console.error('흡수율 분석 데이터 조회 예외:', err);
    displayRows.value = [];
  }
}

// 실적 정보 불러오기 (performance_records에서)
async function loadPerformanceData() {
  if (!selectedSettlementMonth.value) {
    alert('정산월을 선택하세요.');
    return;
  }

  try {
    console.log('=== 실적 정보 불러오기 시작 ===');
    console.log('정산월:', selectedSettlementMonth.value);

    let query = supabase
      .from('performance_records')
      .select(`
        *,
        products!inner(
          product_name, 
          insurance_code, 
          price,
          commission_rate_a,
          commission_rate_b,
          commission_rate_c
        ),
        clients!inner(name),
        companies!inner(
          company_name, 
          company_group, 
          assigned_pharmacist_contact,
          default_commission_grade
        )
      `)
      .eq('settlement_month', selectedSettlementMonth.value);

    const { data, error } = await query.order('created_at', { ascending: true });

    console.log('조회 결과:', data?.length || 0, '건');
    console.log('조회 오류:', error);
    
    if (data && data.length > 0) {
      console.log('첫 번째 데이터 샘플:', data[0]);
    }

    if (error) {
      console.error('실적 데이터 조회 오류:', error);
      alert('실적 데이터 조회 중 오류가 발생했습니다.');
      return;
    }

    if (!data || data.length === 0) {
      alert('해당 정산월의 실적 데이터가 없습니다.');
      return;
    }

    const analysisData = [];
    
    hasExistingData.value = false;
    
    for (const record of data) {
      const row = {
        id: `temp_${Date.now()}_${Math.random()}`,
        original_id: record.id,
        company_id: record.company_id || record.companies.id,
        client_id: record.client_id,
        product_id: record.product_id,
        company_group: record.companies.company_group,
        company_name: record.companies.company_name,
        client_name: record.clients.name,
        prescription_month: record.prescription_month,
        product_name: record.products.product_name,
        product_name_display: record.products.product_name,
        insurance_code: record.products.insurance_code,
        price: record.products.price ? Number(record.products.price).toLocaleString() : '',
        prescription_qty: record.prescription_qty,
        prescription_amount: (record.prescription_qty * record.products.price).toLocaleString(),
        prescription_type: record.prescription_type,
        wholesale_sales: 0,
        direct_sales: 0,
        total_sales: 0,
        absorption_rate: 0,
        commission_rate: 0,
        payment_amount: 0,
        remarks: record.remarks || '',
        orig_created_at: record.created_at,
        orig_registered_by: record.companies.company_name,
        assigned_pharmacist_contact: record.companies.assigned_pharmacist_contact,
        isEditing: false
      };

      // 수수료율 자동 계산
      const company = record.companies;
      const product = record.products;
      
      if (company && product && company.default_commission_grade) {
        let commissionRateDecimal = null;
        const grade = company.default_commission_grade; // 'A', 'B', or 'C'

        switch (grade) {
          case 'A':
            commissionRateDecimal = product.commission_rate_a;
            break;
          case 'B':
            commissionRateDecimal = product.commission_rate_b;
            break;
          case 'C':
            commissionRateDecimal = product.commission_rate_c;
            break;
        }
        
        if (commissionRateDecimal !== null && commissionRateDecimal !== undefined && !isNaN(commissionRateDecimal)) {
          row.commission_rate = (Number(commissionRateDecimal) * 100).toFixed(1);
          const prescriptionAmount = record.prescription_qty * product.price;
          row.payment_amount = Math.round(prescriptionAmount * Number(commissionRateDecimal));
        } else {
          row.commission_rate = '0.0';
        }
      } else {
        row.commission_rate = '0.0';
      }
      analysisData.push(row);
    }

    displayRows.value = analysisData;
    
    alert(`${analysisData.length}건의 실적 데이터를 불러왔습니다.`);

  } catch (err) {
    console.error('실적 데이터 불러오기 예외:', err);
    alert('실적 데이터 불러오기 중 오류가 발생했습니다.');
  }
}



function recalculateRow(rowIndex) {
  const row = displayRows.value[rowIndex];
  
  // 처방액 재계산
  const priceNum = Number(row.price.toString().replace(/,/g, '')) || 0;
  const qty = Number(row.prescription_qty) || 0;
  const prescriptionAmount = qty * priceNum;
  row.prescription_amount = prescriptionAmount.toLocaleString();
  
  // 합산액 계산
  const wholesale = Number(row.wholesale_sales) || 0;
  const direct = Number(row.direct_sales) || 0;
  row.total_sales = wholesale + direct;
  
  // 흡수율 계산
  if (prescriptionAmount > 0) {
    row.absorption_rate = Math.round((row.total_sales / prescriptionAmount) * 100 * 100) / 100;
  } else {
    row.absorption_rate = 0;
  }
  
  // 지급액 계산 (처방액 x 수수료율)
  const commissionRate = Number(row.commission_rate) || 0;
  row.payment_amount = Math.round(prescriptionAmount * commissionRate / 100);
}

// 거래처 검색 관련 함수들
function handleClientNameInput(rowIndex, event) {
  const query = event.target.value;
  
  // 다른 드롭다운들 닫기
  closeOtherDropdowns('client');
  
  clientSearchForRow.value.activeRowIndex = rowIndex;
  clientSearchForRow.value.selectedIndex = -1;
  
  // 타겟 엘리먼트의 위치 계산 후 저장
  clientSearchForRow.value.position = calculateDropdownPosition(event.target);
  
  if (query.trim() === '') {
    clientSearchForRow.value.show = false;
    clientSearchForRow.value.results = [];
    return;
  }
  
  searchClients(query);
  markAsChanged(); // 사용자가 직접 입력할 때만
}

function handleClientNameFocus(rowIndex, event) {
  // 다른 드롭다운들 닫기
  closeOtherDropdowns('client');
  
  clientSearchForRow.value.activeRowIndex = rowIndex;
  
  // 타겟 엘리먼트의 위치 계산 후 저장
  if (event && event.target) {
    clientSearchForRow.value.position = calculateDropdownPosition(event.target);
  }
  
  const currentValue = displayRows.value[rowIndex].client_name;
  
  if (currentValue && currentValue.trim() !== '') {
    searchClients(currentValue);
  } else {
    showAllClients();
  }
}

async function searchClients(query) {
  try {
    let results = allClients.value;
    
    if (query && query.trim() !== '') {
      results = allClients.value.filter(client =>
        (client.name && client.name.toLowerCase().includes(query.trim().toLowerCase())) ||
        (client.business_registration_number && client.business_registration_number.includes(query.trim()))
      );
    }

    clientSearchForRow.value.results = results || [];
    clientSearchForRow.value.show = true;
  } catch (err) {
    console.error('거래처 검색 예외:', err);
  }
}

async function showAllClients() {
  try {
    clientSearchForRow.value.results = allClients.value || [];
    clientSearchForRow.value.show = true;
  } catch (err) {
    console.error('거래처 목록 조회 예외:', err);
  }
}

function toggleClientDropdown(rowIndex, event) {
  // 다른 드롭다운들 닫기
  closeOtherDropdowns('client');
  
    clientSearchForRow.value.activeRowIndex = rowIndex;
  
  // 드롭다운 버튼 클릭시 input 엘리먼트의 위치를 찾아서 계산
  if (event && event.target) {
    const inputElement = event.target.closest('.product-input-container').querySelector('input');
    if (inputElement) {
      clientSearchForRow.value.position = calculateDropdownPosition(inputElement);
    }
  }
  
  showAllClients();
}

function clickClientFromSearchList(client, rowIndex) {
  displayRows.value[rowIndex].client_name = client.name;
  clientSearchForRow.value.show = false;
  markAsChanged(); // 사용자가 선택했을 때
}

function hideClientSearchList(rowIndex) {
  if (clientSearchForRow.value.activeRowIndex === rowIndex) {
    clientSearchForRow.value.show = false;
    clientSearchForRow.value.results = [];
  }
}

function navigateClientSearchList(direction) {
  if (!clientSearchForRow.value.show || clientSearchForRow.value.results.length === 0) return;
  
  if (direction === 'down') {
    clientSearchForRow.value.selectedIndex = 
      clientSearchForRow.value.selectedIndex < clientSearchForRow.value.results.length - 1 
        ? clientSearchForRow.value.selectedIndex + 1 
        : 0;
  } else if (direction === 'up') {
    clientSearchForRow.value.selectedIndex = 
      clientSearchForRow.value.selectedIndex > 0 
        ? clientSearchForRow.value.selectedIndex - 1 
        : clientSearchForRow.value.results.length - 1;
  }
}

function applySelectedClientFromSearch(rowIndex) {
  if (clientSearchForRow.value.selectedIndex >= 0 && clientSearchForRow.value.results.length > 0) {
    const selectedClient = clientSearchForRow.value.results[clientSearchForRow.value.selectedIndex];
    clickClientFromSearchList(selectedClient, rowIndex);
  }
}

// 제품 검색 관련 함수들
function handleProductNameInput(rowIndex, event) {
  const query = event.target.value;
  
  // 다른 드롭다운들 닫기
  closeOtherDropdowns('product');
  
  productSearchForRow.value.activeRowIndex = rowIndex;
  productSearchForRow.value.selectedIndex = -1;
  
  // 타겟 엘리먼트의 위치 계산 후 저장
  productSearchForRow.value.position = calculateDropdownPosition(event.target);
  
  if (query.trim() === '') {
    productSearchForRow.value.show = false;
    productSearchForRow.value.results = [];
    return;
  }
  
  searchProducts(query);
  markAsChanged(); // 사용자가 직접 입력할 때만
}

function handleProductNameFocus(rowIndex, event) {
  // 다른 드롭다운들 닫기
  closeOtherDropdowns('product');
  
  productSearchForRow.value.activeRowIndex = rowIndex;
  
  // 타겟 엘리먼트의 위치 계산 후 저장
  if (event && event.target) {
    productSearchForRow.value.position = calculateDropdownPosition(event.target);
  }
  
  const currentValue = displayRows.value[rowIndex].product_name_display;
  
  if (currentValue && currentValue.trim() !== '') {
    searchProducts(currentValue);
  } else {
    showAllProducts();
  }
}

async function searchProducts(query) {
  try {
    let searchQuery = supabase
      .from('products')
      .select('*')
      .order('product_name');

    if (query && query.trim() !== '') {
      searchQuery = searchQuery.or(`product_name.ilike.%${query.trim()}%,insurance_code.ilike.%${query.trim()}%`);
    }

    const { data, error } = await searchQuery.limit(20);

    if (error) {
      console.error('제품 검색 오류:', error);
      return;
    }

    productSearchForRow.value.results = data || [];
    productSearchForRow.value.show = true;
  } catch (err) {
    console.error('제품 검색 예외:', err);
  }
}

async function showAllProducts() {
  try {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .order('product_name')
      .limit(50);

    if (error) {
      console.error('제품 목록 조회 오류:', error);
      return;
    }

    productSearchForRow.value.results = data || [];
    productSearchForRow.value.show = true;
  } catch (err) {
    console.error('제품 목록 조회 예외:', err);
  }
}

function toggleProductDropdown(rowIndex, event) {
  // 다른 드롭다운들 닫기
  closeOtherDropdowns('product');
  
    productSearchForRow.value.activeRowIndex = rowIndex;
  
  // 드롭다운 버튼 클릭시 input 엘리먼트의 위치를 찾아서 계산
  if (event && event.target) {
    const inputElement = event.target.closest('.product-input-container').querySelector('input');
    if (inputElement) {
      productSearchForRow.value.position = calculateDropdownPosition(inputElement);
    }
  }
  
  showAllProducts();
}

function clickProductFromSearchList(product, rowIndex) {
  const row = displayRows.value[rowIndex];
  row.product_name = product.product_name;
  row.product_name_display = product.product_name;
  row.insurance_code = product.insurance_code;
  row.price = Number(product.price).toLocaleString();
  
  productSearchForRow.value.show = false;
  
  recalculateRow(rowIndex);
  markAsChanged(); // 사용자가 제품을 선택했을 때
  
  if (row.company_name) {
    updateCommissionRate(rowIndex);
  }
}

function hideProductSearchList(rowIndex) {
  if (productSearchForRow.value.activeRowIndex === rowIndex) {
    productSearchForRow.value.show = false;
    productSearchForRow.value.activeRowIndex = -1;
  }
}

function navigateProductSearchList(direction) {
  if (!productSearchForRow.value.show || productSearchForRow.value.results.length === 0) return;
  
  if (direction === 'down') {
    productSearchForRow.value.selectedIndex = 
      productSearchForRow.value.selectedIndex < productSearchForRow.value.results.length - 1 
        ? productSearchForRow.value.selectedIndex + 1 
        : 0;
  } else if (direction === 'up') {
    productSearchForRow.value.selectedIndex = 
      productSearchForRow.value.selectedIndex > 0 
        ? productSearchForRow.value.selectedIndex - 1 
        : productSearchForRow.value.results.length - 1;
  }
}

function applySelectedProductFromSearch(rowIndex) {
  if (productSearchForRow.value.selectedIndex >= 0 && productSearchForRow.value.results.length > 0) {
    const selectedProduct = productSearchForRow.value.results[productSearchForRow.value.selectedIndex];
    clickProductFromSearchList(selectedProduct, rowIndex);
  }
}

// 유틸리티 함수
function truncateText(text, maxLength) {
  if (!text) return '';
  return text.length > maxLength ? text.substring(0, maxLength) + '...' : text;
}

// 편집 관련 함수들
function startEdit(rowData) {
  // 편집 시작 전 원본 데이터 백업
  rowData.originalData = { ...rowData };
  rowData.isEditing = true;
  markAsChanged();
}

function saveEdit(rowData) {
  // 편집 완료 시 재계산
  const rowIndex = displayRows.value.findIndex(row => row.id === rowData.id);
  if (rowIndex !== -1) {
    recalculateRow(rowIndex);
  }
  
  rowData.isEditing = false;
  delete rowData.originalData;
  markAsChanged();
}

function cancelEdit(rowData) {
  // 원본 데이터로 복원
  if (rowData.originalData) {
    Object.assign(rowData, rowData.originalData);
    delete rowData.originalData;
  }
  rowData.isEditing = false;
}

// 업체 변경 시 이벤트 핸들러
function onCompanyChange(rowData) {
  const company = allCompanies.value.find(c => c.id === rowData.company_id);
  if (company) {
    rowData.company_name = company.company_name;
    rowData.company_group = company.company_group || '';
    rowData.assigned_pharmacist_contact = company.assigned_pharmacist_contact || '';
    
    // 수수료율 자동 계산
    const rowIndex = displayRows.value.findIndex(row => row.id === rowData.id);
    if (rowIndex !== -1) {
      updateCommissionRate(rowIndex);
    }
  }
  markAsChanged();
}

// 거래처 변경 시 이벤트 핸들러
function onClientChange(rowData) {
  const client = allClients.value.find(c => c.id === rowData.client_id);
  if (client) {
    rowData.client_name = client.name;
  }
  markAsChanged();
}

// 제품 변경 시 이벤트 핸들러
function onProductChange(rowData) {
  const product = allProducts.value.find(p => p.id === rowData.product_id);
  if (product) {
    rowData.product_name = product.product_name;
    rowData.product_name_display = product.product_name;
    rowData.insurance_code = product.insurance_code;
    rowData.price = product.price ? Number(product.price).toLocaleString() : '0';
    
    // 처방액 재계산
    const rowIndex = displayRows.value.findIndex(row => row.id === rowData.id);
    if (rowIndex !== -1) {
      recalculateRow(rowIndex);
      // 수수료율 자동 계산
      updateCommissionRate(rowIndex);
    }
  }
  markAsChanged();
}

// 처방월 변경 시 이벤트 핸들러
function onPrescriptionMonthChange(rowData) {
  // 수수료율 자동 계산
  const rowIndex = displayRows.value.findIndex(row => row.id === rowData.id);
  if (rowIndex !== -1) {
    updateCommissionRate(rowIndex);
  }
  markAsChanged();
}

// 값 변경 시 이벤트 핸들러 (수량, 수수료율 등)
function onValueChange(rowData) {
  const rowIndex = displayRows.value.findIndex(row => row.id === rowData.id);
  if (rowIndex !== -1) {
    recalculateRow(rowIndex);
  }
  markAsChanged();
}

// 편집용 제품 필터링 함수
function getFilteredProducts(rowData) {
  return allProducts.value;
}

// 수수료율 자동 계산 함수 (개선된 버전)
async function updateCommissionRate(rowIndex) {
  const row = displayRows.value[rowIndex];
  
  if (!row.company_id || !row.product_id || !row.prescription_month) {
    return;
  }
  
  try {
    // 1. 업체의 수수료율 등급 조회
    const { data: companyData, error: companyError } = await supabase
      .from('companies')
      .select('commission_grade')
      .eq('id', row.company_id)
      .single();
    
    if (companyError || !companyData) {
      console.error('업체 정보 조회 오류:', companyError);
      return;
    }
    
    // 2. 처방월 기준으로 정산월 조회
    const { data: settlementData, error: settlementError } = await supabase
      .from('settlement_months')
      .select('id')
      .eq('settlement_month', row.prescription_month)
      .single();
    
    if (settlementError || !settlementData) {
      console.error('정산월 정보 조회 오류:', settlementError);
      return;
    }
    
    // 3. 해당 정산월, 제품, 등급의 수수료율 조회
    const { data: rateData, error: rateError } = await supabase
      .from('settlement_share')
      .select('commission_rate')
      .eq('settlement_month_id', settlementData.id)
      .eq('product_id', row.product_id)
      .eq('grade', companyData.commission_grade)
      .single();
    
    if (rateError || !rateData) {
      console.error('수수료율 정보 조회 오류:', rateError);
      return;
    }
    
    // 4. 수수료율 적용 (퍼센트로 변환)
    const commissionRate = (rateData.commission_rate || 0) * 100;
    row.commission_rate = commissionRate;
    
    // 5. 금액 재계산
    recalculateRow(rowIndex);
    
  } catch (err) {
    console.error('수수료율 계산 오류:', err);
  }
}

// 행 삭제/추가 함수들
function confirmDeleteRow(rowIndex) {
  if (displayRows.value.length === 1) {
    alert('최소 1개 행은 유지되어야 합니다.');
    return;
  }
  
  if (confirm('이 행을 삭제하시겠습니까?')) {
    displayRows.value.splice(rowIndex, 1);
    markAsChanged(); // 사용자가 행을 삭제했을 때
  }
}

function addRowBelow(rowIndex) {
  // 기본 처방월을 정산월 -1개월로 설정
  const defaultPrescriptionMonth = prescriptionMonthOptions.value.length > 0 
    ? prescriptionMonthOptions.value[0] 
    : selectedSettlementMonth.value;
  
  const newRow = {
    id: `new_${Date.now()}_${Math.random()}`,
    original_id: null,
    company_id: null,
    client_id: null,
    product_id: null,
    company_group: '',
    company_name: '',
    client_name: '',
    prescription_month: defaultPrescriptionMonth,
    product_name: '',
    product_name_display: '',
    insurance_code: '',
    price: '0',
    prescription_qty: 0,
    prescription_amount: '0',
    prescription_type: 'EDI',
    wholesale_sales: 0,
    direct_sales: 0,
    total_sales: 0,
    absorption_rate: 0,
    commission_rate: 0,
    payment_amount: 0,
    remarks: '',
    orig_created_at: new Date().toISOString(),
    orig_registered_by: '관리자', // 새로 추가하는 행은 관리자가 등록자
    assigned_pharmacist_contact: '',
    isEditing: false
  };
  
  displayRows.value.splice(rowIndex + 1, 0, newRow);
  markAsChanged(); // 사용자가 행을 추가했을 때
}

// 합계 계산
const totalPrescriptionQty = computed(() => {
  return displayRows.value.reduce((sum, row) => sum + (Number(row.prescription_qty) || 0), 0).toLocaleString();
});
const totalPrescriptionAmount = computed(() => {
  return displayRows.value.reduce((sum, row) => sum + (Number(row.prescription_amount?.toString().replace(/,/g, '')) || 0), 0).toLocaleString();
});
const totalWholesaleSales = computed(() => {
  return displayRows.value.reduce((sum, row) => sum + (Number(row.wholesale_sales) || 0), 0).toLocaleString();
});
const totalDirectSales = computed(() => {
  return displayRows.value.reduce((sum, row) => sum + (Number(row.direct_sales) || 0), 0).toLocaleString();
});
const totalSales = computed(() => {
  return displayRows.value.reduce((sum, row) => sum + (Number(row.total_sales) || 0), 0).toLocaleString();
});
const totalPaymentAmount = computed(() => {
  return displayRows.value.reduce((sum, row) => sum + (Number(row.payment_amount) || 0), 0).toLocaleString();
});

// 엑셀 다운로드
function downloadExcel() {
  if (displayRows.value.length === 0) {
    alert('다운로드할 데이터가 없습니다.');
    return;
  }

  const excelData = displayRows.value.map(row => ({
    '구분': row.company_group,
    '업체명': row.company_name,
    '거래처': row.client_name,
    '처방월': row.prescription_month,
    '제품명': row.product_name,
    '보험코드': row.insurance_code,
    '약가': Number(row.price?.toString().replace(/,/g, '')),
    '처방수량': Number(row.prescription_qty),
    '처방액': Number(row.prescription_amount?.toString().replace(/,/g, '')),
    '처방구분': row.prescription_type,
    '도매매출': Number(row.wholesale_sales),
    '직거래매출': Number(row.direct_sales),
    '합산액': Number(row.total_sales),
    '흡수율(%)': Number(row.absorption_rate),
    '수수료율(%)': Number(row.commission_rate),
    '지급액': Number(row.payment_amount),
    '비고': row.remarks,
    '원본등록일시': formatDateTime(row.orig_created_at),
    '원본등록자': row.orig_registered_by,
    '관리자': row.assigned_pharmacist_contact,
  }));

  const ws = XLSX.utils.json_to_sheet(excelData);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '흡수율분석');
  ws['!cols'] = [
    { width: 10 }, { width: 15 }, { width: 20 }, { width: 10 }, { width: 20 },
    { width: 12 }, { width: 10 }, { width: 10 }, { width: 12 }, { width: 10 },
    { width: 12 }, { width: 12 }, { width: 12 }, { width: 10 }, { width: 10 },
    { width: 12 }, { width: 15 }, { width: 15 }, { width: 15 }, { width: 15 }
  ];

  const numCols = [6,7,8,10,11,12,14,15]; // G~J, L~M, O, P
  const range = XLSX.utils.decode_range(ws['!ref']);
  for (let row = 1; row <= range.e.r; row++) {
    numCols.forEach(col => {
      const cell = ws[XLSX.utils.encode_cell({ r: row, c: col })];
      if (cell) cell.z = '#,##0';
    });
  }

  const today = new Date().toISOString().split('T')[0];
  const fileName = `흡수율분석_${selectedSettlementMonth.value || ''}_${today}.xlsx`;
  XLSX.writeFile(wb, fileName);
}

// 저장 기능
async function saveAnalysisData() {
  if (displayRows.value.length === 0) {
    alert('저장할 데이터가 없습니다.');
    return;
  }
  
  // 저장 전 company_id 없는 row 처리
  for (const row of displayRows.value) {
    if (!row.company_id && row.company_name) {
      // company_name으로 company_id 찾기
      const { data: company, error } = await supabase
        .from('companies')
        .select('id')
        .eq('company_name', row.company_name.trim())
        .single();
      if (company && company.id) {
        row.company_id = company.id;
      }
    }
  }
  
  const validRows = displayRows.value.filter(row => 
    row.company_name && row.client_name && row.product_name
  );
  
  if (validRows.length === 0) {
    alert('저장할 유효한 데이터가 없습니다. 업체명, 거래처, 제품명을 모두 입력해주세요.');
    return;
  }
  
  try {
    const { error: deleteError } = await supabase
      .from('absorption_analysis')
      .delete()
      .eq('settlement_month', selectedSettlementMonth.value);
      
    if (deleteError) {
      throw new Error('기존 데이터 삭제 실패: ' + deleteError.message);
    }
    
    const saveData = validRows.map(row => ({
        settlement_month: selectedSettlementMonth.value,
        prescription_month: row.prescription_month,
        company_id: row.company_id,
        client_id: row.client_id,
        product_id: row.product_id,
        company_group: row.company_group,
        company_name: row.company_name,
        client_name: row.client_name,
        product_name: row.product_name,
        insurance_code: row.insurance_code,
        price: Number(row.price.toString().replace(/,/g, '')) || 0,
        prescription_qty: Number(row.prescription_qty) || 0,
        prescription_amount: Number(row.prescription_amount.toString().replace(/,/g, '')) || 0,
        prescription_type: row.prescription_type,
        wholesale_sales: Number(row.wholesale_sales) || 0,
        direct_sales: Number(row.direct_sales) || 0,
        total_sales: Number(row.total_sales) || 0,
        absorption_rate: Number(row.absorption_rate) || 0,
        commission_rate: Number(row.commission_rate) || 0,
        payment_amount: Number(row.payment_amount) || 0,
        remarks: row.remarks || '',
        orig_created_at: row.orig_created_at,
        orig_registered_by: row.orig_registered_by,
        assigned_pharmacist_contact: row.assigned_pharmacist_contact || ''
    }));
    
    const { error: insertError } = await supabase
      .from('absorption_analysis')
      .insert(saveData);
      
    if (insertError) {
      throw new Error('데이터 저장 실패: ' + insertError.message);
    }
    
    // 변경사항 초기화
    hasUnsavedChanges.value = false;
    
    alert(`${validRows.length}건의 흡수율 분석 데이터가 저장되었습니다.`);
    
    // 저장 후 데이터 다시 로드하여 최신 상태 반영
    await loadAbsorptionAnalysisData();
    
  } catch (err) {
    console.error('저장 예외:', err);
    alert('저장 중 오류가 발생했습니다: ' + err.message);
  }
}

// 흡수율 분석 실행 (기존 로직 유지)
async function runAbsorptionAnalysis() {
  if (displayRows.value.length === 0) {
    alert('분석할 데이터가 없습니다. 먼저 실적 정보를 불러오세요.');
    return;
  }

  console.log('🚀 흡수율 분석 시작...');
  
  try {
    // 데이터 준비
    const { data: wholesaleSales, error: wholesaleError } = await supabase.from('wholesale_sales').select('*');
    if (wholesaleError) throw new Error('도매매출 데이터 조회 실패: ' + wholesaleError.message);

    const { data: directSales, error: directError } = await supabase.from('direct_sales').select('*');
    if (directError) throw new Error('직거래매출 데이터 조회 실패: ' + directError.message);
    
    const { data: products, error: productsError } = await supabase.from('products').select('insurance_code, standard_code');
    if (productsError) throw new Error('제품 정보 조회 실패: ' + productsError.message);

    const { data: pharmacyMappings, error: mappingError } = await supabase.from('pharmacy_mappings').select('client_id, pharmacy_id');
    if (mappingError) console.warn('병원-약국 매핑 정보 조회 실패:', mappingError.message);

    // [규칙 2] 보험코드 -> 표준코드 목록 맵 생성
    const insuranceToStandardMap = products.reduce((map, p) => {
      if (p.insurance_code && p.standard_code) {
        if (!map[p.insurance_code]) {
          map[p.insurance_code] = [];
        }
        map[p.insurance_code].push(p.standard_code);
      }
      return map;
    }, {});

    for (let i = 0; i < displayRows.value.length; i++) {
      const row = displayRows.value[i];
      
      const wholesaleAmount = await calculateWholesaleAmount(
        row, wholesaleSales, insuranceToStandardMap, pharmacyMappings || []
      );
      
      const directAmount = await calculateDirectAmount(
        row, directSales, insuranceToStandardMap, pharmacyMappings || []
      );
      
      row.wholesale_sales = wholesaleAmount;
      row.direct_sales = directAmount;
      
      recalculateRow(i);
    }

    alert('흡수율 분석이 완료되었습니다.');

  } catch (err) {
    console.error('흡수율 분석 오류:', err);
    alert('흡수율 분석 중 오류가 발생했습니다:\n' + err.message);
  }
}

// 도매매출 계산 함수
async function calculateWholesaleAmount(row, wholesaleSales, insuranceToStandardMap, pharmacyMappings) {
  const standardCodes = insuranceToStandardMap[row.insurance_code] || [];
  if (standardCodes.length === 0) return 0;
  
  const prescriptionYearMonth = row.prescription_month.substring(0, 7);

  const totalAmount = wholesaleSales
    .filter(sale => 
      standardCodes.includes(sale.standard_code) &&
      sale.sale_date.startsWith(prescriptionYearMonth)
    )
    .reduce((sum, sale) => sum + (sale.amount || 0), 0);
    
  return totalAmount;
}

// 직거래매출 계산 함수  
async function calculateDirectAmount(row, directSales, insuranceToStandardMap, pharmacyMappings) {
  // TODO: 다음 단계에서 구현
  console.log(`  📊 직거래매출 계산: ${row.product_name_display}`);
  return 0;
}

// 라이프사이클
onMounted(async () => {
  await fetchAvailableMonths();
  await fetchAllMasterData();
  
  document.addEventListener('click', handleGlobalClick);
});

onUnmounted(() => {
  document.removeEventListener('click', handleGlobalClick);
});

// 페이지 이동시 확인 팝업
onBeforeRouteLeave((to, from, next) => {
  if (hasUnsavedChanges.value) {
    const answer = confirm('저장하지 않은 변경사항이 있습니다. 정말 페이지를 떠나시겠습니까?');
    if (answer) {
      hasUnsavedChanges.value = false; // 강제로 초기화
      next();
    } else {
      next(false);
    }
  } else {
    next();
  }
});

function handleGlobalClick(event) {
  const isDropdownElement = event.target.closest('.product-input-container') ||
                           event.target.closest('.search-dropdown') ||
                           event.target.closest('select') ||
                           event.target.closest('.dropdown-arrow-btn');
  
  // 드롭다운 관련 요소가 아닌 곳을 클릭했을 때 모든 드롭다운 닫기
  if (!isDropdownElement) {
    closeAllDropdowns();
  }
}

// 업체명 검색 관련 함수들
function handleCompanyNameInput(rowIndex, event) {
  const query = event.target.value;
  
  // 다른 드롭다운들 닫기
  closeOtherDropdowns('company');
  
  companySearchForRow.value.activeRowIndex = rowIndex;
  companySearchForRow.value.selectedIndex = -1;
  
  // 타겟 엘리먼트의 위치 계산 후 저장
  companySearchForRow.value.position = calculateDropdownPosition(event.target);
  
  if (query.trim() === '') {
    companySearchForRow.value.show = false;
    companySearchForRow.value.results = [];
    return;
  }
  
  searchCompanies(query);
  markAsChanged(); // 사용자가 직접 입력할 때만
}

function handleCompanyNameFocus(rowIndex, event) {
  // 다른 드롭다운들 닫기
  closeOtherDropdowns('company');
  
  companySearchForRow.value.activeRowIndex = rowIndex;
  
  // 타겟 엘리먼트의 위치 계산 후 저장
  if (event && event.target) {
    companySearchForRow.value.position = calculateDropdownPosition(event.target);
  }
  
  const currentValue = displayRows.value[rowIndex].company_name;
  
  if (currentValue && currentValue.trim() !== '') {
    searchCompanies(currentValue);
  } else {
    showAllCompanies();
  }
}

async function searchCompanies(query) {
  try {
    const { data, error } = await supabase
      .from('companies')
      .select('*')
      .or(`company_name.ilike.%${query.trim()}%,representative_name.ilike.%${query.trim()}%`)
      .order('company_name')
      .limit(20);
      
    if (error) {
      console.error('업체 검색 오류:', error);
      return;
    }
    
    companySearchForRow.value.results = data || [];
    companySearchForRow.value.show = true;
  } catch (err) {
    console.error('업체 검색 예외:', err);
  }
}

async function showAllCompanies() {
  try {
    const { data, error } = await supabase
      .from('companies')
      .select('*')
      .order('company_name')
      .limit(50);
      
    if (error) {
      console.error('업체 목록 조회 오류:', error);
      return;
    }
    
    companySearchForRow.value.results = data || [];
    companySearchForRow.value.show = true;
  } catch (err) {
    console.error('업체 목록 조회 예외:', err);
  }
}

function toggleCompanyDropdown(rowIndex, event) {
  // 다른 드롭다운들 닫기
  closeOtherDropdowns('company');
  
  companySearchForRow.value.activeRowIndex = rowIndex;
  
  // 드롭다운 버튼 클릭시 input 엘리먼트의 위치를 찾아서 계산
  if (event && event.target) {
    const inputElement = event.target.closest('.product-input-container').querySelector('input');
    if (inputElement) {
      companySearchForRow.value.position = calculateDropdownPosition(inputElement);
    }
  }
  
  showAllCompanies();
}

function clickCompanyFromSearchList(company, rowIndex) {
  displayRows.value[rowIndex].company_id = company.id; // company_id 추가
  displayRows.value[rowIndex].company_name = company.company_name;
  displayRows.value[rowIndex].company_group = company.company_group || '';
  displayRows.value[rowIndex].assigned_pharmacist_contact = company.assigned_pharmacist_contact || '';
  companySearchForRow.value.show = false;
  markAsChanged(); // 사용자가 업체를 선택했을 때
  
  // 수수료율 자동 업데이트
  updateCommissionRate(rowIndex);
}

function hideCompanySearchList(rowIndex) {
  if (companySearchForRow.value.activeRowIndex === rowIndex) {
    companySearchForRow.value.show = false;
    companySearchForRow.value.results = [];
  }
}

function navigateCompanySearchList(direction) {
  if (!companySearchForRow.value.show || companySearchForRow.value.results.length === 0) return;
  
  if (direction === 'down') {
    companySearchForRow.value.selectedIndex = 
      companySearchForRow.value.selectedIndex < companySearchForRow.value.results.length - 1 
        ? companySearchForRow.value.selectedIndex + 1 
        : 0;
  } else if (direction === 'up') {
    companySearchForRow.value.selectedIndex = 
      companySearchForRow.value.selectedIndex > 0 
        ? companySearchForRow.value.selectedIndex - 1 
        : companySearchForRow.value.results.length - 1;
  }
}

function applySelectedCompanyFromSearch(rowIndex) {
  if (companySearchForRow.value.selectedIndex >= 0 && companySearchForRow.value.results.length > 0) {
    const selectedCompany = companySearchForRow.value.results[companySearchForRow.value.selectedIndex];
    clickCompanyFromSearchList(selectedCompany, rowIndex);
  }
}

// 변경사항 표시
function markAsChanged() {
  hasUnsavedChanges.value = true;
}

// 모든 드롭다운 닫기
function closeAllDropdowns() {
  clientSearchForRow.value.show = false;
  productSearchForRow.value.show = false;
  companySearchForRow.value.show = false;
  
  clientSearchForRow.value.results = [];
  productSearchForRow.value.results = [];
  companySearchForRow.value.results = [];
  
  clientSearchForRow.value.activeRowIndex = -1;
  productSearchForRow.value.activeRowIndex = -1;
  companySearchForRow.value.activeRowIndex = -1;
}

// 다른 드롭다운들 닫기 (현재 열린 것 제외)
function closeOtherDropdowns(currentType) {
  if (currentType !== 'client') {
    clientSearchForRow.value.show = false;
    clientSearchForRow.value.results = [];
    clientSearchForRow.value.activeRowIndex = -1;
  }
  if (currentType !== 'product') {
  productSearchForRow.value.show = false;
    productSearchForRow.value.results = [];
  productSearchForRow.value.activeRowIndex = -1;
  }
  if (currentType !== 'company') {
    companySearchForRow.value.show = false;
    companySearchForRow.value.results = [];
    companySearchForRow.value.activeRowIndex = -1;
  }
}


// 전체 삭제 기능
async function confirmDeleteAllData() {
  if (displayRows.value.length === 0) {
    alert('삭제할 데이터가 없습니다.');
    return;
  }
  
  if (!selectedSettlementMonth.value) {
    alert('정산월을 선택하세요.');
    return;
  }

  const deleteMessage = hasExistingData.value 
    ? `${selectedSettlementMonth.value} 정산월의 모든 흡수율 분석 데이터를 DB에서 완전히 삭제하시겠습니까?\n\n⚠️ 이 작업은 되돌릴 수 없습니다!`
    : '현재 화면의 모든 데이터를 삭제하시겠습니까?';

  if (!confirm(deleteMessage)) {
    return;
  }

  try {
    // DB에 저장된 데이터가 있는 경우 DB에서도 삭제
    if (hasExistingData.value) {
      console.log('DB에서 흡수율 분석 데이터 삭제 중...', selectedSettlementMonth.value);
      
      const { error } = await supabase
        .from('absorption_analysis')
        .delete()
        .eq('settlement_month', selectedSettlementMonth.value);

    if (error) {
        throw new Error('DB 삭제 실패: ' + error.message);
      }
      
      console.log('DB 삭제 완료');
      hasExistingData.value = false; // 기존 데이터 없음으로 변경
    }
    
    // 화면 데이터 삭제
    displayRows.value = [];
    hasUnsavedChanges.value = false; // 삭제 후에는 저장할 변경사항이 없음
    
    alert('전체 데이터가 삭제되었습니다.');
    
  } catch (err) {
    console.error('전체 삭제 오류:', err);
    alert('삭제 중 오류가 발생했습니다: ' + err.message);
  }
}

// 날짜 포맷 함수
function formatDateTime(dateTimeString) {
  if (!dateTimeString) return '-';
  const date = new Date(dateTimeString);
  if (isNaN(date.getTime())) return '-';
  
  // 한국 시간(UTC+9)으로 변환
  const kstOffset = 9 * 60 * 60 * 1000;
  const kstDate = new Date(date.getTime() + kstOffset);
  
  const year = kstDate.getUTCFullYear();
  const month = String(kstDate.getUTCMonth() + 1).padStart(2, '0');
  const day = String(kstDate.getUTCDate()).padStart(2, '0');
  const hours = String(kstDate.getUTCHours()).padStart(2, '0');
  const minutes = String(kstDate.getUTCMinutes()).padStart(2, '0');
  
  return `${year}-${month}-${day} ${hours}:${minutes}`;
}
</script>

