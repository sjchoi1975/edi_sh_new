<template>
  <div class="admin-settlement-share-view page-container" style="display: flex; flex-direction: column; height: 100vh;">
    <!-- <div class="page-breadcrumb">정산 관리 &gt; 정산내역서 공유</div> -->
    <div class="page-header-title-area" style="flex-shrink: 0;">
      <div class="header-title">정산내역서 공유</div>
    </div>
    <!-- 필터 카드 -->
    <div class="filter-card" style="flex-shrink: 0;">
      <div class="filter-row">
        <div style="display: flex; align-items: center; gap: 8px;">
          <label style="font-weight:400;">정산월</label>
          <select v-model="selectedMonth" class="select_month">
            <option v-for="month in availableMonths" :key="month" :value="month">{{ month }}</option>
          </select>
        </div>
      </div>
    </div>
    <!-- 데이터 카드 -->
    <div class="data-card" style="flex-grow: 1; display: flex; flex-direction: column; overflow: hidden;">
      <div class="data-card-header" style="flex-shrink: 0;">
        <div class="total-count-display">전체 {{ filteredCompanies.length }} 건</div>
        <div class="action-buttons-group">
          <button class="btn-select-all" @click="setAllShare(true)">전체 공유</button>
          <button class="btn-select-none" @click="setAllShare(false)">전체 해제</button>
          <button class="btn-save" :disabled="!hasShareChanges" @click="saveShareChanges">저장</button>
        </div>
      </div>
      <div style="flex-grow: 1; overflow: auto;">
      <DataTable 
        :value="filteredCompanies" 
        scrollable 
        scrollHeight="calc(100vh - 220px)"
        class="admin-settlement-share-table"
      >
        <template #empty>조회된 데이터가 없습니다.</template>
        <Column header="No" :headerStyle="{ width: columnWidths.no }">
          <template #body="slotProps">{{ slotProps.index + 1 }}</template>
        </Column>
        <Column field="company_group" header="구분" :headerStyle="{ width: columnWidths.company_group }" />
        <Column field="company_name" header="업체명" :headerStyle="{ width: columnWidths.company_name }" />
        <Column field="business_registration_number" header="사업자등록번호" :headerStyle="{ width: columnWidths.business_registration_number }" />
        <Column field="representative_name" header="대표자" :headerStyle="{ width: columnWidths.representative_name }" />
        <Column field="assigned_pharmacist_contact" header="관리자" :headerStyle="{ width: columnWidths.assigned_pharmacist_contact }" />
        <Column field="client_count" header="거래처수" :headerStyle="{ width: columnWidths.client_count }" />
        <Column field="prescription_count" header="처방건수" :headerStyle="{ width: columnWidths.prescription_count }" />
        <Column field="prescription_amount" header="처방액" :headerStyle="{ width: columnWidths.prescription_amount }" />
        <Column field="payment_amount" header="지급액" :headerStyle="{ width: columnWidths.payment_amount }" />
        <Column header="상세" :headerStyle="{ width: columnWidths.detail }">
          <template #body="slotProps">
            <button class="btn-detail" @click="goDetail(slotProps.data)">상세</button>
          </template>
        </Column>
        <Column field="share_enabled" header="공유" :headerStyle="{ width: columnWidths.share }">
          <template #body="slotProps">
            <input type="checkbox" v-model="slotProps.data.share_enabled" @change="onShareChange(slotProps.data)" class="share-checkbox" />
          </template>
        </Column>
        <ColumnGroup type="footer">
            <Row>
              <Column footer="합계" :colspan="6" footerClass="footer-cell" footerStyle="text-align:center !important;" />
              <Column :footer="totalClientCount" footerClass="footer-cell" footerStyle="text-align:center !important;" />
              <Column :footer="totalPrescriptionCount" footerClass="footer-cell" footerStyle="text-align:center !important;" />
              <Column :footer="totalPrescriptionAmount" footerClass="footer-cell" footerStyle="text-align:right !important;" />
              <Column :footer="totalPaymentAmount" footerClass="footer-cell" footerStyle="text-align:right !important;" />
              <Column :colspan="2" footerClass="footer-cell" />
            </Row>
          </ColumnGroup>
      </DataTable>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import ColumnGroup from 'primevue/columngroup';
import Row from 'primevue/row';
import { useRouter } from 'vue-router';
import { supabase } from '@/supabase';
import * as XLSX from 'xlsx';

const columnWidths = {
  no: '4%',
  company_group: '8%',
  company_name: '14%',
  business_registration_number: '10%',
  representative_name: '8%',
  assigned_pharmacist_contact: '8%',
  client_count: '8%',
  prescription_count: '8%',
  prescription_amount: '8%',
  payment_amount: '8%',
  detail: '8%',
  share: '8%'
};

const selectedMonth = ref('');
const availableMonths = ref([]);
const companies = ref([]);
const router = useRouter();

// 합계 계산
const totalClientCount = computed(() => {
  return companies.value.reduce((sum, company) => sum + (company.client_count || 0), 0);
});
const totalPrescriptionCount = computed(() => {
  return companies.value.reduce((sum, company) => sum + (company.prescription_count || 0), 0);
});
const totalPrescriptionAmount = computed(() => {
  const total = companies.value.reduce((sum, company) => sum + (Number(company.prescription_amount?.toString().replace(/,/g, '')) || 0), 0);
  return total.toLocaleString();
});
const totalPaymentAmount = computed(() => {
  const total = companies.value.reduce((sum, company) => sum + (Number(company.payment_amount?.toString().replace(/,/g, '')) || 0), 0);
  return total.toLocaleString();
});

// 업체명 → company_id(uuid) 매핑용
const companyNameToId = ref({});
// settlement_share 데이터 캐시
const shareMap = ref({});

// 정산월(흡수율 분석 데이터가 있는 월만)
async function fetchAvailableMonths() {
  const { data, error } = await supabase
    .from('absorption_analysis')
    .select('settlement_month')
    .neq('settlement_month', null);
  if (!error && data) {
    const months = Array.from(new Set(data.map(d => d.settlement_month))).sort((a, b) => b.localeCompare(a));
    availableMonths.value = months;
    if (months.length > 0) selectedMonth.value = months[0];
  }
}

// 업체명→id 매핑, settlement_share 데이터 미리 불러오기
async function fetchCompanyIdAndShare() {
  // 1. 업체명 목록
  const { data: aaData } = await supabase
    .from('absorption_analysis')
    .select('company_name')
    .eq('settlement_month', selectedMonth.value);
  const companyNames = Array.from(new Set((aaData || []).map(r => r.company_name)));
  // 2. companies에서 id 매핑
  const { data: compData } = await supabase
    .from('companies')
    .select('id, company_name');
  const nameToId = {};
  (compData || []).forEach(c => { nameToId[c.company_name] = c.id; });
  companyNameToId.value = nameToId;
  // 3. settlement_share에서 공유여부
  const { data: shareData } = await supabase
    .from('settlement_share')
    .select('settlement_month, company_id, share_enabled');
  const map = {};
  (shareData || []).forEach(s => {
    map[`${s.settlement_month}_${s.company_id}`] = s.share_enabled;
  });
  shareMap.value = map;
}

// 업체별 집계 데이터
async function fetchCompanies() {
  if (!selectedMonth.value) return;
  await fetchCompanyIdAndShare();
  const { data, error } = await supabase
    .from('absorption_analysis')
    .select('*')
    .eq('settlement_month', selectedMonth.value);
  if (!error && data) {
    // 업체별 집계(처방건수, 처방액, 지급액 등)
    const grouped = {};
    data.forEach(row => {
      if (!grouped[row.company_name]) {
        const cid = companyNameToId.value[row.company_name] || null;
        const shareKey = `${selectedMonth.value}_${cid}`;
        grouped[row.company_name] = {
          company_group: row.company_group,
          company_name: row.company_name,
          business_registration_number: row.business_registration_number || '',
          representative_name: row.representative_name || '',
          assigned_pharmacist_contact: row.assigned_pharmacist_contact,
          client_names: new Set(),
          prescription_count: 0,
          prescription_amount: 0,
          payment_amount: 0,
          share_enabled: shareMap.value[shareKey] || false,
          company_id: cid,
        };
      }
      grouped[row.company_name].business_registration_number = row.business_registration_number || grouped[row.company_name].business_registration_number;
      grouped[row.company_name].representative_name = row.representative_name || grouped[row.company_name].representative_name;
      grouped[row.company_name].client_names.add(row.client_name);
      grouped[row.company_name].prescription_count += 1;
      grouped[row.company_name].prescription_amount += Number(row.prescription_amount || 0);
      grouped[row.company_name].payment_amount += Number(row.payment_amount || 0);
    });
    companies.value = Object.values(grouped).map(c => ({
      ...c,
      client_count: c.client_names.size,
      prescription_amount: c.prescription_amount.toLocaleString(),
      payment_amount: c.payment_amount.toLocaleString(),
    }));
  }
}

onMounted(async () => {
  await fetchAvailableMonths();
  await fetchCompanies();
});

watch(selectedMonth, fetchCompanies);

const filteredCompanies = computed(() => companies.value);

function goDetail(row) {
  router.push({ name: 'AdminSettlementShareDetail', query: { month: selectedMonth.value, company: row.company_name } });
}

// function downloadExcel() {
//   console.log('엑셀 데이터:', filteredCompanies.value);
//   if (!filteredCompanies.value.length) {
//     alert('다운로드할 데이터가 없습니다.');
//     return;
//   }
//   const excelData = filteredCompanies.value.map(row => ({
//     구분: row.company_group,
//     업체명: row.company_name,
//     사업자등록번호: row.business_registration_number,
//     대표자: row.representative_name,
//     관리자: row.assigned_pharmacist_contact,
//     거래처수: Number(row.client_count) || 0,
//     처방건수: Number(row.prescription_count) || 0,
//     처방액: Number(row.prescription_amount?.toString().replace(/,/g, '')) || 0,
//     지급액: Number(row.payment_amount?.toString().replace(/,/g, '')) || 0,
//     공유: row.share_enabled ? '공유' : '비공유',
//   }));
//   const ws = XLSX.utils.json_to_sheet(excelData);
//   const wb = XLSX.utils.book_new();
//   XLSX.utils.book_append_sheet(wb, ws, '정산내역서목록');
//   ws['!cols'] = [
//     { width: 10 }, { width: 18 }, { width: 14 }, { width: 10 }, { width: 10 }, { width: 8 }, { width: 8 }, { width: 12 }, { width: 12 }, { width: 8 }
//   ];
//   // 숫자 셀 서식 적용 (거래처수, 처방건수, 처방액, 지급액)
//   const numCols = [5, 6, 7, 8]; // F~I
//   const range = XLSX.utils.decode_range(ws['!ref']);
//   for (let row = 1; row <= range.e.r; row++) {
//     numCols.forEach(col => {
//       const cell = ws[XLSX.utils.encode_cell({ r: row, c: col })];
//       if (cell) cell.z = '#,##0';
//     });
//   }
//   const today = new Date().toISOString().split('T')[0];
//   const fileName = `정산내역서목록_${today}.xlsx`;
//   XLSX.writeFile(wb, fileName);
// }

// function downloadCompanyExcel(row) {
//   // 업체별 엑셀 다운로드 구현
// }

// 공유 변경사항 임시 저장용
const shareChanges = ref({});
const hasShareChanges = computed(() => Object.keys(shareChanges.value).length > 0);

function onShareChange(row) {
  if (!row.company_id) {
    alert('업체 정보가 없습니다.');
    return;
  }
  const key = `${selectedMonth.value}_${row.company_id}`;
  shareChanges.value[key] = {
    settlement_month: selectedMonth.value,
    company_id: row.company_id,
    share_enabled: row.share_enabled
  };
}

async function saveShareChanges() {
  const changes = Object.values(shareChanges.value);
  for (const change of changes) {
    // settlement_share에 이미 있으면 update, 없으면 insert
    const { data: exist } = await supabase
      .from('settlement_share')
      .select('id')
      .eq('settlement_month', change.settlement_month)
      .eq('company_id', change.company_id)
      .maybeSingle();
    if (exist && exist.id) {
      await supabase.from('settlement_share')
        .update({ share_enabled: change.share_enabled })
        .eq('id', exist.id);
    } else {
      await supabase.from('settlement_share')
        .insert({
          settlement_month: change.settlement_month,
          company_id: change.company_id,
          share_enabled: change.share_enabled
        });
    }
  }
  shareChanges.value = {};
  alert('공유 변경사항이 저장되었습니다.');
  await fetchCompanies();
}

// 전체 공유/전체 해제 기능
async function setAllShare(flag) {
  // 화면 데이터 먼저 반영
  companies.value.forEach(c => {
    c.share_enabled = flag;
    // 변경사항 무조건 추가
    if (c.company_id) {
      const key = `${selectedMonth.value}_${c.company_id}`;
      shareChanges.value[key] = {
        settlement_month: selectedMonth.value,
        company_id: c.company_id,
        share_enabled: flag
      };
    }
  });
  // DB 일괄 업데이트는 저장 버튼에서만 처리
}
</script>
