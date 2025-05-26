<template>
  <div class="admin-clients-assign-companies">
    <div class="header-title">거래처-담당업체 지정</div>
    <div class="content-container">
      <div class="selection-area">
        <div class="client-selection">
          <h3>거래처 선택</h3>
          <DataTable
            :value="clients"
            v-model:selection="selectedClient"
            selectionMode="single"
            :paginator="true"
            :rows="10"
            :rowsPerPageOptions="[10, 20, 50]"
            :globalFilterFields="['name', 'business_registration_number']"
            v-model:filters="filters"
            class="custom-table"
          >
            <template #header>
              <div class="table-header">
                <span class="p-input-icon-left">
                  <i class="pi pi-search" />
                  <InputText v-model="filters['global'].value" placeholder="거래처명, 사업자등록번호 검색" />
                </span>
              </div>
            </template>
            <Column field="name" header="거래처명" :sortable="true" />
            <Column field="business_registration_number" header="사업자등록번호" :sortable="true" />
            <Column field="address" header="주소" :sortable="true" />
          </DataTable>
        </div>
        
        <div class="company-selection">
          <h3>담당업체 선택</h3>
          <DataTable
            :value="companies"
            v-model:selection="selectedCompanies"
            selectionMode="multiple"
            :paginator="true"
            :rows="10"
            :rowsPerPageOptions="[10, 20, 50]"
            :globalFilterFields="['company_name', 'business_registration_number']"
            v-model:filters="companyFilters"
            class="custom-table"
          >
            <template #header>
              <div class="table-header">
                <span class="p-input-icon-left">
                  <i class="pi pi-search" />
                  <InputText v-model="companyFilters['global'].value" placeholder="업체명, 사업자등록번호 검색" />
                </span>
              </div>
            </template>
            <Column field="company_name" header="업체명" :sortable="true" />
            <Column field="business_registration_number" header="사업자등록번호" :sortable="true" />
            <Column field="representative_name" header="대표자명" :sortable="true" />
          </DataTable>
        </div>
      </div>
      
      <div class="action-area">
        <Button label="담당업체 지정" @click="assignCompanies" :disabled="!selectedClient || selectedCompanies.length === 0" />
        <Button label="담당업체 해제" @click="unassignCompanies" :disabled="!selectedClient || selectedCompanies.length === 0" class="p-button-danger" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import InputText from 'primevue/inputtext';
import Button from 'primevue/button';
import { supabase } from '@/supabase';
import { useToast } from 'primevue/usetoast';

const toast = useToast();
const clients = ref([]);
const companies = ref([]);
const selectedClient = ref(null);
const selectedCompanies = ref([]);
const filters = ref({ 'global': { value: null, matchMode: 'contains' } });
const companyFilters = ref({ 'global': { value: null, matchMode: 'contains' } });

const fetchClients = async () => {
  const { data, error } = await supabase
    .from('clients')
    .select('*')
    .order('name', { ascending: true });
  if (!error && data) {
    clients.value = data;
  }
};

const fetchCompanies = async () => {
  const { data, error } = await supabase
    .from('companies')
    .select('*')
    .eq('approval_status', 'approved')
    .order('company_name', { ascending: true });
  if (!error && data) {
    companies.value = data;
  }
};

const assignCompanies = async () => {
  if (!selectedClient.value || selectedCompanies.value.length === 0) return;
  
  try {
    const assignments = selectedCompanies.value.map(company => ({
      client_id: selectedClient.value.id,
      company_id: company.id
    }));
    
    const { error } = await supabase
      .from('client_company_assignments')
      .upsert(assignments, { onConflict: 'client_id,company_id' });
      
    if (error) throw error;
    
    toast.add({ severity: 'success', summary: '성공', detail: '담당업체가 지정되었습니다.', life: 3000 });
  } catch (error) {
    console.error('Error assigning companies:', error);
    toast.add({ severity: 'error', summary: '오류', detail: '담당업체 지정 중 오류가 발생했습니다.', life: 3000 });
  }
};

const unassignCompanies = async () => {
  if (!selectedClient.value || selectedCompanies.value.length === 0) return;
  
  try {
    const companyIds = selectedCompanies.value.map(company => company.id);
    
    const { error } = await supabase
      .from('client_company_assignments')
      .delete()
      .eq('client_id', selectedClient.value.id)
      .in('company_id', companyIds);
      
    if (error) throw error;
    
    toast.add({ severity: 'success', summary: '성공', detail: '담당업체가 해제되었습니다.', life: 3000 });
  } catch (error) {
    console.error('Error unassigning companies:', error);
    toast.add({ severity: 'error', summary: '오류', detail: '담당업체 해제 중 오류가 발생했습니다.', life: 3000 });
  }
};

onMounted(() => {
  fetchClients();
  fetchCompanies();
});
</script>

<style scoped>
.admin-clients-assign-companies {
  padding: 20px;
}

.header-title {
  font-size: 1.5rem;
  font-weight: 600;
  margin-bottom: 20px;
}

.content-container {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.selection-area {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

.client-selection,
.company-selection {
  background: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
}

h3 {
  margin: 0 0 16px 0;
  font-size: 1.1rem;
  color: #333;
}

.table-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.action-area {
  display: flex;
  gap: 10px;
  justify-content: center;
  margin-top: 20px;
}

:deep(.p-datatable) {
  font-size: 0.9rem;
}

:deep(.p-datatable .p-datatable-thead > tr > th) {
  background: #f8f9fa;
  padding: 12px;
}

:deep(.p-datatable .p-datatable-tbody > tr > td) {
  padding: 12px;
}

:deep(.p-inputtext) {
  width: 100%;
}
</style> 