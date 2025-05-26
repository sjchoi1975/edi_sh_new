<template>
  <div class="admin-clients-assign-pharmacies">
    <div class="header-title">문전약국 지정</div>
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
      >
        <template #empty>등록된 거래처가 없습니다.</template>
        <template #loading>거래처 목록을 불러오는 중입니다...</template>
        <Column field="client_code" header="거래처코드" :headerStyle="{ width: '8%' }" />
        <Column field="name" header="병의원명" :headerStyle="{ width: '14%' }" />
        <Column field="business_registration_number" header="사업자등록번호" :headerStyle="{ width: '8%' }" />
        <Column field="owner_name" header="원장명" :headerStyle="{ width: '8%' }" />
        <Column field="address" header="주소" :headerStyle="{ width: '28%' }" />
        <Column header="약국명" :headerStyle="{ width: '14%' }">
          <template #body="slotProps">
            <div v-if="slotProps.data.pharmacies && slotProps.data.pharmacies.length > 0">
              <div v-for="(pharmacy, idx) in slotProps.data.pharmacies" :key="pharmacy.id" style="min-height:32px;display:flex;align-items:center;">{{ pharmacy.name }}</div>
            </div>
            <div v-else style="min-height:32px;">-</div>
          </template>
        </Column>
        <Column header="사업자등록번호" :headerStyle="{ width: '8%' }">
          <template #body="slotProps">
            <div v-if="slotProps.data.pharmacies && slotProps.data.pharmacies.length > 0">
              <div v-for="(pharmacy, idx) in slotProps.data.pharmacies" :key="pharmacy.id" style="min-height:32px;display:flex;align-items:center;">{{ pharmacy.business_registration_number }}</div>
            </div>
            <div v-else style="min-height:32px;">-</div>
          </template>
        </Column>
        <Column header="작업" :headerStyle="{ width: '12%' }">
          <template #body="slotProps">
            <div v-if="slotProps.data.pharmacies && slotProps.data.pharmacies.length > 0">
              <div v-for="(pharmacy, idx) in slotProps.data.pharmacies" :key="pharmacy.id" style="min-height:32px;display:flex;align-items:center;gap:4px;">
                <button class="btn-delete-m" @click="deleteAssignment(slotProps.data, pharmacy)">- 삭제</button>
                <button v-if="idx === slotProps.data.pharmacies.length - 1" class="btn-add-m" @click="openAssignModal(slotProps.data)">+ 추가</button>
              </div>
            </div>
            <div v-else style="min-height:32px;display:flex;align-items:center;">
              <button class="btn-add-m" @click="openAssignModal(slotProps.data)">+ 추가</button>
            </div>
          </template>
        </Column>
      </DataTable>
    </div>

    <!-- 담당약국 지정 모달 -->
    <Dialog
      v-model:visible="assignModalVisible"
      header="약국 지정"
      :modal="true"
    >
      <div>
        <InputText v-model="pharmacySearch" placeholder="약국명, 사업자등록번호 검색" style="width:100%;margin-bottom:12px;margin-top:0px;" />
        <DataTable
          :value="filteredPharmacies"
          v-model:selection="selectedPharmacies"
          selectionMode="multiple"
          :rows="20"
          class="custom-table"
        >
          <Column selectionMode="multiple" :headerStyle="{ width: '6%' }" />
          <Column field="name" header="약국명" :headerStyle="{ width: '30%' }" />
          <Column field="business_registration_number" header="사업자등록번호" :headerStyle="{ width: '20%' }" />
          <Column field="address" header="주소" :headerStyle="{ width: '44%' }" />
        </DataTable>
        <div class="btn-row" style="margin-top:16px;">
          <button class="btn-cancel" @click="closeAssignModal">취소</button>
          <button class="btn-add" :disabled="selectedPharmacies.length === 0" @click="assignPharmacies">지정</button>
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
const pharmacies = ref([]);
const filters = ref({ 'global': { value: null, matchMode: 'contains' } });
const assignModalVisible = ref(false);
const selectedClient = ref(null);
const selectedPharmacies = ref([]);
const pharmacySearch = ref('');

const fetchClients = async () => {
  const { data: clientsData, error } = await supabase
    .from('clients')
    .select(`*, pharmacies:client_pharmacy_assignments(pharmacy:pharmacies(id, name, business_registration_number))`)
    .eq('status', 'active');
  if (!error && clientsData) {
    clients.value = clientsData.map(client => {
      const pharmaciesArr = client.pharmacies.map(p => p.pharmacy);
      return {
        ...client,
        pharmacies: pharmaciesArr
      };
    });
  }
};
const fetchPharmacies = async () => {
  const { data, error } = await supabase
    .from('pharmacies')
    .select('*')
    .eq('status', 'active');
  if (!error && data) pharmacies.value = data;
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
const filteredPharmacies = computed(() => {
  if (!pharmacySearch.value) return pharmacies.value;
  const search = pharmacySearch.value.toLowerCase();
  return pharmacies.value.filter(p =>
    p.name.toLowerCase().includes(search) ||
    p.business_registration_number.includes(search)
  );
});
function openAssignModal(client) {
  selectedClient.value = client;
  selectedPharmacies.value = [];
  assignModalVisible.value = true;
}
function closeAssignModal() {
  assignModalVisible.value = false;
  selectedClient.value = null;
  selectedPharmacies.value = [];
}
async function assignPharmacies() {
  if (!selectedClient.value || selectedPharmacies.value.length === 0) return;
  const assignments = selectedPharmacies.value.map(pharmacy => ({
    client_id: selectedClient.value.id,
    pharmacy_id: pharmacy.id
  }));
  await supabase.from('client_pharmacy_assignments').upsert(assignments, { onConflict: 'client_id,pharmacy_id' });
  closeAssignModal();
  await fetchClients();
}
async function deleteAssignment(client, pharmacy = null) {
  let query = supabase.from('client_pharmacy_assignments').delete().eq('client_id', client.id);
  if (pharmacy) query = query.eq('pharmacy_id', pharmacy.id);
  await query;
  await fetchClients();
}
onMounted(() => {
  fetchClients();
  fetchPharmacies();
});
</script>