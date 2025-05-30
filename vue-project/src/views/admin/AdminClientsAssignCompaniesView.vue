<template>
  <div class="admin-clients-assign-companies">
    <div class="header-title">담당업체 지정</div>
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
        :value="filteredClients"
        paginator
        :rows="20"
        :rowsPerPageOptions="[20, 50, 100]"
        scrollable
        scrollHeight="680px"
        v-model:filters="filters"
        :globalFilterFields="['client_code', 'name', 'business_registration_number']"
        class="custom-table"
        v-model:first="currentPageFirstIndex"
      >
        <template #empty>등록된 거래처가 없습니다.</template>
        <template #loading>거래처 목록을 불러오는 중입니다...</template>
        <Column header="No" :headerStyle="{ width: '4%' }">
          <template #body="slotProps">
            {{ slotProps.index + currentPageFirstIndex + 1 }}
          </template>
        </Column>
        <Column field="client_code" header="거래처코드" :headerStyle="{ width: '8%' }" :sortable="true" />
        <Column field="name" header="병의원명" :headerStyle="{ width: '14%' }" :sortable="true" />
        <Column field="business_registration_number" header="사업자등록번호" :headerStyle="{ width: '8%' }" :sortable="true" />
        <Column field="owner_name" header="원장명" :headerStyle="{ width: '8%' }" :sortable="true" />
        <Column field="address" header="주소" :headerStyle="{ width: '28%' }" :sortable="true" />
        <Column header="업체명" :headerStyle="{ width: '14%' }" :sortable="true">
          <template #body="slotProps">
            <div v-if="slotProps.data.companies && slotProps.data.companies.length > 0">
              <div v-for="(company, idx) in slotProps.data.companies" :key="company.id" style="min-height:32px;display:flex;align-items:center;">{{ company.company_name }}</div>
            </div>
            <div v-else style="min-height:32px;">-</div>
          </template>
        </Column>
        <Column header="사업자등록번호" :headerStyle="{ width: '8%' }" :sortable="true">
          <template #body="slotProps">
            <div v-if="slotProps.data.companies && slotProps.data.companies.length > 0">
              <div v-for="(company, idx) in slotProps.data.companies" :key="company.id" style="min-height:32px;display:flex;align-items:center;">{{ company.business_registration_number }}</div>
            </div>
            <div v-else style="min-height:32px;">-</div>
          </template>
        </Column>
        <Column header="작업" :headerStyle="{ width: '12%' }">
          <template #body="slotProps">
            <div v-if="slotProps.data.companies && slotProps.data.companies.length > 0">
              <div v-for="(company, idx) in slotProps.data.companies" :key="company.id" style="min-height:32px;display:flex;align-items:center;gap:4px;">
                <button class="btn-delete-m" @click="deleteAssignment(slotProps.data, company)">- 삭제</button>
                <button v-if="idx === slotProps.data.companies.length - 1" class="btn-add-m" @click="openAssignModal(slotProps.data)">+ 추가</button>
              </div>
            </div>
            <div v-else style="min-height:32px;display:flex;align-items:center;">
              <button class="btn-add-m" @click="openAssignModal(slotProps.data)">+ 추가</button>
            </div>
          </template>
        </Column>
      </DataTable>
    </div>

    <!-- 담당업체 지정 모달 -->
    <Dialog
      v-model:visible="assignModalVisible"
      header="업체 지정"
      :modal="true"
    >
      <div>
        <InputText v-model="companySearch" placeholder="업체명, 사업자등록번호, 대표자명 검색" style="width:100%;margin-bottom:12px;margin-top:0px;" />
        <DataTable
          :value="filteredCompanies"
          v-model:selection="selectedCompanies"
          selectionMode="multiple"
          :rows="20"
          class="custom-table"
        >
          <Column selectionMode="multiple" :headerStyle="{ width: '6%' }" />
          <Column field="company_name" header="업체명" :headerStyle="{ width: '20%' }" />
          <Column field="business_registration_number" header="사업자등록번호" :headerStyle="{ width: '14%' }" />
          <Column field="representative_name" header="대표자명" :headerStyle="{ width: '12%' }" />
          <Column field="business_address" header="사업장 소재지" :headerStyle="{ width: '48%' }" />
        </DataTable>
        <div class="btn-row" style="margin-top:16px;">
          <button class="btn-cancel" @click="closeAssignModal">취소</button>
          <button class="btn-add" :disabled="selectedCompanies.length === 0" @click="assignCompanies">지정</button>
        </div>
      </div>
    </Dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import InputText from 'primevue/inputtext';
import Dialog from 'primevue/dialog';
import { supabase } from '@/supabase';

const clients = ref([]);
const companies = ref([]);
const filters = ref({ 'global': { value: null, matchMode: 'contains' } });
const assignModalVisible = ref(false);
const selectedClient = ref(null);
const selectedCompanies = ref([]);
const companySearch = ref('');
const currentPageFirstIndex = ref(0);

const fetchClients = async () => {
  const { data: clientsData, error } = await supabase
    .from('clients')
    .select(`*, companies:client_company_assignments(company:companies(id, company_name, business_registration_number))`)
    .eq('status', 'active');
  if (!error && clientsData) {
    clients.value = clientsData.map(client => {
      const companiesArr = client.companies.map(c => c.company);
      return {
        ...client,
        companies: companiesArr
      };
    });
  }
};
const fetchCompanies = async () => {
  const { data, error } = await supabase
    .from('companies')
    .select('*')
    .eq('approval_status', 'approved')
    .eq('status', 'active')
    .eq('user_type', 'user'); // user만 불러오기
  if (!error && data) companies.value = data;
};
const filteredClients = computed(() => {
  if (!filters.value['global'].value) return clients.value;
  const search = filters.value['global'].value.toLowerCase();
  return clients.value.filter(c =>
    c.client_code.toLowerCase().includes(search) ||
    c.name.toLowerCase().includes(search) ||
    c.business_registration_number.includes(search)
  );
});
const filteredCompanies = computed(() => {
  if (!companySearch.value) return companies.value;
  const search = companySearch.value.toLowerCase();
  return companies.value.filter(c =>
    c.company_name.toLowerCase().includes(search) ||
    c.business_registration_number.includes(search) ||
    c.representative_name.toLowerCase().includes(search)
  );
});
function openAssignModal(client) {
  selectedClient.value = client;
  selectedCompanies.value = [];
  assignModalVisible.value = true;
}
function closeAssignModal() {
  assignModalVisible.value = false;
  selectedClient.value = null;
  selectedCompanies.value = [];
}
async function assignCompanies() {
  if (!selectedClient.value || selectedCompanies.value.length === 0) return;
  const assignments = selectedCompanies.value.map(company => ({
    client_id: selectedClient.value.id,
    company_id: company.id
  }));
  await supabase.from('client_company_assignments').upsert(assignments, { onConflict: 'client_id,company_id' });
  closeAssignModal();
  await fetchClients();
}
async function deleteAssignment(client, company = null) {
  let query = supabase.from('client_company_assignments').delete().eq('client_id', client.id);
  if (company) query = query.eq('company_id', company.id);
  await query;
  await fetchClients();
}
onMounted(() => {
  fetchClients();
  fetchCompanies();
});
</script> 