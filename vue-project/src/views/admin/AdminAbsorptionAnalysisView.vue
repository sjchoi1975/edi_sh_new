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
          <select v-model="selectedSettlementMonth" class="select-basic">
            <option v-for="month in availableMonths" :key="month.settlement_month" :value="month.settlement_month">{{ month.settlement_month }}</option>
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
        
        <div style="display: flex; align-items: center; margin-left: auto;">
          <button 
            class="btn-primary" 
            @click="loadAnalysisData" 
            :disabled="loading"
            style="height: 38px;"
          >
            분석 데이터 불러오기
          </button>
        </div>
      </div>
    </div>

    <!-- 데이터 카드 -->
    <div class="data-card" style="flex-grow: 1; display: flex; flex-direction: column; overflow: hidden;">
      <div class="data-card-header" style="flex-shrink: 0;">
        <div class="total-count-display">전체 {{ displayRows.length }} 건</div>
        <div class="data-card-buttons">
           <button class="btn-secondary" @click="downloadExcel" :disabled="displayRows.length === 0">
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
            wrapper: { style: 'min-width: 2200px;' },
            table: { style: 'min-width: 2200px;' }
          }"
        >
          <template #empty>
            <div v-if="loading">데이터를 불러오는 중입니다.</div>
            <div v-else>필터 조건을 선택하고 '분석 데이터 불러오기'를 클릭하세요.</div>
          </template>
          
          <Column field="company_name" header="업체명" :sortable="true" :frozen="true" />
          <Column field="client_name" header="거래처명" :sortable="true" :frozen="true" />
          
          <Column field="prescription_month" header="처방월" :sortable="true" />
          <Column field="product_name_display" header="제품명" :sortable="true" />
          <Column field="insurance_code" header="보험코드" :sortable="true" />
          <Column field="price" header="약가" :sortable="true" />
          <Column field="prescription_qty" header="수량" :sortable="true" />
          <Column field="prescription_amount" header="처방액" :sortable="true" />
          <Column field="prescription_type" header="처방구분" :sortable="true" />
          
          <!-- 신규 추가 컬럼 -->
          <Column field="wholesale_revenue" header="도매매출" :sortable="true">
            <template #body="slotProps">
              {{ slotProps.data.wholesale_revenue.toLocaleString() }}
            </template>
          </Column>
          <Column field="direct_revenue" header="직거래매출" :sortable="true">
             <template #body="slotProps">
              {{ slotProps.data.direct_revenue.toLocaleString() }}
            </template>
          </Column>
          <Column field="total_revenue" header="합산액" :sortable="true">
             <template #body="slotProps">
              {{ slotProps.data.total_revenue.toLocaleString() }}
            </template>
          </Column>
          <Column field="absorption_rate" header="흡수율" :sortable="true">
             <template #body="slotProps">
              {{ slotProps.data.absorption_rate }}%
            </template>
          </Column>

          <Column field="commission_rate" header="수수료율" :sortable="true" />
          <Column field="payment_amount" header="지급액" :sortable="true" />
          <Column field="remarks" header="비고" :sortable="true" />
          <Column field="created_date" header="등록일시" :sortable="true" />
          <Column field="created_by" header="등록자" :sortable="true" />
        </DataTable>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import { supabase } from '@/supabase';

// --- 상태 변수 정의 ---
const loading = ref(false);
const displayRows = ref([]);
const availableMonths = ref([]);
const companyOptions = ref([]);
const hospitalOptions = ref([]);

// 필터 선택값
const selectedSettlementMonth = ref('');
const selectedCompanyId = ref('ALL');
const selectedHospitalId = ref('ALL');

// --- 초기화 및 데이터 로딩 ---
onMounted(async () => {
  await fetchAvailableMonths();
});

async function fetchAvailableMonths() {
  try {
    // 분석 대상은 absorption_analysis 에 있는 정산월만 해당함
    const { data, error } = await supabase
        .from('absorption_analysis')
        .select('settlement_month', { distinct: true })
        .eq('review_status', '완료')
        .order('settlement_month', { ascending: false });

    if (error) throw error;

    availableMonths.value = data;
    if (data.length > 0) {
      selectedSettlementMonth.value = data[0].settlement_month;
      await fetchCompaniesForMonth();
      await fetchClientsForMonth();
    }
  } catch (err) { console.error('정산월 조회 오류:', err); }
}

// 필터 목록을 absorption_analysis 테이블 기준으로 생성
async function fetchCompaniesForMonth() {
  if (!selectedSettlementMonth.value) {
    companyOptions.value = [{ id: 'ALL', company_name: '- 전체 -' }];
    return;
  }
  try {
    const { data, error } = await supabase
      .rpc('get_distinct_companies_from_analysis', { p_settlement_month: selectedSettlementMonth.value });
    
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
        const { data, error } = await supabase
            .rpc('get_distinct_clients_from_analysis', { 
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
    // 데이터를 가져오기 위한 View 또는 RPC를 호출
    // 여기서는 'get_absorption_analysis_details' 라는 RPC를 가정
    const { data, error } = await supabase
      .rpc('get_absorption_analysis_details', {
        p_settlement_month: selectedSettlementMonth.value,
        p_company_id: selectedCompanyId.value === 'ALL' ? null : selectedCompanyId.value,
        p_client_id: selectedHospitalId.value === 'ALL' ? null : selectedHospitalId.value
      });

    if (error) throw error;

    displayRows.value = data.map(row => {
        // 현재는 계산 로직이 없으므로 0으로 설정
        const wholesale_revenue = 0;
        const direct_revenue = 0;
        const total_revenue = 0;
        const absorption_rate = '0.00';

        return {
            ...row, // RPC 결과가 이미 처리된 데이터라고 가정
            price: row.price.toLocaleString(),
            prescription_amount: row.prescription_amount.toLocaleString(),
            commission_rate: `${row.commission_rate}%`, // RPC에서 %가 아닌 소수점으로 준다고 가정
            payment_amount: row.payment_amount.toLocaleString(),
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
  }
});

watch(selectedCompanyId, async () => {
    await fetchClientsForMonth();
});

// --- 유틸리티 함수 ---
function formatDateTime(dateTimeString) {
  if (!dateTimeString) return '-';
  const date = new Date(dateTimeString);
  const kstOffset = 9 * 60 * 60 * 1000;
  const kstDate = new Date(date.getTime() + kstOffset);
  return kstDate.toISOString().slice(0, 16).replace('T', ' ');
}

function downloadExcel() {
  // 엑셀 다운로드 기능 구현 필요
  alert('엑셀 다운로드 기능은 구현 예정입니다.');
}

</script>

<style scoped>
/* 기본 select 스타일 */
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
.absorption-analysis-view { padding: 0px; }
.data-card-buttons { display: flex; gap: 8px; }
</style> 