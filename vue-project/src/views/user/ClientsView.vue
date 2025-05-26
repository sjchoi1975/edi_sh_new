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
        <Column field="name" header="병의원명" :headerStyle="{ width: '20%' }" :sortable="true">
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
        <Column field="address" header="주소" :headerStyle="{ width: '40%' }" :sortable="true" />
        <Column field="remarks" header="비고" :headerStyle="{ width: '16%' }" :sortable="true" />
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

function goToDetail(id) {
  router.push(`/clients/${id}`);
}

const fetchClients = async () => {
  // 1. 로그인한 사용자의 UID
  const { data: { session } } = await supabase.auth.getSession();
  const userUid = session?.user?.id;

  // 2. companies 테이블에서 내 업체 id(uuid) 찾기
  const { data: myCompany, error: companyError } = await supabase
    .from('companies')
    .select('id')
    .eq('user_id', userUid)
    .single();

  if (companyError || !myCompany) {
    clients.value = [];
    return;
  }
  const companyId = myCompany.id;

  // 3. 매핑 테이블에서 내 거래처 id 목록 추출
  const { data: assignments, error: assignError } = await supabase
    .from('client_company_assignments')
    .select('client_id')
    .eq('company_id', companyId);

  if (assignError || !assignments || assignments.length === 0) {
    clients.value = [];
    return;
  }

  const clientIds = assignments.map(a => a.client_id);

  // 4. 거래처 테이블에서 해당 id만 조회
  const { data, error } = await supabase
    .from('clients')
    .select('*')
    .in('id', clientIds)
    .eq('status', 'active')
    .order('client_code', { ascending: true });

  if (!error && data) {
    clients.value = data;
  }
};

onMounted(() => {
  fetchClients();
});
</script> 