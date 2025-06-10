<template>
  <div class="performance-review-view page-container" style="display: flex; flex-direction: column; height: 100vh;">
    <div class="page-header-title-area" style="flex-shrink: 0;">
      <div class="header-title">실적 검수</div>
    </div>

    <!-- 필터 카드: 정산월, 처방월, 업체, 거래처 드롭다운 -->
    <div class="filter-card" style="flex-shrink: 0;">
      <div class="filter-row" style="justify-content: flex-start; align-items: flex-end;">
        <div style="display: flex; align-items: center; gap: 8px;">
          <label style="font-weight:400;">정산월</label>
          <select v-model="selectedSettlementMonth" class="select_month">
            <option v-for="month in availableMonths" :key="month.settlement_month" :value="month.settlement_month">{{ month.settlement_month }}</option>
          </select>
        </div>
        <div style="display: flex; align-items: center; gap: 8px;">
          <label style="font-weight:400;">처방월</label>
          <select v-model="prescriptionOffset" class="select_month">
            <option v-for="opt in prescriptionOptions" :key="opt.value" :value="opt.value">{{ opt.month }}</option>
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
        <div style="display: flex; align-items: center; gap: 16px; margin-left: 20px;">
          <button 
            class="btn-primary" 
            @click="loadPerformanceData" 
            :disabled="!selectedSettlementMonth || loading"
          >
            실적 정보 불러오기
          </button>
        </div>
      </div>
    </div>

    <!-- 데이터 카드: 전체 n건 + 테이블 + 합계 행 -->
    <div class="data-card" style="flex-grow: 1; display: flex; flex-direction: column; overflow: hidden;">

      <!-- 목록 필터링 영역 -->
      <div class="list-filter-area" style="flex-shrink: 0; background: none; padding: 0 0.75rem; border: none; border-radius: 4px; margin-bottom: 16px;">
        <div style="display: flex; align-items: center; gap: 16px; flex-wrap: wrap;">
          <div style="display: flex; align-items: center; gap: 8px;">
            <label style="font-weight: 500; min-width: 48px;">조건 검색</label>
          </div>
          <div style="display: flex; align-items: center; gap: 8px;">
            <label style="font-weight: 400; min-width: 32px;">업체</label>
            <select v-model="listFilterCompany" class="select_200px">
              <option value="">- 전체 -</option>
              <option v-for="company in uniqueCompaniesInList" :key="company" :value="company">{{ company }}</option>
            </select>
          </div>
          <div style="display: flex; align-items: center; gap: 8px;">
            <label style="font-weight: 400; min-width: 40px;">거래처</label>
            <select v-model="listFilterClient" class="select_240px">
              <option value="">- 전체 -</option>
              <option v-for="client in uniqueClientsInList" :key="client" :value="client">{{ client }}</option>
            </select>
          </div>
          <div style="display: flex; align-items: center; gap: 8px;">
            <label style="font-weight: 400; min-width: 32px;">제품</label>
            <select v-model="listFilterProduct" class="select_240px">
              <option value="">- 전체 -</option>
              <option v-for="product in uniqueProductsInList" :key="product" :value="product">{{ product }}</option>
            </select>
          </div>
          <div style="display: flex; align-items: center; gap: 8px;">
            <label style="font-weight: 400; min-width: 32px;">상태</label>
            <select v-model="listFilterStatus" class="select_120px">
              <option value="">- 전체 -</option>
              <option value="완료">완료</option>
              <option value="검수중">검수중</option>
            </select>
          </div>
          <div style="display: flex; align-items: center; gap: 8px;">
            <button class="btn-secondary-small" @click="clearListFilters">초기화</button>
          </div>
        </div>
      </div>

      <div class="data-card-header" style="flex-shrink: 0;">
        <div class="total-count-display">전체 {{ filteredRows.length }} 건 (원본: {{ displayRows.length }} 건)</div>
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
          :value="filteredRows" 
          :loading="loading"
          scrollable 
          scrollHeight="calc(100vh - 280px)"
          scrollDirection="both"
          class="admin-performance-review-table"
          :pt="{
            wrapper: { style: 'min-width: 2600px;' },
            table: { style: 'min-width: 2600px;' }
          }"
          editMode="cell"
          @cell-edit-complete="onCellEditComplete"
          :rowClass="getRowClass"
        >
          <template #empty>
            <div v-if="loading">검수중인 데이터를 불러오는 중입니다.</div>
            <div v-else>등록된 실적이 없습니다.</div>
          </template>
          
          <!-- 체크박스 컬럼 -->
          <Column header="선택" :headerStyle="{ width: columnWidths.checkbox }" :frozen="true">
            <template #header>
              <Checkbox 
                v-model="selectAllChecked" 
                @change="toggleSelectAll"
                :binary="true"
              />
            </template>
            <template #body="slotProps">
              <Checkbox 
                :modelValue="!!selectedRowsMap[slotProps.data.id]" 
                @update:modelValue="(value) => onRowSelectChange(slotProps.data, value)"
                :binary="true"
                :disabled="slotProps.data.review_action === '제외' || slotProps.data.review_status === '완료'"
              />
            </template>
          </Column>

          <!-- 검수 상태 컬럼 -->
          <Column header="상태" :headerStyle="{ width: columnWidths.review_status }" :frozen="true">
            <template #body="slotProps">
              <Tag 
                :value="slotProps.data.review_status" 
                :severity="slotProps.data.review_status === '완료' ? 'success' : 'warning'"
              />
            </template>
          </Column>

          <!-- 검수구분 컬럼 -->
          <Column header="작업" :headerStyle="{ width: columnWidths.review_action }" :frozen="true">
            <template #body="slotProps">
              <Tag 
                v-if="slotProps.data.review_action"
                :value="slotProps.data.review_action"
                :severity="getActionSeverity(slotProps.data.review_action)"
              />
            </template>
          </Column>

          <!-- 액션 컬럼 -->
          <Column header="액션" :headerStyle="{ width: columnWidths.actions }" :frozen="true">
            <template #body="slotProps">
              <div style="display: flex; gap: 4px; justify-content: center;">
                <template v-if="slotProps.data.isEditing">
                  <button class="btn-save-sm" @click="saveEdit(slotProps.data)" title="저장">✓</button>
                  <button class="btn-cancel-sm" @click="cancelEdit(slotProps.data)" title="취소">✕</button>
                </template>
                <template v-else-if="slotProps.data.review_action === '삭제'">
                  <!-- 삭제된 행에서는 되돌리기 버튼만 표시 -->
                  <button 
                    class="btn-restore-sm" 
                    @click="restoreRow(slotProps.data)" 
                    title="되돌리기">↶</button>
                </template>
                <template v-else>
                  <!-- 일반 행에서는 수정/삭제/추가 버튼 표시 -->
                  <button class="btn-edit-sm" @click="startEdit(slotProps.data)" title="수정">✎</button>
                  <button 
                    class="btn-delete-sm" 
                    @click="confirmDeleteRow(slotProps.index)" 
                    title="삭제">－</button>
                  <button class="btn-add-sm" @click="addRowBelow(slotProps.index)" title="추가">＋</button>
                </template>
              </div>
            </template>
          </Column>          

          <Column header="No" :headerStyle="{ width: columnWidths.no }" :frozen="true">
            <template #body="slotProps">
              {{ slotProps.index + 1 }}
            </template>
          </Column>
          
          <Column field="company_group" header="구분" :headerStyle="{ width: columnWidths.company_group }" :sortable="true"/>
          
          <!-- 업체명 -->
          <Column field="company_name" header="업체명" :headerStyle="{ width: columnWidths.company_name }" :sortable="true">
            <template #body="slotProps">
              <span style="font-weight: 400;">{{ slotProps.data.company_name }}</span>
            </template>
          </Column>
          
          <!-- 거래처명 - 항상 읽기전용(수정 불가) -->
          <Column field="client_name" header="거래처명" :headerStyle="{ width: columnWidths.client_name }" :sortable="true">
            <template #body="slotProps">
              <span style="font-weight: 400;">{{ slotProps.data.client_name }}</span>
            </template>
          </Column>
          
          <!-- 처방월(수정) - 편집 가능 -->
          <Column field="prescription_month_modify" header="처방월" :headerStyle="{ width: columnWidths.prescription_month, textAlign: 'center' }" :sortable="true">
            <template #body="slotProps">
              <template v-if="slotProps.data.isEditing">
                <select v-model="slotProps.data.prescription_month_modify" class="select_month edit-mode-input" style="width: 100%; text-align: center !important;">
                  <option value="">- 선택 -</option>
                  <option v-for="month in availableMonths" :key="month.settlement_month" :value="month.settlement_month">
                    {{ month.settlement_month }}
                  </option>
                </select>
              </template>
              <template v-else>
                <span style="font-weight: 400;">
                  {{ slotProps.data.prescription_month_modify || slotProps.data.prescription_month }}
                </span>
              </template>
            </template>
          </Column>
          
          <!-- 제품명 - 편집 가능 -->
          <Column field="product_name_display" header="제품명" :headerStyle="{ width: columnWidths.product_name_display, textAlign: 'left' }" :sortable="true">
            <template #body="slotProps">
              <template v-if="slotProps.data.isEditing">
                <select v-model="slotProps.data.product_name_display" class="select_month edit-mode-input" style="width: 100%; text-align: left !important; padding-left: 4px !important;" @change="onProductChange(slotProps.data, $event.target.value)">
                  <option value="">- 제품 선택 -</option>
                  <option v-for="product in uniqueProducts" :key="product.id" :value="product.product_name">
                    {{ product.product_name }}
                  </option>
                </select>
              </template>
              <template v-else>
                <span style="font-weight: 400;">{{ slotProps.data.product_name_display }}</span>
              </template>
            </template>
          </Column>
          
          <Column field="insurance_code" header="보험코드" :headerStyle="{ width: columnWidths.insurance_code }" :sortable="true"/>
          <Column field="price" header="약가" :headerStyle="{ width: columnWidths.price }" :sortable="true"/>
          
          <!-- 처방수량 - 편집 가능 -->
          <Column field="prescription_qty" header="수량" :headerStyle="{ width: columnWidths.prescription_qty, textAlign: 'right' }" :sortable="true">
            <template #body="slotProps">
              <template v-if="slotProps.data.isEditing">
                <div style="width: 100%; text-align: right;">
                  <InputNumber v-model="slotProps.data.prescription_qty" :min="0" class="edit-mode-input" style="width: 100%;" :inputStyle="{ textAlign: 'right', paddingRight: '4px' }" @change="onCellEditComplete({ data: slotProps.data, field: 'prescription_qty' })" />
                </div>
              </template>
              <template v-else>
                <span style="font-weight: 400; text-align: right; display: block;">{{ slotProps.data.prescription_qty }}</span>
              </template>
            </template>
          </Column>
          
          <Column field="prescription_amount" header="처방액" :headerStyle="{ width: columnWidths.prescription_amount }" :sortable="true"/>
          
          <!-- 처방구분 - 편집 가능 -->
          <Column field="prescription_type" header="처방구분" :headerStyle="{ width: columnWidths.prescription_type, textAlign: 'center' }" :sortable="true">
            <template #body="slotProps">
              <template v-if="slotProps.data.isEditing">
                <select v-model="slotProps.data.prescription_type" class="select_month edit-mode-input" style="width: 100%; text-align: center !important;" @change="onCellEditComplete({ data: slotProps.data, field: 'prescription_type' })">
                  <option value="">- 처방구분 선택 -</option>
                  <option v-for="type in prescriptionTypes" :key="type" :value="type">
                    {{ type }}
                  </option>
                </select>
              </template>
              <template v-else>
                <span style="font-weight: 400;">{{ slotProps.data.prescription_type }}</span>
              </template>
            </template>
          </Column>
          
          <!-- 수수료율 - 편집 가능 -->
          <Column field="commission_rate" header="수수료율" :headerStyle="{ width: columnWidths.commission_rate, textAlign: 'center' }" :sortable="true">
            <template #body="slotProps">
              <template v-if="slotProps.data.isEditing">
                <div style="width: 100%; text-align: center;">
                  <InputNumber v-model="slotProps.data.commission_rate_modify" :min="0" :max="100" suffix="%" class="edit-mode-input" style="width: 100%;" :inputStyle="{ textAlign: 'center' }" @change="onCellEditComplete({ data: slotProps.data, field: 'commission_rate_modify' })" />
                </div>
              </template>
              <template v-else>
                <span style="font-weight: 400;">{{ getCommissionRate(slotProps.data) }}%</span>
              </template>
            </template>
          </Column>
          
          <Column field="payment_amount" header="지급액" :headerStyle="{ width: columnWidths.payment_amount }" :sortable="true"/>
          
          <!-- 비고 - 편집 가능 -->
          <Column field="remarks" header="비고" :headerStyle="{ width: columnWidths.remarks, textAlign: 'left' }" :sortable="true">
            <template #body="slotProps">
              <template v-if="slotProps.data.isEditing">
                <InputText v-model="slotProps.data.remarks" class="edit-mode-input" style="width: 100%;" :inputStyle="{ textAlign: 'left', paddingLeft: '4px' }" @change="onCellEditComplete({ data: slotProps.data, field: 'remarks' })" />
              </template>
              <template v-else>
                <span style="font-weight: 400;">{{ slotProps.data.remarks }}</span>
              </template>
            </template>
          </Column>
          <Column field="created_date" header="등록일시" :headerStyle="{ width: columnWidths.created_date }" :sortable="true"/>
          <Column field="created_by" header="등록자" :headerStyle="{ width: columnWidths.created_by }" :sortable="true"/>
        </DataTable>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Checkbox from 'primevue/checkbox';
import Tag from 'primevue/tag';
import Button from 'primevue/button';
import Dropdown from 'primevue/dropdown';
import InputNumber from 'primevue/inputnumber';
import InputText from 'primevue/inputtext';
import { supabase } from '@/supabase';

// 컬럼 너비 설정
const columnWidths = {
  checkbox: '3%',
  review_status: '4%',
  review_action: '4%',
  actions: '6%',
  no: '3%',
  company_group: '6%',
  company_name: '10%',
  client_name: '14%',
  prescription_month: '5%',
  product_name_display: '12%',
  insurance_code: '6%',
  price: '4%',
  prescription_qty: '4%',
  prescription_amount: '5%',
  prescription_type: '5%',
  commission_rate: '5%',
  payment_amount: '5%',
  remarks: '13%',
  created_date: '7%',
  created_by: '8%'
};

// 반응형 데이터
const availableMonths = ref([]);
const selectedSettlementMonth = ref('');
const selectedMonthInfo = ref(null);
const prescriptionMonth = ref('');
const prescriptionOffset = ref(0);
const prescriptionOptions = ref([]);
const loading = ref(false);

// 업체 관련
const selectedCompanyId = ref('');
const companies = ref([]);
const allCompanies = ref([]); // 편집용 전체 업체 목록

// 거래처 관련
const selectedHospitalId = ref('');
const hospitals = ref([]);
const allClients = ref([]); // 편집용 전체 거래처 목록

// 제품 관련
const allProducts = ref([]); // 편집용 전체 제품 목록

// 실적 데이터
const displayRows = ref([]);

// 목록 필터링 관련
const listFilterCompany = ref('');
const listFilterClient = ref('');
const listFilterProduct = ref('');
const listFilterStatus = ref('');

// 체크박스 관련
const selectedRows = ref([]);
const selectedRowsMap = ref({});
const selectAllChecked = ref(false);

// 편집용 옵션들
const prescriptionTypes = ref(['EDI', '대한조제', '의료매출', '직거래매입', '차감', '원내매출', '원외매출']);

// 추가: performance_records 전체 불러오기
const allPerformanceRecords = ref([]);
async function fetchAllPerformanceRecords() {
  const { data, error } = await supabase.from('performance_records').select('*');
  if (!error && data) allPerformanceRecords.value = data;
}

// Computed 속성들
// 필터링된 목록
const filteredRows = computed(() => {
  let filtered = [...displayRows.value];
  
  if (listFilterCompany.value) {
    filtered = filtered.filter(row => row.company_name === listFilterCompany.value);
  }
  
  if (listFilterClient.value) {
    filtered = filtered.filter(row => row.client_name === listFilterClient.value);
  }
  
  if (listFilterProduct.value) {
    filtered = filtered.filter(row => row.product_name_display === listFilterProduct.value);
  }
  
  if (listFilterStatus.value) {
    filtered = filtered.filter(row => row.review_status === listFilterStatus.value);
  }
  
  return filtered;
});

// 목록에 있는 고유한 업체명들
const uniqueCompaniesInList = computed(() => {
  const companies = [...new Set(displayRows.value.map(row => row.company_name).filter(name => name))];
  return companies.sort();
});

// 목록에 있는 고유한 거래처명들
const uniqueClientsInList = computed(() => {
  const clients = [...new Set(displayRows.value.map(row => row.client_name).filter(name => name))];
  return clients.sort();
});

// 목록에 있는 고유한 제품명들
const uniqueProductsInList = computed(() => {
  const products = [...new Set(displayRows.value.map(row => row.product_name_display).filter(name => name))];
  return products.sort();
});

// 제품 목록 중복 제거 (같은 보험코드는 한 번만)
const uniqueProducts = computed(() => {
  const seen = new Set();
  return allProducts.value.filter(product => {
    if (seen.has(product.insurance_code)) {
      return false;
    }
    seen.add(product.insurance_code);
    return true;
  });
});

// 유틸리티 함수들
function getPrescriptionMonth(settlementMonth, offset) {
  if (!settlementMonth) return '';
  const [y, m] = settlementMonth.split('-');
  let mm = parseInt(m, 10) - offset;
  let yy = parseInt(y, 10);
  while (mm <= 0) { mm += 12; yy -= 1; }
  return `${yy}-${String(mm).padStart(2, '0')}`;
}

function updatePrescriptionOptions() {
  if (!selectedMonthInfo.value) {
    prescriptionOptions.value = [];
    return;
  }
  
  prescriptionOptions.value = [
    { value: 0, month: '- 전체 -' },
    ...([1, 2, 3].map(offset => ({
      value: offset,
      month: getPrescriptionMonth(selectedMonthInfo.value.settlement_month, offset)
    })))
  ];
}

function getActionSeverity(action) {
  switch (action) {
    case '수정': return 'info';
    case '제외': return 'danger';
    default: return 'secondary';
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

// 워치어
watch(selectedSettlementMonth, () => {
  const monthInfo = availableMonths.value.find(m => m.settlement_month === selectedSettlementMonth.value);
  selectedMonthInfo.value = monthInfo || null;
  updatePrescriptionOptions();
  prescriptionOffset.value = 0;
  prescriptionMonth.value = '';
  
  selectedCompanyId.value = '';
  selectedHospitalId.value = '';
  
  if (selectedSettlementMonth.value) {
    fetchCompanies();
    fetchHospitals();
  } else {
    companies.value = [];
    hospitals.value = [];
    displayRows.value = [];
  }
});

watch(prescriptionOffset, (val) => {
  if (val === 0) {
    prescriptionMonth.value = '';
  } else {
    prescriptionMonth.value = getPrescriptionMonth(selectedSettlementMonth.value, val);
  }
  
  selectedCompanyId.value = '';
  selectedHospitalId.value = '';
  
  if (selectedSettlementMonth.value) {
    fetchCompanies();
    fetchHospitals();
  }
});

watch(selectedCompanyId, () => {
  selectedHospitalId.value = '';
  
  if (selectedSettlementMonth.value) {
    fetchHospitals();
  }
});

// selectedHospitalId 변경 시에는 fetchPerformanceRecords를 자동 호출하지 않음

// 목록 필터 변경 시 체크박스 상태 업데이트
watch([listFilterCompany, listFilterClient, listFilterProduct, listFilterStatus], () => {
  updateSelectAllState();
});

// 전체 데이터 로드 함수들 (편집용)
async function fetchAllCompanies() {
  const { data, error } = await supabase.from('companies').select('*');
  if (!error && data) allCompanies.value = data;
}

async function fetchAllClients() {
  const { data, error } = await supabase.from('clients').select('*');
  if (!error && data) allClients.value = data;
}

async function fetchAllProducts() {
  const { data, error } = await supabase.from('products').select('*');
  if (!error && data) allProducts.value = data;
}

// 데이터 fetch 함수들
async function fetchAvailableMonths() {
  try {
    const { data, error } = await supabase
      .from('settlement_months')
      .select('settlement_month, start_date, end_date')
      .order('settlement_month', { ascending: false });
    if (!error && data) {
      availableMonths.value = data;
      if (data.length > 0 && !selectedSettlementMonth.value) {
        selectedSettlementMonth.value = data[0].settlement_month;
      }
    }
  } catch (err) {
    console.error('정산월 조회 오류:', err);
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
      .select(`
        company_id,
        companies!inner(*)
      `)
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
      if (!companyIds.has(record.company_id)) {
        companyIds.add(record.company_id);
        uniqueCompanies.push({
          id: record.companies.id,
          company_name: record.companies.company_name,
          company_group: record.companies.company_group,
          assigned_pharmacist_contact: record.companies.assigned_pharmacist_contact
        });
      }
    });
    
    companies.value = uniqueCompanies.sort((a, b) => a.company_name.localeCompare(b.company_name));
  } catch (err) {
    console.error('업체 조회 예외:', err);
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
      .select(`
        client_id,
        clients!inner(*)
      `)
      .eq('settlement_month', selectedSettlementMonth.value);
    
    if (prescriptionOffset.value !== 0) {
      query = query.eq('prescription_month', prescriptionMonth.value);
    }
    
    if (selectedCompanyId.value) {
      query = query.eq('company_id', selectedCompanyId.value);
    }
    
    const { data, error } = await query;
      
    if (error) {
      console.error('거래처 조회 오류:', error);
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
    console.error('거래처 조회 예외:', err);
    hospitals.value = [];
  }
}

// 검수 데이터 조회 (absorption_analysis에서 모든 데이터를 불러오고, 필터링은 데이터 카드에서 처리)
async function fetchPerformanceRecords() {
  if (!selectedSettlementMonth.value) {
    displayRows.value = [];
    return;
  }
  
  loading.value = true;
  try {
    // absorption_analysis 데이터
    const { data: aaData, error: aaError } = await supabase.from('absorption_analysis').select('*');
    if (aaError) { displayRows.value = []; return; }

    // 연관 테이블 데이터
    await Promise.all([
      fetchAllPerformanceRecords(),
      fetchAllCompanies(),
      fetchAllClients(),
      fetchAllProducts()
    ]);

    // 정산월 필터링: performance_records의 settlement_month를 참조
    const filteredAA = aaData.filter(row => {
      const record = allPerformanceRecords.value.find(r => r.id === row.performance_record_id);
      return record && record.settlement_month === selectedSettlementMonth.value;
    });

    // 매핑
    displayRows.value = filteredAA.map(row => {
      const record = allPerformanceRecords.value.find(r => r.id === row.performance_record_id);
      const company = record ? allCompanies.value.find(c => c.id === record.company_id) : null;
      const client = record ? allClients.value.find(c => c.id === record.client_id) : null;
      const product = record ? allProducts.value.find(p => p.id === record.product_id) : null;
      
      // 수수료율 계산 (modify가 있으면 그것을, 없으면 제품의 commission_rate)
      const commissionRate = row.commission_rate_modify !== null && row.commission_rate_modify !== undefined 
        ? row.commission_rate_modify 
        : (product ? product.commission_rate : 0);
      
      // 수량 (modify가 있으면 그것을, 없으면 원본)
      const prescriptionQty = row.prescription_qty_modify !== null && row.prescription_qty_modify !== undefined
        ? row.prescription_qty_modify
        : (record ? record.prescription_qty : 0);
      
      // 처방액 계산
      const price = product ? product.price : 0;
      const prescriptionAmount = prescriptionQty * price;
      
      // 지급액 계산
      const paymentAmount = Math.round(prescriptionAmount * commissionRate / 100);
      
      return {
        ...row,
        // 기본 정보
        performance_record_id: row.performance_record_id,
        company_id: record ? record.company_id : null,
        client_id: record ? record.client_id : null,
        product_id: record ? record.product_id : null,
        
        // 회사 정보
        company_group: company ? company.company_group : '',
        company_name: company ? company.company_name : '',
        assigned_pharmacist_contact: company ? company.assigned_pharmacist_contact : '',
        
        // 거래처 정보
        client_name: client ? client.name : '',
        
        // 제품 정보
        product_name_display: product ? product.product_name : '',
        insurance_code: product ? product.insurance_code : '',
        price: price ? price.toLocaleString() : '0',
        
        // 처방 정보 (원본 또는 수정값)
        settlement_month: record ? record.settlement_month : '',
        prescription_month: row.prescription_month_modify || (record ? record.prescription_month : ''),
        prescription_qty: prescriptionQty,
        prescription_type: row.prescription_type_modify || (record ? record.prescription_type : ''),
        remarks: row.remarks_modify || (record ? record.remarks : ''),
        
        // 계산된 금액
        prescription_amount: prescriptionAmount.toLocaleString(),
        commission_rate: commissionRate,
        payment_amount: paymentAmount.toLocaleString(),
        
        // 등록 정보
        created_date: record ? formatDateTime(record.created_at) : '',
        created_by: company ? company.company_name : '',
        
        // 검수 상태
        review_status: row.review_status || '검수중',
        review_action: row.review_action || null,
        
        // 편집 상태
        isEditing: false,
        originalData: null
      };
    });
    
    // 체크박스 상태 초기화
    selectedRowsMap.value = {};
    selectedRows.value = [];
    selectAllChecked.value = false;
    
  } catch (err) {
    console.error('검수 데이터 조회 예외:', err);
    displayRows.value = [];
  } finally {
    loading.value = false;
  }
}

// 실적 정보 불러오기 (검수완료된 실적을 absorption_analysis에 저장 및 증분 로딩)
async function loadPerformanceData() {
  if (!selectedSettlementMonth.value) {
    alert('정산월을 선택하세요.');
    return;
  }

  if (!confirm('해당 실적을 검수 작업에 추가하시겠습니까?\n기존 작업 중인 데이터는 유지됩니다.')) {
    return;
  }

  try {
    console.log('=== 실적 정보 불러오기 시작 ===');
    console.log('정산월:', selectedSettlementMonth.value);

    // 1. 현재 absorption_analysis에 있는 performance_record_id 목록 조회
    const { data: existingData, error: existingError } = await supabase
      .from('absorption_analysis')
      .select('performance_record_id')
      .eq('settlement_month', selectedSettlementMonth.value)
      .not('performance_record_id', 'is', null);

    if (existingError) {
      throw new Error('기존 데이터 조회 실패: ' + existingError.message);
    }

    const existingRecordIds = new Set(existingData?.map(item => item.performance_record_id) || []);
    console.log('기존 absorption_analysis에 있는 performance_record_id:', existingRecordIds);

    // 2. performance_records에서 아직 검수하지 않은 데이터 조회 (user_edit_status = '대기')
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
      .eq('settlement_month', selectedSettlementMonth.value)
      .eq('user_edit_status', '대기'); // 대기 상태 데이터만

    // 처방월 필터링 (0이 아닐 때만)
    if (prescriptionOffset.value !== 0 && prescriptionMonth.value) {
      query = query.eq('prescription_month', prescriptionMonth.value);
    }
    
    // 업체가 선택된 경우
    if (selectedCompanyId.value) {
      query = query.eq('company_id', selectedCompanyId.value);
    }
    
    // 거래처가 선택된 경우
    if (selectedHospitalId.value) {
      query = query.eq('client_id', selectedHospitalId.value);
    }

    const { data, error } = await query.order('created_at', { ascending: true });

    console.log('대기 상태 실적 조회 결과:', data?.length || 0, '건');

    if (error) {
      console.error('실적 데이터 조회 오류:', error);
      alert('실적 데이터 조회 중 오류가 발생했습니다.');
      return;
    }

    if (!data || data.length === 0) {
      alert('해당 정산월의 대기 상태 실적 데이터가 없습니다.');
      return;
    }

    // 3. 새로 추가할 데이터만 필터링 (기존에 없는 것만)
    const newRecords = data.filter(record => !existingRecordIds.has(record.id));
    console.log('새로 추가할 실적:', newRecords.length, '건');

    if (newRecords.length === 0) {
      alert('새로 추가할 대기 상태 실적이 없습니다.\n모든 대기 실적이 이미 검수 작업에 포함되어 있습니다.');
      return;
    }

    // 4. 새로운 데이터만 absorption_analysis 테이블에 저장할 데이터 준비
    const analysisData = [];
    
    for (const record of newRecords) {
      // 수수료율 자동 계산
      let commissionRate = 0;
      const company = record.companies;
      const product = record.products;
      
      if (company && product && company.default_commission_grade) {
        // settlement_share에서 수수료율 조회
        try {
          const { data: settlementData } = await supabase
            .from('settlement_months')
            .select('id')
            .eq('settlement_month', record.prescription_month)
            .single();

          if (settlementData) {
            const { data: rateData } = await supabase
              .from('settlement_share')
              .select('commission_rate')
              .eq('settlement_month_id', settlementData.id)
              .eq('product_id', record.product_id)
              .eq('grade', company.default_commission_grade)
              .single();

            if (rateData) {
              commissionRate = (rateData.commission_rate || 0) * 100;
            }
          }
        } catch (err) {
          console.error('수수료율 조회 오류:', err);
        }
      }

      const prescriptionAmount = record.prescription_qty * product.price;
      const paymentAmount = Math.round(prescriptionAmount * commissionRate / 100);

      const analysisRow = {
        settlement_month: selectedSettlementMonth.value,
        prescription_month: record.prescription_month,
        company_id: record.company_id,
        client_id: record.client_id,
        product_id: record.product_id,
        company_group: company.company_group,
        company_name: company.company_name,
        client_name: record.clients.name, // 호환성을 위해 유지
        product_name: product.product_name, // 호환성을 위해 유지
        insurance_code: product.insurance_code, // 호환성을 위해 유지
        price: Number(product.price) || 0, // 호환성을 위해 유지
        prescription_qty: Number(record.prescription_qty) || 0,
        prescription_amount: prescriptionAmount,
        prescription_type: record.prescription_type,
        wholesale_sales: 0,
        direct_sales: 0,
        total_sales: 0,
        absorption_rate: 0,
        commission_rate: commissionRate,
        payment_amount: paymentAmount,
        remarks: record.remarks || '',
        review_status: '검수중', // 새로 추가되는 데이터는 검수중 상태
        review_action: null, // 초기 액션 없음
        isEditing: false,
        originalData: { ...record }
      };

      analysisData.push(analysisRow);
    }

    // 5. 새로운 데이터만 absorption_analysis 테이블에 저장
    const { error: insertError } = await supabase
      .from('absorption_analysis')
      .insert(analysisData);
      
    if (insertError) {
      throw new Error('흡수율 분석 데이터 저장 실패: ' + insertError.message);
    }

    // 6. 해당 performance_records의 상태를 '검수중'으로 변경
    const recordIds = newRecords.map(record => record.id);
    const { error: statusUpdateError } = await supabase
      .from('performance_records')
      .update({ user_edit_status: '검수중' })
      .in('id', recordIds);

    if (statusUpdateError) {
      console.error('실적 상태 업데이트 오류:', statusUpdateError);
      // 오류가 발생해도 전체 작업을 중단하지 않음 (경고만 표시)
    }

    // 7. 저장된 데이터 다시 로드
    await fetchPerformanceRecords();
    
    // 8. 데이터 카드의 목록 필터를 필터 카드와 동일하게 설정
    if (selectedCompanyId.value) {
      const company = companies.value.find(c => c.id === selectedCompanyId.value);
      if (company) {
        listFilterCompany.value = company.company_name;
      }
    } else {
      listFilterCompany.value = '';
    }
    
    if (selectedHospitalId.value) {
      const hospital = hospitals.value.find(h => h.id === selectedHospitalId.value);
      if (hospital) {
        listFilterClient.value = hospital.name;
      }
    } else {
      listFilterClient.value = '';
    }
    
    const filterInfo = [];
    if (selectedCompanyId.value) {
      const company = companies.value.find(c => c.id === selectedCompanyId.value);
      if (company) filterInfo.push(`업체: ${company.company_name}`);
    }
    if (selectedHospitalId.value) {
      const hospital = hospitals.value.find(h => h.id === selectedHospitalId.value);
      if (hospital) filterInfo.push(`거래처: ${hospital.name}`);
    }
    
    const filterText = filterInfo.length > 0 ? `\n필터 조건: ${filterInfo.join(', ')}` : '';
    
    alert(`${analysisData.length}건의 신규 실적 데이터를 검수 작업에 추가했습니다.\n${filterText}\n해당 실적들은 사용자에게 수정이 불가능한 '검수중"으로 보여집니다.`);
    
  } catch (err) {
    console.error('실적 데이터 불러오기 예외:', err);
    alert('실적 데이터 불러오기 중 오류가 발생했습니다: ' + err.message);
  }
}

// 체크박스 관련 함수들
function onRowSelectChange(rowData, isSelected) {
  if (isSelected) {
    selectedRowsMap.value[rowData.id] = true;
    selectedRows.value.push(rowData);
  } else {
    selectedRowsMap.value[rowData.id] = false;
    selectedRows.value = selectedRows.value.filter(row => row.id !== rowData.id);
  }
  updateSelectAllState();
}

function onRowSelect(rowData) {
  const isSelected = selectedRowsMap.value[rowData.id];
  onRowSelectChange(rowData, isSelected);
}

function updateSelectAllState() {
  const selectableRows = filteredRows.value.filter(row => row.review_action !== '제외');
  selectAllChecked.value = selectableRows.length > 0 && 
    selectableRows.every(row => selectedRowsMap.value[row.id]);
}

function toggleSelectAll() {
  const selectableRows = filteredRows.value.filter(row => row.review_action !== '제외');
  
  if (selectAllChecked.value) {
    // 전체 선택
    selectableRows.forEach(row => {
      selectedRowsMap.value[row.id] = true;
    });
    selectedRows.value = [...selectableRows];
  } else {
    // 전체 해제
    selectedRowsMap.value = {};
    selectedRows.value = [];
  }
}

function selectAll() {
  const selectableRows = filteredRows.value.filter(row => row.review_action !== '제외');
  selectableRows.forEach(row => {
    selectedRowsMap.value[row.id] = true;
  });
  selectedRows.value = [...selectableRows];
  selectAllChecked.value = true;
}

function unselectAll() {
  selectedRowsMap.value = {};
  selectedRows.value = [];
  selectAllChecked.value = false;
}

// 목록 필터링 관련 함수들
function clearListFilters() {
  listFilterCompany.value = '';
  listFilterClient.value = '';
  listFilterProduct.value = '';
  listFilterStatus.value = '';
}

// 행 액션 함수들
function excludeRow(rowData) {
  if (rowData.review_status === '완료') return;
  
  rowData.review_action = '제외';
  
  // absorption_analysis에 review_action 저장
  if (!rowData.id.toString().startsWith('new_')) {
    supabase
      .from('absorption_analysis')
      .update({ review_action: '제외' })
      .eq('id', rowData.id)
      .then(({ error }) => {
        if (error) console.error('제외 액션 저장 오류:', error);
      });
  }
  
  selectedRowsMap.value[rowData.id] = false;
  selectedRows.value = selectedRows.value.filter(row => row.id !== rowData.id);
  updateSelectAllState();
}

// 편집 관련 함수들
function startEdit(row) {
  if (row.review_status === '완료') {
    alert('완료된 실적은 수정할 수 없습니다.');
    return;
  }
  
  row.isEditing = true;
  row.originalData = { ...row };
  
  // 처방월 초기값 설정 (기존 처방월을 수정 필드에 설정)
  if (!row.prescription_month_modify && row.prescription_month) {
    row.prescription_month_modify = row.prescription_month;
  }
}

async function saveEdit(row) {
  try {
    if (row.isNewRow) {
      // 새로운 행 - INSERT
      const { data, error } = await supabase
        .from('absorption_analysis')
        .insert({
          performance_record_id: null, // 새로운 행은 performance_record_id가 없음
          prescription_month_modify: row.prescription_month_modify,
          product_id_modify: row.product_id_modify,
          prescription_qty_modify: row.prescription_qty_modify,
          prescription_type_modify: row.prescription_type_modify,
          commission_rate_modify: row.commission_rate_modify,
          remarks_modify: row.remarks,
          review_status: '검수중',
          review_action: '추가'
        })
        .select()
        .single();

      if (error) {
        throw error;
      }

      // 성공적으로 저장되면 실제 ID로 업데이트
      row.id = data.id;
      row.isNewRow = false;
      row.review_action = '추가';
      
    } else {
      // 기존 행 - UPDATE
      const { error } = await supabase
        .from('absorption_analysis')
        .update({
          product_id_modify: row.product_id,
          prescription_qty_modify: row.prescription_qty,
          prescription_type_modify: row.prescription_type,
          remarks_modify: row.remarks,
          prescription_month_modify: row.prescription_month_modify,
          commission_rate_modify: row.commission_rate_modify,
          review_action: '수정'
        })
        .eq('id', row.id);

      if (error) {
        throw error;
      }

      row.review_action = '수정';
    }

    // 성공적으로 저장되면 편집 모드 종료
    row.isEditing = false;
    
    // 금액 재계산
    recalculateAmounts(row);
    
  } catch (err) {
    console.error('저장 오류:', err);
    alert('저장 중 오류가 발생했습니다.');
    // 오류 발생 시 원래 데이터로 복원 (새로운 행이 아닌 경우에만)
    if (!row.isNewRow) {
      cancelEdit(row);
    }
  }
}

function cancelEdit(row) {
  if (row.isNewRow) {
    // 새로운 행인 경우 리스트에서 제거
    const index = displayRows.value.findIndex(r => r.id === row.id);
    if (index !== -1) {
      displayRows.value.splice(index, 1);
    }
    console.log('새로운 행이 취소되어 제거되었습니다.');
  } else {
    // 기존 행인 경우 원래 데이터로 복원
    Object.assign(row, row.originalData);
    row.isEditing = false;
    row.review_action = null;
  }
}

function confirmDeleteRow(index) {
  if (!confirm('이 실적을 삭제하시겠습니까?\n(삭제 표시만 되며, 실제 데이터는 유지됩니다)')) {
    return;
  }
  
  const rowData = filteredRows.value[index];
  
  if (rowData.isNewRow) {
    // 새로운 행인 경우 실제로 리스트에서 제거
    const actualIndex = displayRows.value.findIndex(row => row.id === rowData.id);
    if (actualIndex !== -1) {
      displayRows.value.splice(actualIndex, 1);
    }
    console.log('새로운 행이 삭제되어 제거되었습니다.');
  } else {
    // 기존 행인 경우 삭제 표시만
    rowData.review_action = '삭제';
    
    // absorption_analysis에 review_action 저장
    if (!rowData.id.toString().startsWith('new_')) {
      supabase
        .from('absorption_analysis')
        .update({ review_action: '삭제' })
        .eq('id', rowData.id)
        .then(({ error }) => {
          if (error) {
            console.error('삭제 액션 저장 오류:', error);
          } else {
            console.log('실적이 삭제 표시되었습니다:', rowData);
          }
        });
    }
  }
}

function addRowBelow(index) {
  const currentRow = filteredRows.value[index];
  
  // 새로운 행 생성
  const newRow = {
    id: `new_${Date.now()}`, // 임시 ID
    performance_record_id: null,
    
    // 기존 행에서 복사할 값들 (화면 표시용)
    company_id: currentRow.company_id,
    client_id: currentRow.client_id,
    company_group: currentRow.company_group,
    company_name: currentRow.company_name,
    client_name: currentRow.client_name,
    prescription_month: currentRow.prescription_month,
    prescription_type: currentRow.prescription_type,
    
    // 빈 값으로 시작할 값들 (화면 표시용)
    product_id: null,
    product_name_display: '',
    insurance_code: '',
    price: '0',
    prescription_qty: 0,
    prescription_amount: '0',
    commission_rate: 0,
    payment_amount: '0',
    remarks: '',
    
    // 수정값 필드들 (실제 DB 저장용)
    prescription_month_modify: currentRow.prescription_month,
    product_id_modify: null,
    prescription_qty_modify: 0,
    prescription_type_modify: currentRow.prescription_type,
    commission_rate_modify: null,
    remarks_modify: '',
    
    // 검수 관련 (실제 DB 저장용)
    review_status: '검수중',
    review_action: null,
    
    // 화면 표시용 정보
    created_date: formatDateTime(new Date().toISOString()),
    created_by: '관리자',
    assigned_pharmacist_contact: currentRow.assigned_pharmacist_contact,
    
    // 편집 상태
    isEditing: true, // 자동으로 수정 모드
    originalData: null,
    isNewRow: true // 새로운 행 표시
  };
  
  // displayRows에서 현재 행 아래에 삽입
  const actualIndex = displayRows.value.findIndex(row => row.id === currentRow.id);
  if (actualIndex !== -1) {
    displayRows.value.splice(actualIndex + 1, 0, newRow);
  }
  
  console.log('새로운 행이 추가되었습니다:', newRow);
}

// 편집 관련 함수들
function onClientChange(data, clientName) {
  const client = allClients.value.find(c => c.name === clientName);
  if (client) {
    data.client_id = client.id;
    
    if (!data.review_action && data.review_status !== '완료') {
      data.review_action = '수정';
      
      // absorption_analysis에 review_action 저장
      if (!data.id.toString().startsWith('new_')) {
        supabase
          .from('absorption_analysis')
          .update({ review_action: '수정' })
          .eq('id', data.id)
          .then(({ error }) => {
            if (error) console.error('거래처 변경 액션 저장 오류:', error);
          });
      }
    }
  }
}

function onProductChange(data, productName) {
  const product = allProducts.value.find(p => p.product_name === productName);
  if (product) {
    // 기본 제품 정보 업데이트
    data.product_id = product.id;
    data.product_name_display = product.product_name;
    data.insurance_code = product.insurance_code;
    data.price = product.price.toLocaleString();
    
    // 새로운 행이거나 수정 중인 경우 modify 필드에도 저장
    if (data.isNewRow || data.isEditing) {
      data.product_id_modify = product.id;
      
      // 수수료율 설정 (제품의 기본 수수료율 사용)
      if (product.commission_rate && !data.commission_rate_modify) {
        data.commission_rate_modify = product.commission_rate;
        data.commission_rate = product.commission_rate;
      }
    }
    
    // 금액 재계산
    recalculateAmounts(data);
    
    // 검수 액션 설정 (새로운 행이 아닌 경우에만)
    if (!data.isNewRow && !data.review_action && data.review_status !== '완료') {
      data.review_action = '수정';
      
      // absorption_analysis에 review_action 저장 (기존 행에만)
      if (!data.id.toString().startsWith('new_')) {
        supabase
          .from('absorption_analysis')
          .update({ review_action: '수정' })
          .eq('id', data.id)
          .then(({ error }) => {
            if (error) console.error('제품 변경 액션 저장 오류:', error);
          });
      }
    }
    
    console.log('제품 선택 완료:', {
      product_name: product.product_name,
      product_id: product.id,
      commission_rate: product.commission_rate
    });
  }
}

// 수수료율 표시 및 계산 시 commission_rate_modify 우선 사용
function getCommissionRate(row) {
  if (row.commission_rate_modify !== undefined && row.commission_rate_modify !== null && row.commission_rate_modify !== '') {
    return row.commission_rate_modify;
  }
  // 제품목록에서 product_id로 찾아서 commission_rate 반환
  const product = allProducts.value.find(p => p.id === (row.product_id_modify || row.product_id));
  return product ? product.commission_rate : 0;
}

function recalculateAmounts(data) {
  const price = parseFloat(data.price.replace(/,/g, '')) || 0;
  
  // 수량: modify 값이 있으면 우선 사용, 없으면 기본값
  const qty = (data.isNewRow || data.isEditing) && data.prescription_qty_modify !== null && data.prescription_qty_modify !== undefined
    ? data.prescription_qty_modify 
    : data.prescription_qty || 0;
  
  const prescriptionAmount = price * qty;
  const commissionRate = getCommissionRate(data) || 0;
  const paymentAmount = Math.round(prescriptionAmount * (commissionRate / 100));
  
  data.prescription_amount = prescriptionAmount.toLocaleString();
  data.payment_amount = paymentAmount.toLocaleString();
  
  // 새로운 행이나 수정 중인 경우 현재 입력값도 업데이트
  if (data.isNewRow || data.isEditing) {
    data.prescription_qty = qty;
    if (data.prescription_qty_modify === null || data.prescription_qty_modify === undefined) {
      data.prescription_qty_modify = qty;
    }
  }
}

// 검수 상태 변경 처리 함수 (검수중 ↔ 완료)
async function changeReviewStatus() {
  if (selectedRows.value.length === 0) {
    alert('검수 상태를 변경할 실적을 선택해주세요.');
    return;
  }
  
  // 선택된 행들을 상태별로 분류
  const reviewingRows = selectedRows.value.filter(row => row.review_status === '검수중');
  const completedRows = selectedRows.value.filter(row => row.review_status === '완료');
  
  // 확인 메시지 생성
  let confirmMessage = '검수 상태 변경\n';
  if (reviewingRows.length > 0) {
    confirmMessage += `검수중 → 완료 : ${reviewingRows.length}건\n`;
  }
  if (completedRows.length > 0) {
    confirmMessage += `완료 → 검수중 : ${completedRows.length}건\n`;
  }
  confirmMessage += '\n상태를 변경하시겠습니까?';
  
  if (!confirm(confirmMessage)) {
    return;
  }
  
  try {
    loading.value = true;
    
    let successCount = 0;
    let errorCount = 0;
    
    // 검수중 → 완료 처리
    for (const row of reviewingRows) {
      try {
        // absorption_analysis에서 검수 상태 업데이트
        const { error: updateError } = await supabase
          .from('absorption_analysis')
          .update({ review_status: '완료' })
          .eq('id', row.id);
        
        if (updateError) {
          console.error('검수 상태 업데이트 오류:', updateError);
          errorCount++;
          continue;
        }
        
        // performance_records의 user_edit_status도 업데이트 (사용자 편집 제어용)
        if (row.performance_record_id) {
          await supabase
            .from('performance_records')
            .update({ user_edit_status: '완료' })
            .eq('id', row.performance_record_id);
        }
        
        // UI에서 완료 상태 업데이트
        row.review_status = '완료';
        successCount++;
        
      } catch (err) {
        console.error('검수 완료 처리 오류:', err);
        errorCount++;
      }
    }
    
    // 완료 → 검수중 처리
    for (const row of completedRows) {
      try {
        // absorption_analysis에서 검수 상태 업데이트
        const { error: updateError } = await supabase
          .from('absorption_analysis')
          .update({ review_status: '검수중' })
          .eq('id', row.id);
        
        if (updateError) {
          console.error('검수 상태 업데이트 오류:', updateError);
          errorCount++;
          continue;
        }
        
        // performance_records의 user_edit_status도 업데이트 (사용자 편집 제어용)
        if (row.performance_record_id) {
          await supabase
            .from('performance_records')
            .update({ user_edit_status: '검수중' })
            .eq('id', row.performance_record_id);
        }
        
        // UI에서 검수중 상태 업데이트
        row.review_status = '검수중';
        successCount++;
        
      } catch (err) {
        console.error('검수중 처리 오류:', err);
        errorCount++;
      }
    }
    
    // 결과 메시지 표시
    if (errorCount === 0) {
      alert(`${successCount}건의 실적 상태가 변경되었습니다.`);
    } else {
      alert(`${successCount}건 성공, ${errorCount}건 실패했습니다.`);
    }
    
    // 선택 해제
    selectedRowsMap.value = {};
    selectedRows.value = [];
    selectAllChecked.value = false;
    
  } catch (err) {
    console.error('검수 상태 변경 처리 전체 오류:', err);
    alert('검수 상태 변경 처리 중 오류가 발생했습니다.');
  } finally {
    loading.value = false;
  }
}

// 검수 대상 제외 처리 함수 (absorption_analysis에서 삭제)
async function removeFromReview() {
  if (selectedRows.value.length === 0) {
    alert('검수 대상에서 제외할 실적을 선택해주세요.');
    return;
  }
  
  const confirmMessage = `선택된 ${selectedRows.value.length}건의 실적을 검수 대상에서 제외하시겠습니까?\n제외된 실적은 사용자가 다시 수정할 수 있는 상태가 됩니다.`;
  
  if (!confirm(confirmMessage)) {
    return;
  }
  
  try {
    loading.value = true;
    
    let successCount = 0;
    let errorCount = 0;
    
    for (const row of selectedRows.value) {
      try {
        // 1. absorption_analysis에서 해당 행 삭제
        const { error: deleteError } = await supabase
          .from('absorption_analysis')
          .delete()
          .eq('id', row.id);
        
        if (deleteError) {
          console.error('absorption_analysis 삭제 오류:', deleteError);
          errorCount++;
          continue;
        }
        
        // 2. performance_records의 user_edit_status를 '대기'로 되돌리기
        if (row.performance_record_id) {
          const { error: updateError } = await supabase
            .from('performance_records')
            .update({ user_edit_status: '대기' })
            .eq('id', row.performance_record_id);
          
          if (updateError) {
            console.error('performance_records 상태 업데이트 오류:', updateError);
            // absorption_analysis는 이미 삭제되었으므로 에러만 로그
          }
        }
        
        successCount++;
        
      } catch (err) {
        console.error('검수 대상 제외 처리 오류:', err);
        errorCount++;
      }
    }
    
    // 결과 메시지 표시
    if (errorCount === 0) {
      alert(`${successCount}건의 실적이 검수 대상에서 제외되었습니다.\n해당 실적들은 사용자가 다시 수정할 수 있습니다.`);
    } else {
      alert(`${successCount}건 성공, ${errorCount}건 실패했습니다.`);
    }
    
    // 데이터 다시 로드
    await fetchPerformanceRecords();
    
    // 선택 해제
    selectedRowsMap.value = {};
    selectedRows.value = [];
    selectAllChecked.value = false;
    
  } catch (err) {
    console.error('검수 대상 제외 처리 전체 오류:', err);
    alert('검수 대상 제외 처리 중 오류가 발생했습니다.');
  } finally {
    loading.value = false;
  }
}

function restoreRow(rowData) {
  if (!confirm('이 실적의 삭제를 취소하시겠습니까?')) {
    return;
  }
  
  // 삭제 상태 해제
  rowData.review_action = null;
  
  // absorption_analysis에 review_action 저장
  if (!rowData.id.toString().startsWith('new_')) {
    supabase
      .from('absorption_analysis')
      .update({ review_action: null })
      .eq('id', rowData.id)
      .then(({ error }) => {
        if (error) {
          console.error('되돌리기 액션 저장 오류:', error);
        } else {
          console.log('실적이 복구되었습니다:', rowData);
        }
      });
  }
}

// 초기화
onMounted(async () => {
  await Promise.all([
    fetchAvailableMonths(),
    fetchAllCompanies(),
    fetchAllClients(),
    fetchAllProducts()
  ]);
  
  // 페이지 초기 진입 시 absorption_analysis 데이터 로드
  if (selectedSettlementMonth.value) {
    await fetchPerformanceRecords();
  }
});

// 행 클래스 설정 함수
function getRowClass(data) {
  if (data.review_action === '삭제') {
    return 'deleted-row';
  } else if (data.review_action === '추가') {
    return 'added-row';
  } else if (data.review_action === '수정') {
    return 'modified-row';
  }
  return '';
}
</script>

<style scoped>
.performance-review-view {
  padding: 0px;
}

.data-card-buttons {
  display: flex;
  gap: 8px;
}

.btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* 실적 검수 테이블 전용 스타일 */
.admin-performance-review-table {
  font-size: 14px;
}

/* 컴포넌트별 추가 스타일 (main.css와 중복되지 않는 것만) */
.admin-performance-review-table :deep(.p-datatable-thead th) {
  padding: 8px 4px;
  font-size: 13px;
}

.admin-performance-review-table :deep(.p-datatable-tbody td) {
  padding: 6px 4px;
  font-size: 12px;
}

/* 목록 필터링 전용 스타일 */
.select_200px {
  height: 38px;
  width: 204px;
  padding: 4px 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.select_240px {
  height: 38px;
  width: 240px;
  padding: 4px 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.select_80px {
  width: 80px;
  padding: 4px 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.select_120px {
  width: 120px;
  padding: 4px 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.btn-secondary-small {
  font-size: var(--font-size-base) !important;
  background-color: #fff;
  color: var(--primary-blue);
  border: none;
  padding: 4px 4px;
  border-radius: 4px;
  cursor: pointer;
}

.btn-secondary-small:hover {
  background-color: none;
  text-decoration: underline;
  opacity: 1 !important;
  transform: translateY(0px) !important;
  box-shadow: none !important;
  transition: all 0.2s ease-in-out !important;
}

/* 드롭다운 아이콘 셀 오른쪽 정렬 */
.admin-performance-review-table :deep(.p-dropdown) {
  width: 100% !important;
}
.admin-performance-review-table :deep(.p-dropdown .p-dropdown-label) {
  padding-right: 2.5em !important;
}
.admin-performance-review-table :deep(.p-dropdown .p-dropdown-trigger) {
  right: 0.5em !important;
  left: auto !important;
  position: absolute !important;
}
.admin-performance-review-table :deep(.p-dropdown) {
  position: relative !important;
}

/* 평상시 셀 패딩 설정 */
.admin-performance-review-table :deep(.p-datatable-tbody td) {
  padding: 4px 6px !important;
}

/* 수정 모드에서만 입력 요소들이 셀에 딱 맞도록 조정 */
.admin-performance-review-table :deep(.p-datatable-tbody td .edit-mode-input),
.admin-performance-review-table :deep(.p-datatable-tbody td .edit-mode-input input) {
  box-sizing: border-box !important;
  width: 100% !important;
  padding: 2px 4px !important;
  margin: 0 !important;
  border: 1px solid #ddd !important;
  border-radius: 4px !important;
}

.admin-performance-review-table :deep(.p-datatable-tbody td .p-inputnumber-input) {
  box-sizing: border-box !important;
  width: 100% !important;
  padding: 2px 4px !important;
  margin: 0 !important;
  border: none !important;
}

/* 수정 모드 정렬 설정 */
/* 제품명 - 왼쪽 정렬 */
.admin-performance-review-table :deep(.p-datatable-tbody td[data-field="product_name_display"] select) {
  text-align: left !important;
}

/* 수량 - 오른쪽 정렬 */
.admin-performance-review-table :deep(.p-datatable-tbody td[data-field="prescription_qty"] .p-inputnumber),
.admin-performance-review-table :deep(.p-datatable-tbody td[data-field="prescription_qty"] .p-inputnumber-input) {
  text-align: right !important;
}

/* 수수료율 - 가운데 정렬 */
.admin-performance-review-table :deep(.p-datatable-tbody td[data-field="commission_rate"] .p-inputnumber),
.admin-performance-review-table :deep(.p-datatable-tbody td[data-field="commission_rate"] .p-inputnumber-input) {
  text-align: center !important;
}

/* 처방구분 - 가운데 정렬 */
.admin-performance-review-table :deep(.p-datatable-tbody td[data-field="prescription_type"] select) {
  text-align: center !important;
}

/* 처방월 - 가운데 정렬 */
.admin-performance-review-table :deep(.p-datatable-tbody td[data-field="prescription_month_modify"] select) {
  text-align: center !important;
}

/* 비고 - 왼쪽 정렬 */
.admin-performance-review-table :deep(.p-datatable-tbody td[data-field="remarks"] .p-inputtext) {
  text-align: left !important;
}

/* 삭제된 행 스타일링 */
.admin-performance-review-table :deep(.deleted-row) {
  background-color: #ffe6e6 !important;
}

.admin-performance-review-table :deep(.deleted-row td) {
  background-color: #ffe6e6 !important;
  color: #999 !important;
}

.admin-performance-review-table :deep(.deleted-row td span) {
  color: #999 !important;
}

/* 삭제된 행에서 선택, 상태, 작업 컬럼은 일반 색상 유지 */
.admin-performance-review-table :deep(.deleted-row td:nth-child(1)),
.admin-performance-review-table :deep(.deleted-row td:nth-child(2)), 
.admin-performance-review-table :deep(.deleted-row td:nth-child(3)) {
  color: inherit !important;
}

.admin-performance-review-table :deep(.deleted-row td:nth-child(1) *),
.admin-performance-review-table :deep(.deleted-row td:nth-child(2) *),
.admin-performance-review-table :deep(.deleted-row td:nth-child(3) *) {
  color: inherit !important;
}

/* 삭제된 행의 No부터 등록자까지 컬럼에 취소선 추가 */
.admin-performance-review-table :deep(.deleted-row td:nth-child(n+5)) {
  text-decoration: line-through !important;
}

.admin-performance-review-table :deep(.deleted-row td:nth-child(n+5) span) {
  text-decoration: line-through !important;
}

/* 추가된 행 스타일링 */
.admin-performance-review-table :deep(.added-row) {
  background-color: #e6f3ff !important;
}

.admin-performance-review-table :deep(.added-row td) {
  background-color: #e6f3ff !important;
}

/* 수정된 행 스타일링 */
.admin-performance-review-table :deep(.modified-row) {
  background-color: #fff9e6 !important;
}

.admin-performance-review-table :deep(.modified-row td) {
  background-color: #fff9e6 !important;
}

/* 되돌리기 버튼 스타일 */
.btn-restore-sm {
  background-color: #28a745;
  color: white;
  border: none;
  padding: 4px;
  border-radius: 3px;
  font-size: 12px;
  cursor: pointer;
  width: 26px;
  height: 24px;
  min-width: 26px;
  text-align: center;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.btn-restore-sm:hover {
  background-color: #218838;
  transform: translateY(-1px);
}
</style> 