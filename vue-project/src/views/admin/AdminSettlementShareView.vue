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
          <label>정산월</label>
          <select v-model="selectedMonth" @change="loadSettlementData" class="select_month">
            <option v-for="month in availableMonths" :key="month.settlement_month" :value="month.settlement_month">{{ month.settlement_month }}</option>
          </select>
        </div>
      </div>
    </div>
    <!-- 데이터 카드 -->
    <div class="data-card" style="flex-grow: 1; display: flex; flex-direction: column; overflow: hidden;">
      <div class="data-card-header" style="flex-shrink: 0;">
        <div class="total-count-display">전체 {{ companySummary.length }} 건</div>
        <div class="action-buttons-group">
          <button class="btn-secondary" @click="toggleAllShares(true)">전체 공유</button>
          <button class="btn-secondary" @click="toggleAllShares(false)">전체 해제</button>
          <button class="btn-save" @click="saveShareStatus" :disabled="Object.keys(shareChanges).length === 0">저장</button>
        </div>
      </div>
      <div style="flex-grow: 1; overflow: auto;">
      <DataTable 
        :value="companySummary" 
        :loading="loading"
        scrollable 
        scrollHeight="calc(100vh - 220px)"
        class="admin-settlement-share-table"
      >
        <template #empty>
          <div v-if="!loading">조회된 데이터가 없습니다.</div>
        </template>
        <template #loading>정산내역서를 불러오는 중입니다...</template>

        <Column header="No" :headerStyle="{ width: columnWidths.no }">
          <template #body="slotProps">{{ slotProps.index + 1 }}</template>
        </Column>
        <Column field="company_type" header="구분" :headerStyle="{ width: columnWidths.company_type }" :sortable="true"/>
        <Column field="company_name" header="업체명" :headerStyle="{ width: columnWidths.company_name }" :sortable="true"/>
        <Column field="business_registration_number" header="사업자등록번호" :headerStyle="{ width: columnWidths.business_registration_number }" :sortable="true"/>
        <Column field="representative_name" header="대표자" :headerStyle="{ width: columnWidths.representative_name }" :sortable="true"/>
        <Column field="manager_name" header="관리자" :headerStyle="{ width: columnWidths.manager_name }" :sortable="true"/>
        <Column field="client_count" header="병의원 수" :headerStyle="{ width: columnWidths.client_count }" :sortable="true"/>
        <Column field="prescription_count" header="처방건수" :headerStyle="{ width: columnWidths.prescription_count }" :sortable="true"/>
        <Column field="total_prescription_amount" header="총 처방액" :headerStyle="{ width: columnWidths.total_prescription_amount }" :sortable="true">
            <template #body="slotProps">{{ slotProps.data.total_prescription_amount.toLocaleString() }}</template>
        </Column>
        <Column field="total_payment_amount" header="총 지급액" :headerStyle="{ width: columnWidths.total_payment_amount }" :sortable="true">
            <template #body="slotProps">{{ slotProps.data.total_payment_amount.toLocaleString() }}</template>
        </Column>
        <Column header="상세" :headerStyle="{ width: columnWidths.detail }">
          <template #body="slotProps">
            <button class="btn-detail" @click="goDetail(slotProps.data)">상세</button>
          </template>
        </Column>
        <Column header="공유" :headerStyle="{ width: columnWidths.share }">
          <template #body="slotProps">
            <input type="checkbox" v-model="slotProps.data.is_shared" @change="onShareChange(slotProps.data)" class="share-checkbox" />
          </template>
        </Column>
        <ColumnGroup type="footer">
          <Row>
            <Column footer="합계" :colspan="8" footerClass="footer-cell" footerStyle="text-align:center !important;" />
            <Column :footer="totalPrescriptionAmount"footerClass="footer-cell" footerStyle="text-align:right !important;" />
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
import { ref, onMounted, watch, computed } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import ColumnGroup from 'primevue/columngroup';
import Row from 'primevue/row';
import { useRouter, onBeforeRouteLeave } from 'vue-router';
import { supabase } from '@/supabase';

const columnWidths = {
  no: '4%',
  company_type: '8%',
  company_name: '14%',
  business_registration_number: '10%',
  representative_name: '8%',
  manager_name: '8%',
  client_count: '9%',
  prescription_count: '9%',
  total_prescription_amount: '9%',
  total_payment_amount: '9%',
  detail: '6%',
  share: '6%'
};

const loading = ref(false);
const router = useRouter();

// 필터
const selectedMonth = ref('');
const availableMonths = ref([]);

// 데이터
const companySummary = ref([]);
const shareChanges = ref({}); // 공유 상태 변경 사항 추적

// --- 계산된 속성 (합계) ---
const totalPrescriptionAmount = computed(() => {
    const total = companySummary.value.reduce((sum, item) => sum + Number(item.total_prescription_amount || 0), 0);
    return total.toLocaleString();
});

const totalPaymentAmount = computed(() => {
    const total = companySummary.value.reduce((sum, item) => sum + Number(item.total_payment_amount || 0), 0);
    return Math.round(total).toLocaleString();
});


// --- 초기 데이터 로딩 ---

onMounted(async () => {
  await fetchAvailableMonths();
});

watch(selectedMonth, async (newMonth) => {
  if(newMonth) {
    await loadSettlementData();
  }
});

async function fetchAvailableMonths() {
    try {
        const { data, error } = await supabase
            .from('review_details_view')
            .select('settlement_month', { distinct: true })
            .eq('user_edit_status', '완료');
            
        if (error) throw error;
        
        const months = data.map(item => ({ settlement_month: item.settlement_month }));
        months.sort((a, b) => b.settlement_month.localeCompare(a.settlement_month));
        
        availableMonths.value = months;

        if (months.length > 0) {
            selectedMonth.value = months[0].settlement_month;
        } else {
            // 데이터가 없을 경우에 대한 처리
            companySummary.value = [];
        }
    } catch (err) {
        console.error('정산월 조회 오류', err);
        alert('정산월 목록을 불러오는 중 오류가 발생했습니다.');
    }
}

async function loadSettlementData() {
    if (!selectedMonth.value) return;
    loading.value = true;
    shareChanges.value = {};
    
    try {
        const { data: summaryData, error } = await supabase.rpc('get_settlement_summary_by_company', {
            p_settlement_month: selectedMonth.value
        });
        
        if (error) throw error;

        companySummary.value = summaryData.sort((a,b) => {
          if (b.total_payment_amount !== a.total_payment_amount) {
            return b.total_payment_amount - a.total_payment_amount;
          }
          return a.company_name.localeCompare(b.company_name, 'ko');
        });
        
    } catch (err) {
        console.error('정산 공유 데이터 로드 오류:', err);
        alert('데이터를 불러오는 중 오류가 발생했습니다.');
    } finally {
        loading.value = false;
    }
}

function onShareChange(companyData) {
    shareChanges.value[companyData.company_id] = {
      is_shared: companyData.is_shared,
      id: companyData.settlement_share_id
    };
}

// 전체 공유/해제
function toggleAllShares(share) {
  companySummary.value.forEach(company => {
    company.is_shared = share;
    onShareChange(company);
  });
}

async function saveShareStatus() {
    if (Object.keys(shareChanges.value).length === 0) {
        alert('변경사항이 없습니다.');
        return;
    }

    loading.value = true;
    
    const recordsToInsert = [];
    const recordsToUpdate = [];

    for (const companyId in shareChanges.value) {
        const change = shareChanges.value[companyId];
        if (change.id) { // ID가 있으면 업데이트
            recordsToUpdate.push({
                id: change.id,
                share_enabled: change.is_shared
            });
        } else { // ID가 없으면 삽입
            recordsToInsert.push({
                settlement_month: selectedMonth.value,
                company_id: companyId,
                share_enabled: change.is_shared,
            });
        }
    }

    try {
        const promises = [];
        if (recordsToInsert.length > 0) {
            promises.push(supabase.from('settlement_share').insert(recordsToInsert));
        }
        if (recordsToUpdate.length > 0) {
            const updatePromises = recordsToUpdate.map(record => 
                supabase.from('settlement_share').update({ share_enabled: record.share_enabled }).eq('id', record.id)
            );
            promises.push(...updatePromises);
        }

        const results = await Promise.all(promises);
        
        results.forEach(res => {
            if (res.error) throw res.error;
        });

        shareChanges.value = {};
        alert('공유 상태가 성공적으로 저장되었습니다.');
        await loadSettlementData();

    } catch (err) {
        console.error('공유 상태 저장 오류:', err);
        alert('공유 상태 저장 중 오류가 발생했습니다.');
    } finally {
        loading.value = false;
    }
}

function goDetail(companyData) {
  router.push({ 
      name: 'AdminSettlementShareDetail', 
      query: { month: selectedMonth.value, company_id: companyData.company_id } 
  });
}

onBeforeRouteLeave((to, from, next) => {
  if (Object.keys(shareChanges.value).length > 0) {
    if (confirm('저장하지 않은 변경사항이 있습니다. 페이지를 떠나시겠습니까?')) {
      next();
    } else {
      next(false);
    }
  } else {
    next();
  }
});

function formatDateTime(dateTimeString) {
  if (!dateTimeString) return '-';
  const date = new Date(dateTimeString);
  const kstOffset = 9 * 60 * 60 * 1000;
  const kstDate = new Date(date.getTime() + kstOffset);
  return kstDate.toISOString().slice(0, 16).replace('T', ' ');
}

</script>

<style scoped>
.action-buttons-group {
    display: flex;
    gap: 8px;
}
</style>
