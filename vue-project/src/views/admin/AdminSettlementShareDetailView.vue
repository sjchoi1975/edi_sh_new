<template>
  <div class="admin-settlement-share-detail-view page-container" style="display: flex; flex-direction: column; height: 100vh;">
    <!-- 상단 필터카드 -->
    <div class="filter-card" style="display: flex; align-items: center; gap: 0.5rem; margin-bottom:0rem; padding:0.25rem 1.5rem 0.25rem 1rem !important;">
      <Button icon="pi pi-arrow-left" severity="secondary" text rounded @click="goBack" />
      <div>
        <div style="font-size:1.2rem; font-weight:700;">{{ companyInfo.company_name }}</div>
        <div style="font-size:0.95rem; color:#555;">
          {{ companyInfo.business_registration_number }} / {{ companyInfo.representative_name }} / {{ companyInfo.business_address }}
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
      <div style="flex-grow: 1; overflow: auto;">
      <DataTable 
        :value="detailRows" 
        :loading="loading"
        scrollable 
        scrollHeight="calc(100vh - 220px)"
        class="admin-settlement-share-detail-table">
        <template #empty>
          <div v-if="!loading">조회된 데이터가 없습니다.</div>
        </template>
        <template #loading>정산 상세 데이터를 불러오는 중입니다...</template>
        <Column header="No" :headerStyle="{ width: columnWidths.no }">
          <template #body="slotProps">{{ slotProps.index + 1 }}</template>
        </Column>
        <Column field="client_name" header="거래처명" :headerStyle="{ width: columnWidths.client_name }" :sortable="true" />
        <Column field="prescription_month" header="처방월" :headerStyle="{ width: columnWidths.prescription_month }" :sortable="true" />
        <Column field="product_name" header="제품명" :headerStyle="{ width: columnWidths.product_name }" :sortable="true" />
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
              <Column footer="" footerClass="footer-cell" />
              <Column :footer="totalPaymentAmount" footerClass="footer-cell" footerStyle="text-align:right !important;" />
              <Column footer="" footerClass="footer-cell" />
            </Row>
          </ColumnGroup>
      </DataTable>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Button from 'primevue/button';
import ColumnGroup from 'primevue/columngroup';
import Row from 'primevue/row';
import { useRoute, useRouter } from 'vue-router';
import { supabase } from '@/supabase';
import * as XLSX from 'xlsx';

const route = useRoute();
const router = useRouter();
const month = route.query.month;
const companyName = route.query.company;
const companyInfo = ref({ company_name: '', business_registration_number: '', representative_name: '', business_address: '' });
const detailRows = ref([]);
const loading = ref(false);

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
  client_name: '16%',
  prescription_month: '6%',
  product_name: '16%',
  insurance_code: '7%',
  price: '7%',
  prescription_qty: '7%',
  prescription_amount: '7%',
  commission_rate: '7%',
  payment_amount: '7%',
  remarks: '16%'
};

async function fetchCompanyInfo() {
  if (!companyName) return;
  const { data, error } = await supabase
    .from('companies')
    .select('company_name, business_registration_number, representative_name, business_address')
    .eq('company_name', companyName)
    .single();
  if (!error && data) {
    companyInfo.value = data;
  } else if (error) {
    console.error("Failed to fetch company info:", error);
  }
}

async function fetchDetailRows() {
  loading.value = true;
  try {
    const { data, error } = await supabase
      .from('absorption_analysis')
      .select('*')
      .eq('settlement_month', month)
      .eq('company_name', companyName);
    if (!error && data) {
      detailRows.value = data.map(row => ({
        ...row,
        price: row.price?.toLocaleString() || '',
        prescription_qty: row.prescription_qty?.toLocaleString() || '',
        prescription_amount: row.prescription_amount?.toLocaleString() || '',
        payment_amount: row.payment_amount?.toLocaleString() || '',
        commission_rate: row.commission_rate ? row.commission_rate : '',
      }));
    }
  } catch (err) {
    console.error('상세 데이터 조회 오류:', err);
    detailRows.value = [];
  } finally {
    loading.value = false;
  }
}

function goBack() {
  router.push('/admin/settlement-share');
}

onMounted(async () => {
  await fetchCompanyInfo();
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
  const fileName = `정산내역서상세_${companyInfo.value.company_name || ''}_${today}.xlsx`;
  XLSX.writeFile(wb, fileName);
}
</script>
