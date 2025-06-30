<template>
  <div class="user-settlement-detail-view page-container" style="display: flex; flex-direction: column; height: 100vh;">
    <!-- 상단 필터카드 -->
    <div class="filter-card" style="flex-shrink: 0;">
      <div class="filter-row">
        <div style="display: flex; align-items: center; gap: 8px">
          <label>정산월</label>
          <select v-model="selectedMonth" class="select_month">
            <option v-for="month in availableMonths" :key="month" :value="month">{{ month }}</option>
          </select>
        </div>
        <div style="display: flex; align-items: center; gap: 8px">
          <label>처방월</label>
          <select v-model="selectedPrescriptionMonth" class="select_month">
            <option value="">- 전체 -</option>
            <option v-for="m in availablePrescriptionMonths" :key="m" :value="m">{{ m }}</option>
          </select>
        </div>
        <div style="display: flex; align-items: center; gap: 8px;">
          <label style="white-space: nowrap; font-weight: 400">병의원</label>
          <select v-model="selectedClient" class="select_240px">
            <option value="">- 전체 -</option>
            <option v-for="c in availableClients" :key="c" :value="c">{{ c }}</option>
          </select>
        </div>
      </div>
    </div>

    <!-- 데이터 카드 -->
    <div class="data-card" style="flex-grow: 1; display: flex; flex-direction: column; overflow: hidden;">
      <div class="data-card-header" style="flex-shrink: 0; justify-content: space-between;">
        <div class="total-count-display">전체 {{ detailRows.length }} 건</div>
        <div class="settlement-summary">
          <span>공급가 : {{ settlementSummary.supply_price?.toLocaleString() }}원</span>
          <span>부가세 : {{ settlementSummary.vat_price?.toLocaleString() }}원</span>
          <span>합계 : {{ settlementSummary.total_price?.toLocaleString() }}원</span>
        </div>
        <div class="action-buttons-group">
          <button class="btn-excell-download" @click="downloadExcel">엑셀 다운로드</button>
        </div>
      </div>
      <div style="flex-grow: 1; overflow: hidden;">
        <DataTable
          :value="detailRows" 
          scrollable 
          scrollHeight="calc(100vh - 220px)"
          class="user-settlement-detail-table"
          >
          <template #empty>공유된 정산 내역이 없습니다.</template>
          <Column header="No" :headerStyle="{ width: columnWidths.no }">
            <template #body="slotProps">{{ slotProps.index + 1 }}</template>
          </Column>
          <Column field="client_name" header="병의원명" :headerStyle="{ width: columnWidths.client_name }" :sortable="true" />
          <Column field="prescription_month" header="처방월" :headerStyle="{ width: columnWidths.prescription_month }" :sortable="true" />
          <Column field="product_name_display" header="제품명" :headerStyle="{ width: columnWidths.product_name }" :sortable="true" />
          <Column field="insurance_code" header="보험코드" :headerStyle="{ width: columnWidths.insurance_code }" :sortable="true" />
          <Column field="price" header="약가" :headerStyle="{ width: columnWidths.price }" :sortable="true" />
          <Column field="prescription_qty" header="처방수량" :headerStyle="{ width: columnWidths.prescription_qty }" :sortable="true" />
          <Column field="prescription_amount" header="처방액" :headerStyle="{ width: columnWidths.prescription_amount }" :sortable="true" />
          <Column field="commission_rate" header="수수료율" :headerStyle="{ width: columnWidths.commission_rate }" :sortable="true" />
          <Column field="payment_amount" header="지급액" :headerStyle="{ width: columnWidths.payment_amount }" :sortable="true" />
          <Column field="remarks" header="비고" :headerStyle="{ width: columnWidths.remarks }" :sortable="true" />
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
const allDataForMonth = ref([]);

const totalQty = computed(() => detailRows.value.reduce((sum, row) => sum + (Number(row.prescription_qty?.toString().replace(/,/g, '')) || 0), 0).toLocaleString());
const totalPrescriptionAmount = computed(() => detailRows.value.reduce((sum, row) => sum + (Number(row.prescription_amount?.toString().replace(/,/g, '')) || 0), 0).toLocaleString());
const totalPaymentAmount = computed(() => Math.round(detailRows.value.reduce((sum, row) => sum + (Number(row.payment_amount?.toString().replace(/,/g, '')) || 0), 0)).toLocaleString());

const settlementSummary = computed(() => {
  const totalPrice = detailRows.value.reduce((sum, row) => {
    // 반올림을 위해 parseFloat 사용 후 Number로 변환
    const payment = parseFloat(row.payment_amount?.toString().replace(/,/g, '')) || 0;
    return sum + payment;
  }, 0);

  const supplyPrice = Math.round(totalPrice / 1.1);
  const vatPrice = Math.round(totalPrice - supplyPrice);
  
  return {
    total_price: Math.round(totalPrice),
    supply_price: supplyPrice,
    vat_price: vatPrice,
  };
});

const columnWidths = {
   no: '4%',
   client_name: '18%',
   prescription_month: '6%',
   product_name: '16%',
   insurance_code: '7%',
   price: '7%',
   prescription_qty: '7%',
   prescription_amount: '7%',
   commission_rate: '7%',
   payment_amount: '7%',
   remarks: '14%' };

async function fetchCompanyId() {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session?.user?.id) return;
  const { data, error } = await supabase.from('companies').select('id').eq('user_id', session.user.id).single();
  if (!error && data) companyId.value = data.id;
}

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

async function fetchAllDataForMonth() {
  if (!companyId.value || !selectedMonth.value) {
    allDataForMonth.value = [];
    return;
  }
  
  // 1. settlement_share 테이블에서 공유 여부 확인
  const { data: shareData, error: shareError } = await supabase
    .from('settlement_share')
    .select('share_enabled')
    .eq('settlement_month', selectedMonth.value)
    .eq('company_id', companyId.value)
    .single();

  // 공유되지 않았거나 오류 발생 시, 빈 화면 처리
  if (shareError || !shareData || !shareData.share_enabled) {
    allDataForMonth.value = [];
    updateFilterOptions();
    filterDetailRows();
    return;
  }

  // 2. 공유된 경우에만 performance_records_absorption 데이터 조회
  const { data, error } = await supabase
    .from('performance_records_absorption')
    .select(`
      *,
      clients ( name ),
      products ( product_name, insurance_code, price )
    `)
    .eq('settlement_month', selectedMonth.value)
    .eq('company_id', companyId.value);
  
  if (error) {
    allDataForMonth.value = [];
    return;
  }
  
  allDataForMonth.value = data.map(row => {
    const price = row.products?.price || 0;
    const prescriptionAmount = (row.prescription_qty || 0) * price;
    const paymentAmount = Math.round(prescriptionAmount * (row.commission_rate || 0));
    
    return {
      ...row,
      client_name: row.clients?.name || 'N/A',
      product_name_display: row.products?.product_name || 'N/A',
      insurance_code: row.products?.insurance_code || 'N/A',
      price: price,
      prescription_amount: prescriptionAmount,
      payment_amount: paymentAmount,
      commission_rate: `${((row.commission_rate || 0) * 100).toFixed(1)}%`,
    };
  });
  
  updateFilterOptions();
  filterDetailRows();
}

function updateFilterOptions() {
  if (allDataForMonth.value.length > 0) {
    availablePrescriptionMonths.value = [...new Set(allDataForMonth.value.map(r => r.prescription_month))].sort((a, b) => b.localeCompare(a));
    availableClients.value = [...new Set(allDataForMonth.value.map(r => r.client_name))].sort();
  } else {
    availablePrescriptionMonths.value = [];
    availableClients.value = [];
  }
}

function filterDetailRows() {
  let filtered = [...allDataForMonth.value];
  if (selectedPrescriptionMonth.value) {
    filtered = filtered.filter(row => row.prescription_month === selectedPrescriptionMonth.value);
  }
  if (selectedClient.value) {
    filtered = filtered.filter(row => row.client_name === selectedClient.value);
  }

  filtered.sort((a, b) => {
    // 1. 병의원명 가나다순
    const clientNameCompare = a.client_name.localeCompare(b.client_name, 'ko');
    if (clientNameCompare !== 0) return clientNameCompare;

    // 2. 제품명 가나다순
    const productNameCompare = a.product_name_display.localeCompare(b.product_name_display, 'ko');
    if (productNameCompare !== 0) return productNameCompare;

    // 3. 처방수량 높은 순
    const qtyA = Number(a.prescription_qty.toString().replace(/,/g, '')) || 0;
    const qtyB = Number(b.prescription_qty.toString().replace(/,/g, '')) || 0;
    return qtyB - qtyA;
  });

  detailRows.value = filtered.map(row => ({
    ...row,
    price: (row.price || 0).toLocaleString(),
    prescription_qty: (row.prescription_qty || 0).toLocaleString(),
    prescription_amount: (row.prescription_amount || 0).toLocaleString(),
    payment_amount: (row.payment_amount || 0).toLocaleString()
  }));
}

watch(selectedMonth, async () => {
  selectedPrescriptionMonth.value = '';
  selectedClient.value = '';
  await fetchAllDataForMonth();
});
watch([selectedPrescriptionMonth, selectedClient], filterDetailRows);

onMounted(async () => {
  await fetchCompanyId();
  await fetchAvailableMonths();
});

function downloadExcel() {
  if (!detailRows.value.length) return;
  const excelData = detailRows.value.map(row => ({
    '병의원명': row.client_name,
    '처방월': row.prescription_month,
    '제품명': row.product_name_display,
    '보험코드': row.insurance_code,
    '약가': Number(row.price?.toString().replace(/,/g, '')),
    '처방수량': Number(row.prescription_qty?.toString().replace(/,/g, '')),
    '처방액': Number(row.prescription_amount?.toString().replace(/,/g, '')),
    '수수료율(%)': Number(String(row.commission_rate).replace('%', '')) / 100,
    '지급액': Number(row.payment_amount?.toString().replace(/,/g, '')),
    '비고': row.remarks || '',
  }));

  const ws = XLSX.utils.json_to_sheet(excelData);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '정산내역서상세');

  ws['!cols'] = [ { wch: 18 }, { wch: 10 }, { wch: 20 }, { wch: 12 }, { wch: 12 }, { wch: 12 }, { wch: 12 }, { wch: 10 }, { wch: 12 }, { wch: 18 } ];
  
  const range = XLSX.utils.decode_range(ws['!ref']);
  for (let R = range.s.r + 1; R <= range.e.r; ++R) {
    const numberFormat = '#,##0';
    const percentFormat = '0.0%';

    // 약가, 처방수량, 처방액, 지급액 (E, F, G, I열)
    ['E', 'F', 'G', 'I'].forEach(col => {
      const cellAddress = `${col}${R + 1}`;
      if (ws[cellAddress]) ws[cellAddress].z = numberFormat;
    });
    
    // 수수료율 (H열)
    const commissionCell = `H${R + 1}`;
    if (ws[commissionCell]) ws[commissionCell].z = percentFormat;
  }

  const today = new Date().toISOString().split('T')[0];
  const fileName = `정산내역서상세_${selectedMonth.value || ''}_${today}.xlsx`;
  XLSX.writeFile(wb, fileName);
}
</script>

<style scoped>
.action-buttons-group {
    display: flex;
    gap: 8px;
}

</style>
