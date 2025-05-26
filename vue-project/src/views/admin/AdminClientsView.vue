<template>
  <div class="admin-clients-view">
    <div class="header-title">거래처 목록</div>
    <div class="table-container">
      <div class="table-header">
        <span class="p-input-icon-left">
          <InputText
            v-model="filters['global'].value"
            placeholder="거래처코드, 병의원명, 사업자등록번호 검색"
            class="search-input"
          />
        </span>
        <button class="btn-primary" @click="goCreate">등록</button>
      </div>
      <DataTable
        :value="clients"
        paginator
        :rows="20"
        :rowsPerPageOptions="[20, 50, 100]"
        scrollable
        scrollHeight="680px"
        v-model:filters="filters"
        :globalFilterFields="['client_code', 'name', 'business_registration_number']"
        class="custom-table"
      >
        <template #empty>등록된 거래처가 없습니다.</template>
        <template #loading>거래처 목록을 불러오는 중입니다...</template>
        <Column field="client_code" header="거래처코드" :headerStyle="{ width: '8%' }" :sortable="true" />
        <Column field="name" header="병의원명" :headerStyle="{ width: '16%' }" :sortable="true">
          <template #body="slotProps">
            <a
              href="#"
              style="color:#1976d2;text-decoration:underline;cursor:pointer;"
              @click.prevent="goToDetail(slotProps.data.id)"
            >
              {{ slotProps.data.name }}
            </a>
          </template>
        </Column>
        <Column field="business_registration_number" header="사업자등록번호" :headerStyle="{ width: '8%' }" :sortable="true" />
        <Column field="owner_name" header="원장명" :headerStyle="{ width: '8%' }" :sortable="true" />
        <Column field="address" header="주소" :headerStyle="{ width: '36%' }" :sortable="true" />
        <Column field="remarks" header="비고" :headerStyle="{ width: '16%' }" :sortable="true" />
        <Column field="status" header="상태" :headerStyle="{ width: '8%' }" :sortable="true">
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

const clients = ref([]);
const filters = ref({ 'global': { value: null, matchMode: 'contains' } });
const router = useRouter();

function goCreate() {
  router.push('/admin/clients/create');
}
function goToDetail(id) {
  router.push(`/admin/clients/${id}`);
}

const fetchClients = async () => {
  const { data, error } = await supabase
    .from('clients')
    .select('*')
    .order('client_code', { ascending: true });
  if (!error && data) {
    clients.value = data;
  }
};

onMounted(() => {
  fetchClients();
});
</script> 