<template>
  <div class="absorption-analysis-view page-container" style="display: flex; flex-direction: column; height: 100vh;">
    <div class="page-header-title-area" style="flex-shrink: 0;">
      <div class="header-title">흡수율 분석</div>
    </div>

    <!-- 필터 카드 -->
    <div class="filter-card" style="flex-shrink: 0;">
      <div class="filter-row" style="justify-content: flex-start; align-items: flex-end; gap: 16px; flex-wrap: wrap;">
        
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
          <label>거래처</label>
          <select v-model="selectedHospitalId" class="select_200px">
            <option v-for="hospital in hospitalOptions" :key="hospital.id" :value="hospital.id">{{ hospital.name }}</option>
          </select>
        </div>
        
        <div style="display: flex; align-items: center; margin-left: auto;">
          <button 
            class="btn-primary" 
            @click="loadAnalysisData" 
            :disabled="loading"
          >
            검수 완료 불러오기
          </button>
        </div>
      </div>
    </div>

    <!-- 데이터 카드 -->
    <div class="data-card" style="flex-grow: 1; display: flex; flex-direction: column; overflow: hidden;">
      <div class="data-card-header" style="flex-shrink: 0;">
        <div class="total-count-display">전체 {{ displayRows.length }} 건</div>
        <div class="data-card-buttons">
           <button class="btn-add" @click="calculateAbsorptionRates" :disabled="displayRows.length === 0">
             흡수율 분석
           </button>
           <button class="btn-excell-download" @click="downloadExcel" :disabled="displayRows.length === 0">
             엑셀 다운로드
           </button>
        </div>
      </div>
      
      <div style="flex-grow: 1; overflow: hidden;">
        <DataTable 
          :value="displayRows" 
          :loading="loading"
          scrollable 
          scrollHeight="calc(100vh - 220px)"
          class="absorption-analysis-table"
          :pt="{
            wrapper: { style: 'min-width: 2400px;' },
            table: { style: 'min-width: 2400px;' }
          }"
        >
          <template #empty>
            <div v-if="loading">데이터를 불러오는 중입니다.</div>
            <div v-else>필터 조건을 선택하고 '검수 완료 불러오기'를 클릭하세요.</div>
          </template>
          
          <Column header="작업" field="review_action" :headerStyle="{ width: columnWidths.review_action }" :frozen="true">
            <template #body="slotProps">
              <Tag v-if="slotProps.data.review_action" :value="slotProps.data.review_action" :severity="getActionSeverity(slotProps.data.review_action)"/>
            </template>
          </Column>

          <Column field="company_name" header="업체명" :headerStyle="{ width: columnWidths.company_name }" :sortable="true" :frozen="true" />
          <Column field="client_name" header="거래처명" :headerStyle="{ width: columnWidths.client_name }" :sortable="true" :frozen="true" />
          
          <Column field="prescription_month" header="처방월" :headerStyle="{ width: columnWidths.prescription_month }" :sortable="true" />
          <Column field="product_name_display" header="제품명" :headerStyle="{ width: columnWidths.product_name_display }" :sortable="true" :frozen="true" />
          <Column field="insurance_code" header="보험코드" :headerStyle="{ width: columnWidths.insurance_code }" :sortable="true" />
          <Column field="price" header="약가" :headerStyle="{ width: columnWidths.price }" :sortable="true" />
          <Column field="prescription_qty" header="수량" :headerStyle="{ width: columnWidths.prescription_qty }" :sortable="true" />
          <Column field="prescription_amount" header="처방액" :headerStyle="{ width: columnWidths.prescription_amount }" :sortable="true" />
          <Column field="prescription_type" header="처방구분" :headerStyle="{ width: columnWidths.prescription_type }" :sortable="true" />
          
          <Column field="wholesale_revenue" header="도매매출" :headerStyle="{ width: columnWidths.wholesale_revenue }" :sortable="true">
            <template #body="slotProps">
              {{ slotProps.data.wholesale_revenue.toLocaleString() }}
            </template>
          </Column>
          <Column field="direct_revenue" header="직거래매출" :headerStyle="{ width: columnWidths.direct_revenue }" :sortable="true">
             <template #body="slotProps">
              {{ slotProps.data.direct_revenue.toLocaleString() }}
            </template>
          </Column>
          <Column field="total_revenue" header="합산액" :headerStyle="{ width: columnWidths.total_revenue }" :sortable="true">
             <template #body="slotProps">
              {{ slotProps.data.total_revenue.toLocaleString() }}
            </template>
          </Column>
          <Column field="absorption_rate" header="흡수율" :headerStyle="{ width: columnWidths.absorption_rate }" :sortable="true">
             <template #body="slotProps">
              {{ slotProps.data.absorption_rate }}%
            </template>
          </Column>

          <Column field="commission_rate" header="수수료율" :headerStyle="{ width: columnWidths.commission_rate }" :sortable="true" />
          <Column field="payment_amount" header="지급액" :headerStyle="{ width: columnWidths.payment_amount }" :sortable="true" />
          <Column field="remarks" header="비고" :headerStyle="{ width: columnWidths.remarks }" :sortable="true" />
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
import Tag from 'primevue/tag';
import { supabase } from '@/supabase';
import * as XLSX from 'xlsx';

const columnWidths = {
  review_action: '4%',
  company_name: '10%',
  client_name: '12%',
  prescription_month: '5%',
  product_name_display: '14%',
  insurance_code: '6%',
  price: '5%',
  prescription_qty: '5%',
  prescription_amount: '6%',
  prescription_type: '6%',
  wholesale_revenue: '6%',
  direct_revenue: '6%',
  total_revenue: '7%',
  absorption_rate: '6%',
  commission_rate: '6%',
  payment_amount: '6%',
  remarks: '10%',
  created_date: '9%',
  created_by: '10%'
};

// --- 상태 변수 정의 ---
const loading = ref(false);
const displayRows = ref([]);
const availableMonths = ref([]);
const companyOptions = ref([]);
const hospitalOptions = ref([]);
const prescriptionOptions = ref([]);

// 필터 선택값
const selectedSettlementMonth = ref('');
const selectedCompanyId = ref('ALL');
const selectedHospitalId = ref('ALL');
const prescriptionOffset = ref(0);

// --- 초기화 및 데이터 로딩 ---
onMounted(async () => {
  await fetchAvailableMonths();
});

async function fetchAvailableMonths() {
  try {
    const { data, error } = await supabase.rpc('get_distinct_settlement_months_from_analysis');
    if (error) throw error;
    
    data.sort((a, b) => b.settlement_month.localeCompare(a.settlement_month));
    availableMonths.value = data;

    if (data.length > 0) {
      selectedSettlementMonth.value = data[0].settlement_month;
      await fetchCompaniesForMonth();
      await fetchClientsForMonth();
      updatePrescriptionOptions();
    }
  } catch (err) { console.error('정산월 조회 오류:', err); }
}

async function fetchCompaniesForMonth() {
  if (!selectedSettlementMonth.value) {
    companyOptions.value = [{ id: 'ALL', company_name: '- 전체 -' }];
    return;
  }
  try {
    const { data, error } = await supabase.rpc('get_distinct_companies_from_analysis', { p_settlement_month: selectedSettlementMonth.value });
    if (error) throw error;
    
    const sortedCompanies = data.sort((a, b) => a.company_name.localeCompare(b.company_name));
    companyOptions.value = [{ id: 'ALL', company_name: '- 전체 -' }, ...sortedCompanies];
    selectedCompanyId.value = 'ALL';
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
        const { data, error } = await supabase.rpc('get_distinct_clients_from_analysis', { 
            p_settlement_month: selectedSettlementMonth.value,
            p_company_id: selectedCompanyId.value === 'ALL' ? null : selectedCompanyId.value
        });
        if (error) throw error;

        const sortedClients = data.sort((a, b) => a.name.localeCompare(b.name));
        hospitalOptions.value = [{ id: 'ALL', name: '- 전체 -' }, ...sortedClients];
        selectedHospitalId.value = 'ALL';
    } catch (err) {
        console.error('해당 월의 거래처 조회 오류:', err);
        hospitalOptions.value = [{ id: 'ALL', name: '- 전체 -' }];
    }
}

// --- 핵심 데이터 처리 함수 ---
async function loadAnalysisData() {
  if (!selectedSettlementMonth.value) { alert('정산월을 선택해야 합니다.'); return; }
  
  loading.value = true;
  displayRows.value = [];
  
  try {
    let query = supabase
      .from('v_review_details')
      .select('*')
      .eq('settlement_month', selectedSettlementMonth.value)
      .eq('review_status', '완료');
    
    if (selectedCompanyId.value !== 'ALL') {
      query = query.eq('company_id', selectedCompanyId.value);
    }
    if (selectedHospitalId.value !== 'ALL') {
      query = query.eq('client_id', selectedHospitalId.value);
    }
    
    if (prescriptionOffset.value !== 0) {
      const prescriptionMonth = getPrescriptionMonth(selectedSettlementMonth.value, prescriptionOffset.value);
      query = query.eq('prescription_month', prescriptionMonth);
    }

    const { data, error } = await query;
    if (error) throw error;

    displayRows.value = data.map(row => {
        const wholesale_revenue = 0;
        const direct_revenue = 0;
        const total_revenue = 0;
        const absorption_rate = '0.00';

        return {
            ...row,
            price: row.price?.toLocaleString() || 0,
            prescription_amount: row.prescription_amount?.toLocaleString() || 0,
            commission_rate: `${(row.commission_rate * 100).toFixed(1)}%`,
            payment_amount: Math.round(row.prescription_amount * row.commission_rate).toLocaleString(),
            created_date: formatDateTime(row.created_at),
            wholesale_revenue,
            direct_revenue,
            total_revenue,
            absorption_rate
        };
    });

  } catch (err) {
    console.error('분석 데이터 처리 오류:', err);
    alert(`분석 데이터 처리 중 오류가 발생했습니다: ${err.message}`);
  } finally {
    loading.value = false;
  }
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

// --- 유틸리티 함수 ---
async function calculateAbsorptionRates() {
  if (!selectedSettlementMonth.value) {
    alert('정산월을 선택해주세요.');
    return;
  }
  loading.value = true;
  try {
    const { data: analysisResults, error } = await supabase.rpc('calculate_absorption_rates', {
      p_settlement_month: selectedSettlementMonth.value
    });

    if (error) throw error;

    const resultsMap = new Map(analysisResults.map(r => [r.analysis_id, r]));

    displayRows.value.forEach(row => {
      const result = resultsMap.get(row.id);
      if (result) {
        row.wholesale_revenue = result.wholesale_revenue || 0;
        row.direct_revenue = result.direct_revenue || 0;
        row.total_revenue = row.wholesale_revenue + row.direct_revenue;
        
        const prescriptionAmount = Number(String(row.prescription_amount).replace(/,/g, '')) || 0;
        if (prescriptionAmount > 0) {
          row.absorption_rate = ((row.total_revenue / prescriptionAmount) * 100).toFixed(1);
        } else {
          row.absorption_rate = '0.0';
        }
      }
    });

    alert('흡수율 분석이 완료되었습니다.');
  } catch (err) {
    console.error('흡수율 분석 오류:', err);
    alert(`흡수율 분석 중 오류가 발생했습니다: ${err.message}`);
  } finally {
    loading.value = false;
  }
}

function getPrescriptionMonth(settlementMonth, offset) {
  if (!settlementMonth || offset === null) return '';
  const [y, m] = settlementMonth.split('-');
  let month = parseInt(m, 10) - offset;
  let year = parseInt(y, 10);
  while (month <= 0) { month += 12; year -= 1; }
  return `${year}-${String(month).padStart(2, '0')}`;
}

function updatePrescriptionOptions() {
  prescriptionOptions.value = [
    { value: 0, month: '- 전체 -' },
    ...[1, 2, 3].map(offset => ({
      value: offset,
      month: getPrescriptionMonth(selectedSettlementMonth.value, offset)
    }))
  ];
}

function getActionSeverity(action) {
  if (action === '수정') return 'info';
  if (action === '추가') return 'success';
  if (action === '삭제') return 'danger';
  return 'secondary';
}

function formatDateTime(dateTimeString) {
  if (!dateTimeString) return '-';
  const date = new Date(dateTimeString);
  const kstOffset = 9 * 60 * 60 * 1000;
  const kstDate = new Date(date.getTime() + kstOffset);
  return kstDate.toISOString().slice(0, 16).replace('T', ' ');
}

function downloadExcel() {
  if (displayRows.value.length === 0) {
    alert('다운로드할 데이터가 없습니다.');
    return;
  }

  // 1. 데이터 준비 (엑셀 서식을 위해 숫자/날짜 타입으로 변환)
  const dataToExport = displayRows.value.map(row => ({
    '작업': row.review_action || '-',
    '업체명': row.company_name,
    '거래처명': row.client_name,
    '처방월': row.prescription_month,
    '제품명': row.product_name_display,
    '보험코드': row.insurance_code,
    '약가': Number(String(row.price).replace(/,/g, '')),
    '수량': row.prescription_qty,
    '처방액': Number(String(row.prescription_amount).replace(/,/g, '')),
    '처방구분': row.prescription_type,
    '도매매출': row.wholesale_revenue,
    '직거래매출': row.direct_revenue,
    '합산액': row.total_revenue,
    '흡수율(%)': Number(row.absorption_rate) / 100, // 백분율로 표시하기 위해 100으로 나눔
    '수수료율(%)': Number(String(row.commission_rate).replace('%', '')) / 100,
    '지급액': Number(String(row.payment_amount).replace(/,/g, '')),
    '비고': row.remarks,
    '최초등록일시': new Date(row.created_at), // Date 객체로 변환
    '등록자': row.created_by,
  }));

  // 2. 워크북 및 워크시트 생성
  const worksheet = XLSX.utils.json_to_sheet(dataToExport);

  // 3. 셀 서식 지정
  const range = XLSX.utils.decode_range(worksheet['!ref']);
  for (let R = range.s.r + 1; R <= range.e.r; ++R) {
    const numberFormat = '#,##0';
    const percentFormat = '0%';
    
    // G: 약가
    worksheet[XLSX.utils.encode_cell({c: 6, r: R})].z = numberFormat;
    // H: 수량
    worksheet[XLSX.utils.encode_cell({c: 7, r: R})].z = numberFormat;
    // I: 처방액
    worksheet[XLSX.utils.encode_cell({c: 8, r: R})].z = numberFormat;
    // K: 도매매출
    worksheet[XLSX.utils.encode_cell({c: 10, r: R})].z = numberFormat;
    // L: 직거래매출
    worksheet[XLSX.utils.encode_cell({c: 11, r: R})].z = numberFormat;
    // M: 합산액
    worksheet[XLSX.utils.encode_cell({c: 12, r: R})].z = numberFormat;
    // N: 흡수율(%)
    worksheet[XLSX.utils.encode_cell({c: 13, r: R})].z = '0.00%';
    // O: 수수료율(%)
    worksheet[XLSX.utils.encode_cell({c: 14, r: R})].z = percentFormat;
    // P: 지급액
    worksheet[XLSX.utils.encode_cell({c: 15, r: R})].z = '#,##0.0';
    // R: 최초등록일시
    worksheet[XLSX.utils.encode_cell({c: 17, r: R})].z = 'yyyy-mm-dd hh:mm';
  }

  // 4. 워크북 생성 및 파일 다운로드
  const workbook = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(workbook, worksheet, '흡수율 분석');
  XLSX.writeFile(workbook, '흡수율_분석_데이터.xlsx');
}

</script>

<style scoped>

.absorption-analysis-view { padding: 0px; }
.data-card-buttons { display: flex; gap: 8px; }

/* 셀 배경색을 흰색으로 지정 */
:deep(.p-datatable-tbody > tr > td) {
  background: #ffffff !important;
}
</style> 