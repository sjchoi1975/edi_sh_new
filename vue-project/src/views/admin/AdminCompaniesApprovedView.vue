<template>
  <div class="admin-companies-view">
    <div class="header-title">승인 업체 목록</div>
    <div class="table-container">
      <ConfirmDialog></ConfirmDialog>
      <Toast />
      <DataTable
        :value="approvedCompanies"
        paginator
        :rows="20"
        :rowsPerPageOptions="[20, 50, 100]"
        editMode="cell"
        @cell-edit-complete="onCellEditComplete"
        scrollable
        scrollHeight="680px"
        v-model:filters="filters"
        :globalFilterFields="['company_name', 'business_registration_number', 'representative_name']"
        class="custom-table"
      >
        <template #header>
          <div class="table-header">
            <span class="p-input-icon-left">
              <InputText v-model="filters['global'].value" placeholder="업체명, 사업자등록번호, 대표자명 검색" style="width: 280px" />
            </span>
            <div>
              <Button label="신규 업체 추가" icon="pi pi-plus" class="p-button-success" @click="goCreate" />
            </div>
          </div>
        </template>
        <template #empty>
          승인된 업체가 없습니다.
        </template>
        <template #loading>
          승인된 업체 목록을 불러오는 중입니다...
        </template>
        <Column field="company_group" header="구분" :headerStyle="{ width: '10%' }" :sortable="true" :editor="getTextEditor"></Column>
        <Column field="company_name" header="업체명" :headerStyle="{ width: '12%' }" :sortable="true">
          <template #body="slotProps">
            <span class="company-link" @click="openCompanyDetailDialog(slotProps.data)">{{ slotProps.data.company_name }}</span>
          </template>
        </Column>
        <Column field="business_registration_number" header="사업자등록번호" :headerStyle="{ width: '10%' }" :sortable="true" :editor="getTextEditor"></Column>
        <Column field="representative_name" header="대표자" :headerStyle="{ width: '8%' }" :sortable="true" :editor="getTextEditor"></Column>
        <Column field="business_address" header="사업장소재지" :headerStyle="{ width: '24%' }" :sortable="true" :editor="getTextEditor"></Column>
        <Column field="default_commission_grade" header="수수료 등급" :headerStyle="{ width: '8%' }" :sortable="true" :editor="getDropdownEditor">
          <template #editor="{ data, field }">
            <Dropdown v-model="data[field]" :options="commissionGrades" optionLabel="name" optionValue="value" />
          </template>
        </Column>
        <Column field="assigned_pharmacist_contact" header="관리자" :headerStyle="{ width: '8%' }" :sortable="true" :editor="getTextEditor"></Column>
        <Column field="remarks" header="비고" :headerStyle="{ width: '12%' }" :sortable="true" :editor="getTextEditor"></Column>
        <Column field="approval_status" header="승인 처리" :headerStyle="{ width: '8%' }" :exportable="false" style="min-width:10rem">
          <template #body="slotProps">
            <Button label="취소" icon="pi pi-times" class="p-button-rounded p-button-warning p-button-sm" @click="confirmApprovalChange(slotProps.data, 'pending')" />
          </template>
        </Column>
      </DataTable>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, reactive, watch } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Button from 'primevue/button';
import ConfirmDialog from 'primevue/confirmdialog';
import Toast from 'primevue/toast';
import InputText from 'primevue/inputtext';
import { h } from 'vue';
import { useConfirm } from "primevue/useconfirm";
import { useToast } from "primevue/usetoast";
import { supabase } from '@/supabase';
import Textarea from 'primevue/textarea';
import Password from 'primevue/password';
import { useRouter } from 'vue-router';

const approvedCompanies = ref([]);
const loading = ref(false);
const filters = ref({
    'global': { value: null, matchMode: 'contains' },
});
const commissionGrades = [
  { name: 'A', value: 'A' },
  { name: 'B', value: 'B' },
  { name: 'C', value: 'C' }
];
const confirm = useConfirm();
const toast = useToast();
const router = useRouter();

const fetchCompanies = async () => {
  loading.value = true;
  try {
    const { data, error } = await supabase
      .from('companies')
      .select('*');
    if (error) throw error;
    approvedCompanies.value = (data || []).filter(company => company.user_type === 'user' && company.approval_status === 'approved');
  } catch (err) {
    toast.add({ severity: 'error', summary: '오류', detail: err.message || '업체 정보를 불러오는데 실패했습니다.', life: 3000 });
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  fetchCompanies();
});

function getDropdownEditor() { return {}; }

const goCreate = () => {
  router.push('/admin/companies/create');
};

const companyDetailDialog = ref(false);
const selectedCompany = reactive({});
const isEditing = ref(false);
const hasChanges = ref(false);
const originalCompanyDetail = ref({});

const openCompanyDetailDialog = (company) => {
  Object.assign(selectedCompany, company);
  originalCompanyDetail.value = JSON.parse(JSON.stringify(company));
  companyDetailDialog.value = true;
  isEditing.value = false;
  hasChanges.value = false;
};
const closeCompanyDetailDialog = () => {
  companyDetailDialog.value = false;
};
const startEditCompanyDetail = () => {
  isEditing.value = true;
  hasChanges.value = false;
};
const cancelEditCompanyDetail = () => {
  Object.assign(selectedCompany, JSON.parse(JSON.stringify(originalCompanyDetail.value)));
  isEditing.value = false;
  hasChanges.value = false;
};
const saveCompanyDetail = async () => {
  try {
    loading.value = true;
    const { error } = await supabase
      .from('companies')
      .update({
        company_name: selectedCompany.company_name,
        representative_name: selectedCompany.representative_name,
        business_address: selectedCompany.business_address,
        landline_phone: selectedCompany.landline_phone,
        contact_person_name: selectedCompany.contact_person_name,
        mobile_phone: selectedCompany.mobile_phone,
        mobile_phone_2: selectedCompany.mobile_phone_2,
        receive_email: selectedCompany.receive_email,
        company_group: selectedCompany.company_group,
        default_commission_grade: selectedCompany.default_commission_grade,
        assigned_pharmacist_contact: selectedCompany.assigned_pharmacist_contact,
        remarks: selectedCompany.remarks,
        updated_at: new Date().toISOString()
      })
      .eq('id', selectedCompany.id);
    if (error) throw error;
    toast.add({ severity: 'success', summary: '성공', detail: '업체 정보가 성공적으로 수정되었습니다.', life: 3000 });
    isEditing.value = false;
    hasChanges.value = false;
    originalCompanyDetail.value = JSON.parse(JSON.stringify(selectedCompany));
    await fetchCompanies();
  } catch (err) {
    toast.add({ severity: 'error', summary: '오류', detail: err.message || '업체 정보 수정 중 오류가 발생했습니다.', life: 3000 });
  } finally {
    loading.value = false;
  }
};

watch(selectedCompany, (newVal) => {
  hasChanges.value = JSON.stringify(newVal) !== JSON.stringify(originalCompanyDetail.value);
}, { deep: true });

const confirmApprovalChange = (company, newStatus) => {
  confirm.require({
    message: `${company.company_name} 업체를 ${newStatus === 'approved' ? '승인' : '승인 취소'} 처리하시겠습니까?`,
    header: `업체 ${newStatus === 'approved' ? '승인' : '승인 취소'} 확인`,
    icon: newStatus === 'approved' ? 'pi pi-check-circle' : 'pi pi-exclamation-triangle',
    acceptLabel: newStatus === 'approved' ? '승인' : '승인 취소',
    rejectLabel: '취소',
    acceptClass: newStatus === 'approved' ? 'p-button-success' : 'p-button-danger',
    accept: async () => {
      loading.value = true;
      try {
        const { error } = await supabase
          .from('companies')
          .update({ approval_status: newStatus })
          .eq('id', company.id);
        if (error) throw error;
        toast.add({ severity: 'success', summary: '성공', detail: `업체 상태가 성공적으로 변경되었습니다.`, life: 3000 });
        await fetchCompanies();
      } catch (err) {
        toast.add({ severity: 'error', summary: '오류', detail: err.message || '상태 변경 실패', life: 3000 });
      } finally {
        loading.value = false;
      }
    },
    reject: () => {
      toast.add({ severity: 'info', summary: '알림', detail: `처리가 취소되었습니다.`, life: 2000 });
    }
  });
};

// 날짜 포맷 함수 및 최종 수정자 함수 추가
const formatDateTime = (dateString) => {
  if (!dateString) return '';
  const date = new Date(dateString);
  return date.toLocaleString('ko-KR', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false
  });
};
const getLastModifiedBy = (company) => {
  if (!company) return '';
  if (company.user_type === 'admin') {
    return `관리자(${company.email})`;
  } else {
    return `${company.company_name}(${company.email})`;
  }
};
// 비밀번호 초기화 기능
const resetCompanyPassword = async () => {
  try {
    loading.value = true;
    const response = await fetch('/api/reset-password', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: selectedCompany.email, newPassword: 'asdf1234' })
    });
    const result = await response.json();
    if (!response.ok) throw new Error(result.error || '비밀번호 초기화 실패');
    toast.add({ severity: 'success', summary: '비밀번호 초기화', detail: '비밀번호가 asdf1234로 초기화되었습니다.', life: 3000 });
  } catch (err) {
    toast.add({ severity: 'error', summary: '오류', detail: err.message || '비밀번호 초기화 중 오류가 발생했습니다.', life: 3000 });
  } finally {
    loading.value = false;
  }
};

function getTextEditor(slotProps) {
  return h(InputText, {
    modelValue: slotProps.data[slotProps.field],
    'onUpdate:modelValue': value => slotProps.data[slotProps.field] = value
  });
}

function onCellEditComplete(event) {
  // event.data, event.field, event.newValue 등 활용
  // 예: 서버에 저장 등
}
</script> 