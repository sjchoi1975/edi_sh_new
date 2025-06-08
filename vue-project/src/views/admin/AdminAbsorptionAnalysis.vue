<template>
  <div class="performance-register-view page-container absorption-analysis" style="display: flex; flex-direction: column; height: 100vh;">
    <div class="page-header-title-area" style="flex-shrink: 0;">
    <div class="header-title">흡수율 분석</div>
    </div>

    <!-- 필터 카드: 정산월, 처방월, 업체, 거래처 드롭다운 -->
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
      
    <!-- 데이터 카드: 전체 n건 + 버튼들 + 테이블 + 합계 행 -->
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
            :disabled="displayRows.length === 0 || (hasExistingData && !hasUnsavedChanges)"
            :class="{ 'btn-disabled': displayRows.length === 0 || (hasExistingData && !hasUnsavedChanges) }"
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
            wrapper: { style: 'min-width: 3000px;' },
            table: { style: 'min-width: 3000px;' }
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
          <Column field="company_name" header="업체명" :headerStyle="{ width: columnWidths.company_name }" :sortable="true" />
          <Column field="client_name" header="거래처" :headerStyle="{ width: columnWidths.client_name }" :sortable="true" />
          <Column field="prescription_month" header="처방월" :headerStyle="{ width: columnWidths.prescription_month }" :sortable="true" />
          <Column field="product_name_display" header="제품명" :headerStyle="{ width: columnWidths.product_name_display }" :sortable="true" />
          <Column field="insurance_code" header="보험코드" :headerStyle="{ width: columnWidths.insurance_code }" :sortable="true" />
          <Column field="price" header="약가" :headerStyle="{ width: columnWidths.price }" :sortable="true" />
          <Column field="prescription_qty" header="처방수량" :headerStyle="{ width: columnWidths.prescription_qty }" :sortable="true" />
          <Column field="prescription_amount" header="처방액" :headerStyle="{ width: columnWidths.prescription_amount }" :sortable="true" />
          <Column field="prescription_type" header="처방구분" :headerStyle="{ width: columnWidths.prescription_type }" :sortable="true" />
          <Column field="wholesale_sales" header="도매매출" :headerStyle="{ width: columnWidths.wholesale_sales }" :sortable="true" />
          <Column field="direct_sales" header="직거래매출" :headerStyle="{ width: columnWidths.direct_sales }" :sortable="true" />
          <Column field="total_sales" header="합산액" :headerStyle="{ width: columnWidths.total_sales }" :sortable="true" />
          <Column field="absorption_rate" header="흡수율" :headerStyle="{ width: columnWidths.absorption_rate }" :sortable="true" />
          <Column field="commission_rate" header="수수료율" :headerStyle="{ width: columnWidths.commission_rate }" :sortable="true" />
          <Column field="payment_amount" header="지급액" :headerStyle="{ width: columnWidths.payment_amount }" :sortable="true" />
          <Column field="remarks" header="비고" :headerStyle="{ width: columnWidths.remarks }" :sortable="true" />
          <Column field="orig_created_at" header="등록일시" :headerStyle="{ width: columnWidths.orig_created_at }" :sortable="true">
            <template #body="slotProps">
              {{ formatDateTime(slotProps.data.orig_created_at) }}
            </template>
          </Column>
          <Column field="orig_registered_by" header="등록자" :headerStyle="{ width: columnWidths.orig_registered_by }" :sortable="true" />
          <Column field="assigned_pharmacist_contact" header="관리자" :headerStyle="{ width: columnWidths.assigned_pharmacist_contact }" :sortable="true" />
          <Column header="작업" :headerStyle="{ width: columnWidths.actions }" frozen frozenPosition="right" />

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
                    <Column footer="" footerClass="footer-cell" frozen />
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
  actions: '8%'  // 픽셀 단위로 고정
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
const companies = ref([]);
const hospitals = ref([]);

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

// 편집용 처방월 옵션 업데이트
function updatePrescriptionMonthOptions() {
  if (!selectedSettlementMonth.value) {
    prescriptionMonthOptions.value = [];
    return;
  }
  
  prescriptionMonthOptions.value = [1, 2, 3].map(offset => ({
    value: getPrescriptionMonth(selectedSettlementMonth.value, offset),
    month: getPrescriptionMonth(selectedSettlementMonth.value, offset)
  }));
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
  companies.value = [];
  hospitals.value = [];
  hasExistingData.value = false; // 기존 데이터 존재 여부 초기화
  
  // 정산월 선택 시 흡수율 분석 데이터 자동 조회
  if (selectedSettlementMonth.value) {
    loadAbsorptionAnalysisData();
    fetchCompanies();
    fetchHospitals();
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

async function fetchCompanies() {
  try {
    const { data, error } = await supabase
      .from('companies')
      .select('*')
      .order('company_name');
      
    if (error) {
      console.error('업체 목록 조회 오류:', error);
      return;
    }
    
    companies.value = data || [];
    allCompanies.value = data || [];
  } catch (err) {
    console.error('업체 목록 조회 예외:', err);
  }
}

async function fetchHospitals() {
  try {
    const { data, error } = await supabase
      .from('clients')
      .select('*')
      .eq('status', 'active')
      .order('name');
      
    if (error) {
      console.error('거래처 목록 조회 오류:', error);
      return;
    }
    
    hospitals.value = data || [];
    allClients.value = data || [];
  } catch (err) {
    console.error('거래처 목록 조회 예외:', err);
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
      assigned_pharmacist_contact: record.assigned_pharmacist_contact
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
        products!inner(product_name, insurance_code, price),
        clients!inner(name),
        companies!inner(company_name, company_group, assigned_pharmacist_contact)
      `)
      .eq('settlement_month', selectedSettlementMonth.value);

    const { data, error } = await query.order('created_at', { ascending: true });

    console.log('조회 결과:', data?.length || 0, '건');
    console.log('조회 오류:', error);
    
    if (data && data.length > 0) {
      console.log('첫 번째 데이터 샘플:', data[0]);
      console.log('companies 조인 데이터:', data[0].companies);
      console.log('company_group:', data[0].companies?.company_group);
      console.log('assigned_pharmacist_contact:', data[0].companies?.assigned_pharmacist_contact);
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
    
    // 실적 정보를 불러올 때는 기존 데이터가 없는 상태
    hasExistingData.value = false;
    
    for (const record of data) {
      const row = {
        id: `temp_${Date.now()}_${Math.random()}`,
        original_id: record.id,
        company_id: record.company_id || record.companies.id, // company_id 추가 (없으면 companies.id)
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
        orig_registered_by: record.companies.company_name, // 등록자는 업체명으로 설정
        assigned_pharmacist_contact: record.companies.assigned_pharmacist_contact
      };

      console.log('처리 중인 행:', row.company_name);
      console.log('company_group:', row.company_group);
      console.log('assigned_pharmacist_contact:', row.assigned_pharmacist_contact);

      // 수수료율 자동 계산
      try {
        // 업체 정보 조회
        const { data: company, error: companyError } = await supabase
          .from('companies')
          .select('commission_grade')
          .eq('company_name', record.companies.company_name.trim())
          .single();

        if (companyError) {
          console.warn(`업체 정보 조회 실패 (${record.companies.company_name}):`, companyError.message);
        } else if (!company || !company.commission_grade) {
          console.warn(`업체 수수료 등급 정보 없음: ${record.companies.company_name}`);
        } else {
        // 제품 정보 조회
          const { data: product, error: productError } = await supabase
          .from('products')
          .select('commission_rate_A, commission_rate_B, commission_rate_C')
          .eq('product_name', record.products.product_name.trim())
          .single();

          if (productError) {
            console.warn(`제품 정보 조회 실패 (${record.products.product_name}):`, productError.message);
          } else if (!product) {
            console.warn(`제품 수수료율 정보 없음: ${record.products.product_name}`);
          } else {
          const commissionField = `commission_rate_${company.commission_grade}`;
          const commissionRate = product[commissionField];
          
            if (commissionRate !== null && commissionRate !== undefined && !isNaN(commissionRate)) {
            const percentageRate = Number(commissionRate) * 100;
            row.commission_rate = percentageRate;
            
            const prescriptionAmount = record.prescription_qty * record.products.price;
            row.payment_amount = Math.round(prescriptionAmount * commissionRate);
            
              console.log(`수수료율 계산 성공: ${record.products.product_name} - ${percentageRate}%`);
            } else {
              console.warn(`수수료율 값이 유효하지 않음: ${record.products.product_name}, ${commissionField}=${commissionRate}`);
            }
          }
        }
      } catch (err) {
        console.error(`수수료율 계산 예외 (${record.products.product_name}):`, err);
        // 에러가 발생해도 계속 진행
      }

      analysisData.push(row);
    }

    displayRows.value = analysisData;
    
    console.log('최종 analysisData:', analysisData.length, '건');
    if (analysisData.length > 0) {
      console.log('첫 번째 최종 데이터:', analysisData[0]);
      console.log('최종 company_group:', analysisData[0].company_group);
      console.log('최종 assigned_pharmacist_contact:', analysisData[0].assigned_pharmacist_contact);
    }
    
    alert(`${analysisData.length}건의 실적 데이터를 불러왔습니다.`);

  } catch (err) {
    console.error('실적 데이터 불러오기 예외:', err);
    alert('실적 데이터 불러오기 중 오류가 발생했습니다.');
  }
}

// 이벤트 핸들러
async function onCompanyInput(rowIndex) {
  updateCommissionRate(rowIndex);
  markAsChanged(); // 업체 변경시
}

function onQtyInput(rowIndex) {
  recalculateRow(rowIndex);
  markAsChanged(); // 수량 변경시
}

function onPrescriptionTypeInput(rowIndex) {
  // 처방구분 변경시 처리
  markAsChanged(); // 처방구분 변경시
}

function onSalesInput(rowIndex) {
  recalculateRow(rowIndex);
  markAsChanged(); // 매출 변경시
}

function onCommissionInput(rowIndex) {
  recalculateRow(rowIndex);
  markAsChanged(); // 수수료율 변경시
}

// 수수료율 자동 조회 함수
async function updateCommissionRate(rowIndex) {
  const row = displayRows.value[rowIndex];
  
  if (!row.company_name || !row.product_name) {
    return;
  }
  
  try {
    const { data: company, error: companyError } = await supabase
      .from('companies')
      .select('commission_grade, company_name')
      .eq('company_name', row.company_name.trim())
      .single();
      
    if (companyError || !company) {
      return;
    }
    
    const { data: product, error: productError } = await supabase
      .from('products')
      .select('*')
      .eq('product_name', row.product_name.trim())
      .single();
      
    if (productError || !product) {
      return;
    }
    
    const commissionField = `commission_rate_${company.commission_grade}`;
    const commissionRate = product[commissionField];
    
    if (commissionRate !== null && commissionRate !== undefined) {
      const percentageRate = Number(commissionRate) * 100;
      row.commission_rate = percentageRate;
      recalculateRow(rowIndex);
    }
    
  } catch (err) {
    console.error('수수료율 조회 예외:', err);
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

function confirmAddRowBelow(rowIndex) {
  const newRow = {
    id: `new_${Date.now()}_${Math.random()}`,
    original_id: null,
    company_group: '',
    company_name: '',
    client_name: '',
    prescription_month: selectedSettlementMonth.value,
    product_name: '',
    product_name_display: '',
    insurance_code: '',
    price: '',
    prescription_qty: 0,
    prescription_amount: '',
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
    assigned_pharmacist_contact: ''
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
        company_id: row.company_id, // company_id 저장
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
  console.log(`분석 대상: ${displayRows.value.length}건`);

  try {
    // 1단계: 처방월 범위 확인
    const prescriptionMonths = [...new Set(displayRows.value.map(row => row.prescription_month))];
    console.log('처방월 범위:', prescriptionMonths);

    // 2단계: 도매매출 데이터 조회
    console.log('📋 도매매출 데이터 조회 중...');
    const { data: wholesaleSales, error: wholesaleError } = await supabase
      .from('wholesale_sales')
      .select('*');

    if (wholesaleError) {
      throw new Error('도매매출 데이터 조회 실패: ' + wholesaleError.message);
    }

    console.log(`도매매출 데이터: ${wholesaleSales?.length || 0}건`);

    // 3단계: 직거래매출 데이터 조회  
    console.log('📋 직거래매출 데이터 조회 중...');
    const { data: directSales, error: directError } = await supabase
      .from('direct_sales')
      .select('*');

    if (directError) {
      throw new Error('직거래매출 데이터 조회 실패: ' + directError.message);
    }

    console.log(`직거래매출 데이터: ${directSales?.length || 0}건`);

    // 4단계: 제품 정보 조회 (보험코드-표준코드 매핑용)
    console.log('📋 제품 정보 조회 중...');
    const { data: products, error: productsError } = await supabase
      .from('products')
      .select('*');

    if (productsError) {
      throw new Error('제품 정보 조회 실패: ' + productsError.message);
    }

    console.log(`제품 정보: ${products?.length || 0}건`);

    // 5단계: 병원-약국 매핑 정보 조회
    console.log('📋 병원-약국 매핑 정보 조회 중...');
    const { data: pharmacyMappings, error: mappingError } = await supabase
      .from('pharmacy_mappings')
      .select(`
        *,
        clients!inner(name, business_registration_number),
        pharmacies!inner(pharmacy_name, business_registration_number)
      `);

    if (mappingError) {
      console.warn('병원-약국 매핑 정보 조회 실패:', mappingError.message);
      // 매핑 정보가 없어도 일단 진행
    }

    console.log(`병원-약국 매핑: ${pharmacyMappings?.length || 0}건`);

    // 6단계: 매출 데이터 필터링 및 매칭 준비
    console.log('🔍 매출 데이터 매칭 시작...');
    
    let processedCount = 0;
    let matchedWholesale = 0;
    let matchedDirect = 0;

    for (let i = 0; i < displayRows.value.length; i++) {
      const row = displayRows.value[i];
      
      console.log(`[${i+1}/${displayRows.value.length}] 처리 중: ${row.client_name} - ${row.product_name_display}`);
      
      // 7단계: 해당 행의 도매매출 계산
      const wholesaleAmount = await calculateWholesaleAmount(
        row, wholesaleSales, products, pharmacyMappings
      );
      
      // 8단계: 해당 행의 직거래매출 계산  
      const directAmount = await calculateDirectAmount(
        row, directSales, products, pharmacyMappings
      );
      
      // 9단계: 결과 적용
      row.wholesale_sales = wholesaleAmount;
      row.direct_sales = directAmount;
      
      if (wholesaleAmount > 0) matchedWholesale++;
      if (directAmount > 0) matchedDirect++;
      
      processedCount++;
      
      // 실시간 재계산
      recalculateRow(i);
    }

    // 분석 완료 메시지
    alert(`흡수율 분석 완료!\n\n` +
          `✅ 처리 건수: ${processedCount}건\n` +
          `📊 도매매출 매칭: ${matchedWholesale}건\n` +
          `📊 직거래매출 매칭: ${matchedDirect}건\n\n` +
          `이제 합산액과 흡수율이 자동 계산되었습니다.`);

  } catch (err) {
    console.error('흡수율 분석 오류:', err);
    alert('흡수율 분석 중 오류가 발생했습니다:\n' + err.message);
  }
}

// 도매매출 계산 함수
async function calculateWholesaleAmount(row, wholesaleSales, products, pharmacyMappings) {
  // TODO: 다음 단계에서 구현
  console.log(`  📊 도매매출 계산: ${row.product_name_display}`);
  return 0;
}

// 직거래매출 계산 함수  
async function calculateDirectAmount(row, directSales, products, pharmacyMappings) {
  // TODO: 다음 단계에서 구현
  console.log(`  📊 직거래매출 계산: ${row.product_name_display}`);
  return 0;
}

// 라이프사이클
onMounted(async () => {
  await fetchAvailableMonths();
  await fetchCompanies();
  await fetchHospitals();
  
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

// 처방월 변경 핸들러
function onPrescriptionMonthChange(rowIndex) {
  markAsChanged(); // 사용자가 처방월을 변경했을 때
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

// 드롭다운 위치 계산 함수

// 엑셀 템플릿 다운로드
function downloadExcelTemplate() {
  if (!selectedSettlementMonth.value) {
    alert('정산월을 먼저 선택하세요.');
    return;
  }

  try {
    // 템플릿 헤더
    const headers = [
      '업체_사업자등록번호',
      '정산월', 
      '처방월',
      '거래처_사업자등록번호',
      '제품보험코드',
      '처방수량',
      '처방구분',
      '비고'
    ];

    // 처방월 옵션 생성 (선택된 정산월 기준으로)
    const prescriptionMonthSamples = [1, 2, 3].map(offset => 
      getPrescriptionMonth(selectedSettlementMonth.value, offset)
    );

    // 샘플 데이터 (사용자 참고용)
    const sampleData = [
      [
        '123-45-67890',  // 업체_사업자등록번호
        selectedSettlementMonth.value,  // 정산월
        prescriptionMonthSamples[0],    // 처방월 (1개월 전)
        '987-65-43210',  // 거래처_사업자등록번호
        '654321098',     // 제품보험코드
        100,             // 처방수량
        'EDI',           // 처방구분
        '샘플 데이터'     // 비고
      ],
      [
        '111-22-33444',
        selectedSettlementMonth.value,
        prescriptionMonthSamples[1],    // 처방월 (2개월 전)
        '555-66-77888',
        '123456789',
        50,
        '대한조제',
        ''
      ],
      [
        '',  // 빈 행들은 사용자가 입력할 수 있도록
        selectedSettlementMonth.value,
        '',
        '',
        '',
        '',
        'EDI',
        ''
      ]
    ];

    // 설명 및 가이드 추가
    const guideData = [
      ['※ 엑셀 일괄등록 가이드'],
      [''],
      ['1. 업체_사업자등록번호: 등록된 업체의 사업자등록번호를 정확히 입력하세요.'],
      ['2. 정산월: 선택한 정산월과 동일해야 합니다.'],
      [`3. 처방월: ${prescriptionMonthSamples.join(', ')} 중 선택하세요.`],
      ['4. 거래처_사업자등록번호: 등록된 거래처의 사업자등록번호를 정확히 입력하세요.'],
      ['5. 제품보험코드: 등록된 제품의 보험코드를 정확히 입력하세요.'],
      ['6. 처방수량: 숫자로 입력하세요.'],
      [`7. 처방구분: ${prescriptionTypeOptions.value.join(', ')} 중 선택하세요.`],
      ['8. 비고: 필요시 추가 정보를 입력하세요.'],
      [''],
      ['※ 아래 샘플 데이터를 참고하여 데이터를 입력하세요.'],
      ['※ 샘플 데이터는 삭제하고 실제 데이터만 남겨두세요.'],
      ['']
    ];

    // 워크북 생성
    const wb = XLSX.utils.book_new();
    
    // 가이드 시트 생성
    const guideWs = XLSX.utils.aoa_to_sheet(guideData);
    XLSX.utils.book_append_sheet(wb, guideWs, '가이드');

    // 템플릿 시트 생성
    const templateData = [headers, ...sampleData];
    const templateWs = XLSX.utils.aoa_to_sheet(templateData);
    
    // 컬럼 너비 설정
    const colWidths = [
      { wch: 18 },  // 업체_사업자등록번호
      { wch: 12 },  // 정산월
      { wch: 12 },  // 처방월
      { wch: 18 },  // 거래처_사업자등록번호
      { wch: 15 },  // 제품보험코드
      { wch: 12 },  // 처방수량
      { wch: 12 },  // 처방구분
      { wch: 15 }   // 비고
    ];
    templateWs['!cols'] = colWidths;

    // 헤더 스타일 설정 (첫 번째 행)
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
    const fileName = `흡수율분석_일괄등록_템플릿_${selectedSettlementMonth.value}.xlsx`;
    XLSX.writeFile(wb, fileName);

    alert('엑셀 템플릿이 다운로드되었습니다.\n\n가이드 시트를 참고하여 데이터를 입력한 후 일괄등록을 진행하세요.');

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
      alert('변환할 수 있는 유효한 데이터가 없습니다.');
      return;
    }
    
    // 기존 데이터에 추가 (또는 교체)
    if (displayRows.value.length > 0) {
      const answer = confirm(`기존 ${displayRows.value.length}건의 데이터가 있습니다.\n\n[확인]: 기존 데이터에 추가\n[취소]: 기존 데이터 교체`);
      if (!answer) {
        // 기존 데이터 교체
        displayRows.value = parsedData;
      } else {
        // 기존 데이터에 추가
        displayRows.value.push(...parsedData);
      }
    } else {
      displayRows.value = parsedData;
    }

    // 변경사항 표시
    hasUnsavedChanges.value = true;
    hasExistingData.value = false; // 엑셀로 새로 불러온 데이터는 기존 DB 데이터가 아님

    alert(`엑셀 일괄등록 완료!\n\n총 ${parsedData.length}건의 데이터를 불러왔습니다.`);
    
  } catch (err) {
    console.error('엑셀 업로드 오류:', err);
    alert('엑셀 파일 처리 중 오류가 발생했습니다:\n' + err.message);
  } finally {
    // 파일 입력 초기화
    event.target.value = '';
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

// 엑셀 업로드 관련
const excelFileInput = ref(null);

// 엑셀 데이터 파싱 함수
async function parseExcelData(dataRows) {
  const parsedData = [];
  const errors = [];

  for (let i = 0; i < dataRows.length; i++) {
    const row = dataRows[i];
    const rowNum = i + 2; // 엑셀 행 번호 (헤더 포함)

    try {
      // 엑셀 데이터 구조: 업체_사업자등록번호 / 정산월 / 처방월 / 거래처_사업자등록번호 / 제품보험코드 / 처방수량 / 처방구분 / 비고
      const companyBusinessNumber = row[0]?.toString().trim();
      const settlementMonth = row[1]?.toString().trim();
      const prescriptionMonth = row[2]?.toString().trim();
      const clientBusinessNumber = row[3]?.toString().trim();
      const insuranceCode = row[4]?.toString().trim();
      const prescriptionQty = Number(row[5]) || 0;
      const prescriptionType = row[6]?.toString().trim() || 'EDI';
      const remarks = row[7]?.toString().trim() || '';

      // 필수 데이터 검증
      if (!companyBusinessNumber || !settlementMonth || !prescriptionMonth || !clientBusinessNumber || !insuranceCode) {
        errors.push(`${rowNum}행: 필수 데이터가 누락되었습니다.`);
        continue;
      }

      // 정산월 검증
      if (settlementMonth !== selectedSettlementMonth.value) {
        errors.push(`${rowNum}행: 정산월이 선택된 정산월(${selectedSettlementMonth.value})과 다릅니다.`);
        continue;
      }

      // 업체 정보 매칭
      const company = await matchCompanyByBusinessNumber(companyBusinessNumber);
      if (!company) {
        errors.push(`${rowNum}행: 업체를 찾을 수 없습니다. (사업자번호: ${companyBusinessNumber})`);
        continue;
      }

      // 거래처 정보 매칭
      const client = await matchClientByBusinessNumber(clientBusinessNumber);
      if (!client) {
        errors.push(`${rowNum}행: 거래처를 찾을 수 없습니다. (사업자번호: ${clientBusinessNumber})`);
        continue;
      }

      // 제품 정보 매칭
      const product = await matchProductByInsuranceCode(insuranceCode);
      if (!product) {
        errors.push(`${rowNum}행: 제품을 찾을 수 없습니다. (보험코드: ${insuranceCode})`);
        continue;
      }

      // 수수료율 계산
      let commissionRate = 0;
      let paymentAmount = 0;
      
      try {
        if (company.commission_grade && product[`commission_rate_${company.commission_grade}`] !== null) {
          const rate = Number(product[`commission_rate_${company.commission_grade}`]);
          commissionRate = rate * 100;
          paymentAmount = Math.round(prescriptionQty * product.price * rate);
        }
      } catch (err) {
        console.warn(`${rowNum}행: 수수료율 계산 실패`, err);
      }

      // 데이터 객체 생성
      const analysisRow = {
        id: `excel_${Date.now()}_${i}`,
        original_id: null,
        company_id: company.id, // company_id 추가
        company_group: company.company_group || '',
        company_name: company.company_name,
        client_name: client.name,
        prescription_month: prescriptionMonth,
        product_name: product.product_name,
        product_name_display: product.product_name,
        insurance_code: product.insurance_code,
        price: Number(product.price).toLocaleString(),
        prescription_qty: prescriptionQty,
        prescription_amount: (prescriptionQty * product.price).toLocaleString(),
        prescription_type: prescriptionType,
        wholesale_sales: 0,
        direct_sales: 0,
        total_sales: 0,
        absorption_rate: 0,
        commission_rate: commissionRate,
        payment_amount: paymentAmount,
        remarks: remarks,
        orig_created_at: new Date().toISOString(),
        orig_registered_by: '관리자', // 엑셀 일괄등록은 관리자가 등록자
        assigned_pharmacist_contact: company.assigned_pharmacist_contact || ''
      };

      parsedData.push(analysisRow);

    } catch (err) {
      console.error(`${rowNum}행 처리 오류:`, err);
      errors.push(`${rowNum}행: 데이터 처리 중 오류 발생`);
    }
  }

  // 오류 메시지 표시
  if (errors.length > 0) {
    const errorMessage = `다음 오류가 발생했습니다:\n\n${errors.slice(0, 10).join('\n')}${errors.length > 10 ? `\n... 외 ${errors.length - 10}건` : ''}`;
    console.warn('엑셀 파싱 오류:', errors);
    
    if (parsedData.length === 0) {
      alert(errorMessage);
    } else {
      alert(`${errorMessage}\n\n성공적으로 처리된 데이터: ${parsedData.length}건`);
    }
  }

  return parsedData;
}

// 업체 매칭 함수
async function matchCompanyByBusinessNumber(businessNumber) {
  try {
    const { data, error } = await supabase
      .from('companies')
      .select('*')
      .eq('business_registration_number', businessNumber.trim());

    if (error || !data || data.length === 0) {
      console.warn(`업체 매칭 실패: ${businessNumber}`);
      return null;
    }

    console.log(`업체 매칭 성공: ${businessNumber} -> ${data[0].company_name} (총 ${data.length}개 중 첫 번째)`);
    return data[0]; // 여러 개가 있어도 첫 번째 결과 반환
  } catch (err) {
    console.error('업체 매칭 오류:', err);
    return null;
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

