<template>
  <div class="admin-revenue-view">
    <div class="header-title">도매매출 목록</div>
    <div class="table-container">
      <div class="table-header">
        <span class="p-input-icon-left">
          <InputText
                v-model="filters['global'].value"
                placeholder="약국명, 사업자등록번호, 표준코드, 제품명 검색"
                class="search-input"
              />
        </span>
        <button class="btn-primary" @click="goCreate">등록</button>
      </div>
      <DataTable
        :value="revenues"
        paginator
        :rows="20"
        :rowsPerPageOptions="[20, 50, 100]"
        scrollable
        scrollHeight="680px"
        v-model:filters="filters"
        :globalFilterFields="['pharmacy_name', 'business_registration_number', 'standard_code', 'product_name']"
        class="custom-table"
      >
        <template #empty>등록된 매출이 없습니다.</template>
        <template #loading>매출 목록을 불러오는 중입니다...</template>
        <Column field="pharmacy_code" header="약국코드" :headerStyle="{ width: '10%' }" />
        <Column field="pharmacy_name" header="약국명" :headerStyle="{ width: '14%' }" />
        <Column field="business_registration_number" header="사업자번호" :headerStyle="{ width: '13%' }" />
        <Column field="address" header="주소" :headerStyle="{ width: '18%' }" />
        <Column field="standard_code" header="표준코드" :headerStyle="{ width: '10%' }" />
        <Column field="product_name" header="제품명" :headerStyle="{ width: '13%' }" />
        <Column field="sales_amount" header="매출액" :headerStyle="{ width: '10%' }">
          <template #body="slotProps">
            {{ slotProps.data.sales_amount?.toLocaleString() }}
          </template>
        </Column>
        <Column field="sales_date" header="매출일자" :headerStyle="{ width: '12%' }" />
      </DataTable>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import InputText from 'primevue/inputtext';
import { useRouter } from 'vue-router';
import { supabase } from '@/supabase';

const revenues = ref([]);
const filters = ref({ 'global': { value: null, matchMode: 'contains' } });
const router = useRouter();

function goCreate() {
  router.push('/admin/wholesale-revenue/create');
}

const fetchRevenues = async () => {
  const { data, error } = await supabase
    .from('wholesale_sales')
    .select('*')
    .order('sales_date', { ascending: false });
  if (!error && data) {
    revenues.value = data;
  }
};

onMounted(() => {
  fetchRevenues();
});
</script> 