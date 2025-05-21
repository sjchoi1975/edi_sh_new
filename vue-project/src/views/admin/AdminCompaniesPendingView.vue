<template>
  <div class="admin-companies-view">
    <div class="header-title">미승인 업체 목록</div>
    <div class="table-container">
      <ConfirmDialog></ConfirmDialog>
      <Toast />
      <DataTable
        :value="pendingCompanies"
        :paginator="true"
        :rows="10"
        :loading="loading"
        responsiveLayout="scroll"
        v-model:filters="filters"
        filterDisplay="menu"
        :globalFilterFields="['company_name', 'business_registration_number', 'representative_name']"
        class="custom-table"
      >
        <template #header>
          <div class="table-header">
            <span class="p-input-icon-left">
              <i class="pi pi-search"></i>
              <InputText v-model="filters['global'].value" placeholder="전체 검색" />
            </span>
          </div>
        </template>
        <template #empty>
          미승인 업체가 없습니다.
        </template>
        <template #loading>
          미승인 업체 목록을 불러오는 중입니다...
        </template>
        <Column field="company_group" header="구분" sortable></Column>
        <Column field="company_name" header="업체명" sortable>
          <template #body="slotProps">
            <span class="company-link" @click="openCompanyDetailDialog(slotProps.data)">{{ slotProps.data.company_name }}</span>
          </template>
        </Column>
        <Column field="business_registration_number" header="사업자등록번호"></Column>
        <Column field="representative_name" header="대표자"></Column>
        <Column field="business_address" header="사업장소재지"></Column>
        <Column field="default_commission_grade" header="수수료 등급"></Column>
        <Column field="assigned_pharmacist_contact" header="관리자"></Column>
        <Column field="remarks" header="비고"></Column>
        <Column field="approval_status" header="승인 처리" :exportable="false" style="min-width:10rem">
          <template #body="slotProps">
            <Button label="승인" icon="pi pi-check" class="p-button-rounded p-button-success p-button-sm" @click="confirmApprovalChange(slotProps.data, 'approved')" />
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
import Button from 'primevue/button';
import ConfirmDialog from 'primevue/confirmdialog';
import Toast from 'primevue/toast';
import InputText from 'primevue/inputtext';
import Dropdown from 'primevue/dropdown';
import { useConfirm } from "primevue/useconfirm";
import { useToast } from "primevue/usetoast";
import { supabase } from '@/supabase';

const pendingCompanies = ref([]);
const loading = ref(false);
const filters = ref({
    'global': { value: null, matchMode: 'contains' },
});
const confirm = useConfirm();
const toast = useToast();

const fetchCompanies = async () => {
  loading.value = true;
  try {
    const { data, error } = await supabase
      .from('companies')
      .select('*');
    if (error) throw error;
    pendingCompanies.value = (data || []).filter(company => company.user_type === 'user' && company.approval_status === 'pending');
  } catch (err) {
    toast.add({ severity: 'error', summary: '오류', detail: err.message || '업체 정보를 불러오는데 실패했습니다.', life: 3000 });
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  fetchCompanies();
});

function getTextEditor() { return {}; }
function getDropdownEditor() { return {}; }

const openCompanyDetailDialog = () => { toast.add({ severity: 'info', summary: '알림', detail: '상세 보기 기능 구현 필요', life: 2000 }); };

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
</script>

<style scoped>
.admin-companies-view {
  max-width: none;
  margin: 0;
  padding: 0 0 0 0;
}
.header-title {
  font-size: 1.35rem;
  font-weight: 700;
  color: #222;
  margin-bottom: 16px;
  margin-left: 0;
  margin-top: 0;
  padding-left: 0px;
  padding-top: 0;
}
.table-container {
  background: #fff;
  border: 1.5px solid #e0e0e0;
  border-radius: 4px;
  box-shadow: 0 1px 4px 0 rgba(0,0,0,0.03);
  padding: 16px 16px 16px 16px;
  margin: 0 0px 0 0px;
}
.table-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 0.5rem;
  padding-left: 0;
  padding-right: 0;
}
.custom-table :deep(.p-datatable) {
  border-radius: 4px;
  border: 1px solid #e0e0e0;
  background: #fff;
}
.custom-table :deep(.p-datatable-thead > tr > th),
.custom-table :deep(.p-datatable-tbody > tr > td),
.custom-table :deep(.p-datatable-tfoot > tr > td) {
  font-size: 14px;
  padding: 10px 8px;
  border-bottom: 1px solid #f0f0f0;
}
.custom-table :deep(.p-datatable-thead > tr > th:first-child),
.custom-table :deep(.p-datatable-tbody > tr > td:first-child),
.custom-table :deep(.p-datatable-tfoot > tr > td:first-child) {
  border-left: 1px solid #e0e0e0;
}
.custom-table :deep(.p-datatable-thead > tr > th:last-child),
.custom-table :deep(.p-datatable-tbody > tr > td:last-child),
.custom-table :deep(.p-datatable-tfoot > tr > td:last-child) {
  border-right: 1px solid #e0e0e0;
}
.custom-table :deep(.p-datatable-thead > tr > th) {
  background: #f8fafb;
  color: #222;
  font-weight: 600;
  font-size: 15px;
  border-bottom: 1px solid #e0e0e0;
}
.custom-table :deep(.p-datatable-tbody > tr) {
  transition: background 0.15s;
}
.custom-table :deep(.p-datatable-tbody > tr:hover) {
  background: #f4f8f6;
}
.company-link {
  font-weight: 700;
  color: #1976d2;
  text-decoration: underline;
  cursor: pointer;
}
/* 버튼 색상 통일 */
:deep(.p-button),
:deep(.p-button-sm),
:deep(.p-button-success),
:deep(.p-button-warning),
:deep(.p-button-info),
:deep(.p-button-danger) {
  border-radius: 4px !important;
  font-size: 14px !important;
}
</style> 