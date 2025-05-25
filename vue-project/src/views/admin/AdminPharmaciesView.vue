<template>
  <div class="admin-clients-view">
    <div class="header-title">문전약국 목록</div>
    <div class="table-container">
      <div class="table-header">
        <span class="p-input-icon-left">
          <InputText v-model="filters['global'].value" placeholder="약국코드, 약국명, 사업자등록번호 검색" style="width: 280px" />
        </span>
        <button class="btn-primary" @click="goCreate">등록</button>
      </div>
      <DataTable
        :value="pharmacies"
        paginator
        :rows="20"
        :rowsPerPageOptions="[20, 50, 100]"
        scrollable
        scrollHeight="680px"
        v-model:filters="filters"
        :globalFilterFields="['pharmacy_code', 'name', 'business_registration_number']"
        class="custom-table"
      >
        <template #empty>등록된 약국이 없습니다.</template>
        <template #loading>약국 목록을 불러오는 중입니다...</template>
        <Column field="pharmacy_code" header="약국코드" :headerStyle="{ width: '12%' }" />
        <Column field="name" header="약국명" :headerStyle="{ width: '16%' }">
          <template #body="slotProps">
            <a href="#" class="company-link" @click.prevent="goToDetail(slotProps.data)">{{ slotProps.data.name }}</a>
          </template>
        </Column>
        <Column field="business_registration_number" header="사업자등록번호" :headerStyle="{ width: '14%' }" />
        <Column field="address" header="주소" :headerStyle="{ width: '20%' }" />
        <Column field="remarks" header="비고" :headerStyle="{ width: '16%' }" />
        <Column field="status" header="상태" :headerStyle="{ width: '8%' }">
          <template #body="slotProps">
            {{ slotProps.data.status === 'active' ? '활성' : '비활성' }}
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
import InputText from 'primevue/inputtext';
import { useRouter } from 'vue-router';
import { supabase } from '@/supabase';

const pharmacies = ref([]);
const filters = ref({ 'global': { value: null, matchMode: 'contains' } });
const router = useRouter();

function goCreate() {
  router.push('/admin/pharmacies/create');
}
function goToDetail(pharmacy) {
  router.push(`/admin/pharmacies/${pharmacy.id}`);
}

const fetchPharmacies = async () => {
  const { data, error } = await supabase
    .from('pharmacies')
    .select('*')
    .order('pharmacy_code', { ascending: true });
  if (!error && data) {
    pharmacies.value = data;
  }
};

onMounted(() => {
  fetchPharmacies();
});
</script> 