<template>
  <div class="admin-settlement-months-view">
    <div class="header-title">정산월 관리</div>
    <div class="table-container">
      <div class="table-header">
        <button class="btn-primary" @click="goCreate">등록</button>
      </div>
      <DataTable
        :value="settlementMonths"
        paginator
        :rows="20"
        :rowsPerPageOptions="[20, 50, 100]"
        scrollable
        scrollHeight="680px"
        class="custom-table"
        v-model:first="currentPageFirstIndex"
      >
        <template #empty>등록된 정산월이 없습니다.</template>
        <template #loading>정산월 목록을 불러오는 중입니다...</template>
        <Column header="No" :headerStyle="{ width: '6%' }">
          <template #body="slotProps">
            {{ slotProps.index + currentPageFirstIndex + 1 }}
          </template>
        </Column>
        <Column field="settlement_month" header="정산월" :headerStyle="{ width: '8%' }" :sortable="true">
          <template #body="slotProps">
            <a
              href="#"
              style="color:#1976d2;text-decoration:underline;cursor:pointer;"
              @click.prevent="goToDetail(slotProps.data.id)"
            >
              {{ slotProps.data.settlement_month }}
            </a>
          </template>
        </Column>
        <Column field="start_date" header="실적입력 시작일" :headerStyle="{ width: '10%' }" />
        <Column field="end_date" header="실적입력 종료일" :headerStyle="{ width: '10%' }" />
        <Column field="notice" header="전달 사항" :headerStyle="{ width: '38%' }" />
        <Column field="remarks" header="비고" :headerStyle="{ width: '20%' }" />
        <Column field="status" header="상태" :headerStyle="{ width: '10%' }">
          <template #body="slotProps">
            <span :class="slotProps.data.status === 'active' ? 'active-badge' : 'inactive-badge'">
              {{ slotProps.data.status === 'active' ? '활성' : '비활성' }}
            </span>
          </template>
        </Column>
      </DataTable>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import { useRouter } from 'vue-router';
import { supabase } from '@/supabase';

const settlementMonths = ref([]);
const router = useRouter();
const currentPageFirstIndex = ref(0);

function goCreate() {
  router.push('/admin/settlement-months/create');
}

function goToDetail(id) {
  router.push(`/admin/settlement-months/${id}`);
}

const fetchSettlementMonths = async () => {
  const { data, error } = await supabase
    .from('settlement_months')
    .select('*')
    .order('settlement_month', { ascending: false });
  if (!error && data) {
    settlementMonths.value = data;
  }
};

onMounted(() => {
  fetchSettlementMonths();
});
</script> 