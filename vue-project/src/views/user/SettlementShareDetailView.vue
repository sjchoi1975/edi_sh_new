<template>
  <div class="admin-settlement-share-detail-view page-container" style="display: flex; flex-direction: column; height: 100vh;">
    <!-- 상단 필터카드: 실적 등록 현황과 동일하게 -->
    <div class="filter-card performance-list-filter-row" style="flex-shrink: 0;">

      <div class="filter-row">
        <div style="display: flex; align-items: center; gap: 8px; margin-right: 24px;">
          <label style="white-space: nowrap; font-weight: 400">정산월</label>
          <select v-model="selectedMonth" @change="onMonthChange" class="select_month">
            <option v-for="month in availableMonths" :key="month" :value="month">{{ month }}</option>
          </select>
        </div>

        <div style="display: flex; align-items: center; gap: 8px; margin-right: 24px;">
          <label style="white-space: nowrap; font-weight: 400">처방월</label>
          <select v-model="selectedPrescriptionMonth" @change="onFilterChange" class="select_month">
            <option value="">- 전체 -</option>
            <option v-for="m in availablePrescriptionMonths" :key="m" :value="m">{{ m }}</option>
          </select>
        </div>

        <div style="display: flex; align-items: center; gap: 8px;">
          <label style="white-space: nowrap; font-weight: 400">거래처</label>
          <select v-model="selectedClient" @change="onFilterChange" class="select_240">
            <option value="">- 전체 -</option>
            <option v-for="c in availableClients" :key="c" :value="c">{{ c }}</option>
          </select>
        </div>
      </div>
    </div>

    <!-- 데이터 카드 -->
    <div class="data-card" style="flex-grow: 1; display: flex; flex-direction: column; overflow: hidden;">
      <div class="data-card-header" style="flex-shrink: 0;">
        <div class="total-count-display">전체 {{ detailRows.length }} 건</div>
        <div class="action-buttons-group">
          <button class="btn-excell-download" @click="downloadExcel">엑셀 다운로드</button>
        </div>
      </div>
      <div style="flex-grow: 1; overflow: hidden;">
        <DataTable
          :value="detailRows" 
          scrollable 
          scrollHeight="calc(100vh - 220px)"
          class="admin-settlement-share-detail-table"
          >
          <template #empty>조회된 데이터가 없습니다.</template>
          <Column header="No" :headerStyle="{ width: columnWidths.no }">
            <template #body="slotProps">{{ slotProps.index + 1 }}</template>
          </Column>
          <Column field="client_name" header="거래처명" :headerStyle="{ width: columnWidths.client_name }" />
          <Column field="prescription_month" header="처방월" :headerStyle="{ width: columnWidths.prescription_month }" />
          <Column field="product_name" header="제품명" :headerStyle="{ width: columnWidths.product_name }" />
          <Column field="insurance_code" header="보험코드" :headerStyle="{ width: columnWidths.insurance_code }" />
          <Column field="price" header="약가" :headerStyle="{ width: columnWidths.price }" />
          <Column field="prescription_qty" header="처방수량" :headerStyle="{ width: columnWidths.prescription_qty }" />
          <Column field="prescription_amount" header="처방액" :headerStyle="{ width: columnWidths.prescription_amount }" />
          <Column field="commission_rate" header="수수료율" :headerStyle="{ width: columnWidths.commission_rate }" />
          <Column field="payment_amount" header="지급액" :headerStyle="{ width: columnWidths.payment_amount }" />
          <Column field="remarks" header="비고" :headerStyle="{ width: columnWidths.remarks }" />
          <ColumnGroup type="footer">
            <Row>
              <Column footer="합계" :colspan="6" footerClass="footer-cell" footerStyle="text-align:center !important;" />
              <Column :footer="totalQty" footerClass="footer-cell" footerStyle="text-align:right !important;" />
              <Column :footer="totalPrescriptionAmount" footerClass="footer-cell" footerStyle="text-align:right !important;" />
              <Column footerClass="footer-cell" />
              <Column :footer="totalPaymentAmount" footerClass="footer-cell" footerStyle="text-align:right !important;" />
              <Column footerClass="footer-cell" />
            </Row>
          </ColumnGroup>
        </DataTable>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch, computed } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import ColumnGroup from 'primevue/columngroup';
import Row from 'primevue/row';
import { supabase } from '@/supabase';
import * as XLSX from 'xlsx';

const companyId = ref('');
const availableMonths = ref([]);
const selectedMonth = ref('');
const availablePrescriptionMonths = ref([]);
const selectedPrescriptionMonth = ref('');
const availableClients = ref([]);
const selectedClient = ref('');
const detailRows = ref([]);

// 합계 계산
const totalQty = computed(() => {
  return detailRows.value.reduce((sum, row) => sum + (Number(row.prescription_qty?.toString().replace(/,/g, '')) || 0), 0).toLocaleString();
});
const totalPrescriptionAmount = computed(() => {
  return detailRows.value.reduce((sum, row) => sum + (Number(row.prescription_amount?.toString().replace(/,/g, '')) || 0), 0).toLocaleString();
});
const totalPaymentAmount = computed(() => {
  return detailRows.value.reduce((sum, row) => sum + (Number(row.payment_amount?.toString().replace(/,/g, '')) || 0), 0).toLocaleString();
});

const columnWidths = {
  no: '4%',
  client_name: '14%',
  prescription_month: '8%',
  product_name: '14%',
  insurance_code: '8%',
  price: '8%',
  prescription_qty: '8%',
  prescription_amount: '8%',
  commission_rate: '8%',
  payment_amount: '8%',
  remarks: '12%'
};

// 1. 내 company_id 조회
async function fetchCompanyId() {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session?.user?.id) return;
  const { data, error } = await supabase
    .from('companies')
    .select('id')
    .eq('user_id', session.user.id)
    .single();
  if (!error && data) companyId.value = data.id;
}

// 2. 공유된 정산월 목록 조회
async function fetchAvailableMonths() {
  if (!companyId.value) return;
  const { data, error } = await supabase
    .from('settlement_share')
    .select('settlement_month')
    .eq('company_id', companyId.value)
    .eq('share_enabled', true);
  if (!error && data) {
    availableMonths.value = Array.from(new Set(data.map(d => d.settlement_month))).sort((a, b) => b.localeCompare(a));
    if (availableMonths.value.length > 0) selectedMonth.value = availableMonths.value[0];
  }
}

// 3. 처방월/거래처 옵션 조회
async function fetchFilterOptions() {
  if (!companyId.value || !selectedMonth.value) return;
  const { data, error } = await supabase
    .from('absorption_analysis')
    .select('prescription_month, client_name')
    .eq('settlement_month', selectedMonth.value)
    .eq('company_id', companyId.value);
  if (!error && data) {
    availablePrescriptionMonths.value = Array.from(new Set(data.map(r => r.prescription_month))).sort((a, b) => b.localeCompare(a));
    availableClients.value = Array.from(new Set(data.map(r => r.client_name))).sort();
  }
}

// 4. 상세 데이터 조회
async function fetchDetailRows() {
  if (!companyId.value || !selectedMonth.value) {
    detailRows.value = [];
    return;
  }
  let query = supabase
    .from('absorption_analysis')
    .select('*')
    .eq('settlement_month', selectedMonth.value)
    .eq('company_id', companyId.value);
  if (selectedPrescriptionMonth.value) query = query.eq('prescription_month', selectedPrescriptionMonth.value);
  if (selectedClient.value) query = query.eq('client_name', selectedClient.value);
  const { data, error } = await query;
  if (!error && data) {
    detailRows.value = data.map(row => ({
      ...row,
      price: row.price?.toLocaleString() || '',
      prescription_qty: row.prescription_qty?.toLocaleString() || '',
      prescription_amount: row.prescription_amount?.toLocaleString() || '',
      payment_amount: row.payment_amount?.toLocaleString() || '',
      commission_rate: row.commission_rate ? row.commission_rate : '',
    }));
  } else {
    detailRows.value = [];
  }
}

function onMonthChange() {
  selectedPrescriptionMonth.value = '';
  selectedClient.value = '';
  fetchFilterOptions();
  fetchDetailRows();
}
function onFilterChange() {
  fetchDetailRows();
}

onMounted(async () => {
  await fetchCompanyId();
  await fetchAvailableMonths();
  await fetchFilterOptions();
  await fetchDetailRows();
});

watch(selectedMonth, async () => {
  await fetchFilterOptions();
  await fetchDetailRows();
});

function downloadExcel() {
  if (!detailRows.value.length) {
    alert('다운로드할 데이터가 없습니다.');
    return;
  }
  const excelData = detailRows.value.map(row => ({
    거래처명: row.client_name,
    처방월: row.prescription_month,
    제품명: row.product_name,
    보험코드: row.insurance_code,
    약가: Number(row.price?.toString().replace(/,/g, '')) || 0,
    처방수량: Number(row.prescription_qty?.toString().replace(/,/g, '')) || 0,
    처방액: Number(row.prescription_amount?.toString().replace(/,/g, '')) || 0,
    수수료율: Number(row.commission_rate?.toString().replace(/,/g, '')) || 0,
    지급액: Number(row.payment_amount?.toString().replace(/,/g, '')) || 0,
    비고: row.remarks || '',
  }));
  const ws = XLSX.utils.json_to_sheet(excelData);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '정산내역서상세');
  ws['!cols'] = [
    { width: 16 }, { width: 10 }, { width: 18 }, { width: 12 }, { width: 8 }, { width: 10 }, { width: 12 }, { width: 8 }, { width: 12 }, { width: 16 }
  ];
  // 숫자 셀 서식 적용 (약가, 처방수량, 처방액, 수수료율, 지급액)
  const numCols = [5, 6, 7, 8, 9]; // E~I
  const range = XLSX.utils.decode_range(ws['!ref']);
  for (let row = 1; row <= range.e.r; row++) {
    numCols.forEach(col => {
      const cell = ws[XLSX.utils.encode_cell({ r: row, c: col })];
      if (cell) cell.z = '#,##0';
    });
  }
  const today = new Date().toISOString().split('T')[0];
  const fileName = `정산내역서상세_${selectedMonth.value || ''}_${today}.xlsx`;
  XLSX.writeFile(wb, fileName);
}
</script>
