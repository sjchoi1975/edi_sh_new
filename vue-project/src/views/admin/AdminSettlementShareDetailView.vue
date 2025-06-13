<template>
  <div class="admin-settlement-share-detail-view page-container" style="display: flex; flex-direction: column; height: 100vh;">
    <!-- 상단 필터카드 -->
    <div class="filter-card" style="display: flex; align-items: center; gap: 0.5rem; margin-bottom:0rem; padding:0.15rem 1.5rem 0.15rem 1rem !important;">
      <Button icon="pi pi-arrow-left" severity="secondary" text rounded @click="goBack" />
      <div>
        <div style="font-size:1.1rem; font-weight:700;">{{ companyInfo.company_name }}</div>
        <div style="font-size:0.88rem; color:#444;">
          {{ companyInfo.business_registration_number }} / {{ companyInfo.representative_name }} / {{ companyInfo.business_address }}
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
        <Column field="product_name_display" header="제품명" :headerStyle="{ width: columnWidths.product_name_display }" :sortable="true" />
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
const month = ref(route.query.month);
const companyId = ref(route.query.company_id);

const companyInfo = ref({});
const detailRows = ref([]);
const loading = ref(false);

const columnWidths = {
  no: '4%',
  client_name: '18%',
  prescription_month: '6%',
  product_name_display: '16%',
  insurance_code: '7%',
  price: '7%',
  prescription_qty: '7%',
  prescription_amount: '7%',
  commission_rate: '7%',
  payment_amount: '7%',
  remarks: '14%'
};

onMounted(async () => {
  await loadDetailData();
});

async function loadDetailData() {
  if (!month.value || !companyId.value) return;
  loading.value = true;
  try {
    // 1. 상세 데이터 조회 (RPC 사용)
    const { data, error } = await supabase.rpc('get_absorption_analysis_details', {
        p_settlement_month: month.value,
        p_company_id: companyId.value,
        p_client_id: null,
        p_prescription_month: null
    });
    if (error) throw error;
    
    // 2. 데이터 가공
    detailRows.value = data.map(row => ({
      ...row,
      price: row.price.toLocaleString(),
      prescription_qty: row.prescription_qty.toLocaleString(),
      prescription_amount: row.prescription_amount.toLocaleString(),
      commission_rate: `${(row.commission_rate * 100).toFixed(2)}%`,
      payment_amount: row.payment_amount.toLocaleString(),
    }));

    // 3. 업체 정보 설정 (주소 필드 추가)
    if (data.length > 0) {
      const { data: cInfo, error: cError } = await supabase
        .from('companies')
        .select('company_name, business_registration_number, representative_name, business_address')
        .eq('id', companyId.value)
        .single();
      if(cError) throw cError;
      companyInfo.value = cInfo;
    }

  } catch (err) {
    console.error('상세 데이터 조회 오류:', err);
    alert('상세 데이터를 불러오는 중 오류가 발생했습니다.');
    detailRows.value = [];
  } finally {
    loading.value = false;
  }
}

// 합계 계산
const totalQty = computed(() => {
  return detailRows.value.reduce((sum, row) => sum + Number(String(row.prescription_qty).replace(/,/g, '')), 0).toLocaleString();
});
const totalPrescriptionAmount = computed(() => {
  return detailRows.value.reduce((sum, row) => sum + Number(String(row.prescription_amount).replace(/,/g, '')), 0).toLocaleString();
});
const totalPaymentAmount = computed(() => {
  return detailRows.value.reduce((sum, row) => sum + Number(String(row.payment_amount).replace(/,/g, '')), 0).toLocaleString();
});

const settlementSummary = computed(() => {
  const totalPrice = detailRows.value.reduce((sum, row) => {
    return sum + (parseFloat(row.payment_amount?.toString().replace(/,/g, '')) || 0);
  }, 0);

  const supplyPrice = Math.round(totalPrice / 1.1);
  const vatPrice = Math.round(totalPrice - supplyPrice);

  return {
    total_price: Math.round(totalPrice),
    supply_price: supplyPrice,
    vat_price: vatPrice,
  };
});

function goBack() {
  router.push('/admin/settlement-share');
}

function downloadExcel() {
  if (detailRows.value.length === 0) {
    alert('다운로드할 데이터가 없습니다.');
    return;
  }
  const excelData = detailRows.value.map(row => ({
    '거래처명': row.client_name,
    '처방월': row.prescription_month,
    '제품명': row.product_name_display,
    '보험코드': row.insurance_code,
    '약가': Number(String(row.price).replace(/,/g, '')),
    '처방수량': Number(String(row.prescription_qty).replace(/,/g, '')),
    '처방액': Number(String(row.prescription_amount).replace(/,/g, '')),
    '수수료율(%)': Number(String(row.commission_rate).replace('%', '')) / 100,
    '지급액': Number(String(row.payment_amount).replace(/,/g, '')),
    '비고': row.remarks || '',
  }));
  const ws = XLSX.utils.json_to_sheet(excelData);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '정산내역서상세');

  ws['!cols'] = [ { wch: 20 }, { wch: 10 }, { wch: 25 }, { wch: 12 }, { wch: 10 }, { wch: 10 }, { wch: 12 }, { wch: 10 }, { wch: 12 }, { wch: 20 }];
  
  const range = XLSX.utils.decode_range(ws['!ref']);
  for (let R = range.s.r + 1; R <= range.e.r; ++R) {
    ws[XLSX.utils.encode_cell({c: 4, r: R})].z = '#,##0';
    ws[XLSX.utils.encode_cell({c: 5, r: R})].z = '#,##0';
    ws[XLSX.utils.encode_cell({c: 6, r: R})].z = '#,##0';
    ws[XLSX.utils.encode_cell({c: 7, r: R})].z = '0.00%';
    ws[XLSX.utils.encode_cell({c: 8, r: R})].z = '#,##0.0';
  }

  const today = new Date().toISOString().split('T')[0];
  const fileName = `정산내역서상세_${companyInfo.value.company_name || ''}_${month.value}_${today}.xlsx`;
  XLSX.writeFile(wb, fileName);
}
</script>
