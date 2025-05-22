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
    <Dialog v-model:visible="companyDetailDialog" header="업체 상세 정보 및 수정" :style="{ width: '60vw' }" :modal="true">
      <div class="p-fluid">
        <div class="dialog-section">
          <div class="p-grid p-formgrid">
            <div class="p-field p-col-12 p-md-4">
              <label for="detail_email">아이디(이메일)</label>
              <span class="detail-text">{{ selectedCompany.email }}</span>
            </div>
            <div class="p-field p-col-12 p-md-4" style="display: flex; align-items: flex-end;">
              <Button label="비밀번호 초기화" class="p-button-warning" @click="resetCompanyPassword" style="margin-top: 1.5rem;" />
            </div>
          </div>
        </div>
        <div class="dialog-section">
          <div class="p-grid p-formgrid">
            <div class="p-field p-col-12 p-md-4">
              <label for="detail_company_name">업체명</label>
              <template v-if="isEditing">
                <InputText id="detail_company_name" v-model="selectedCompany.company_name" />
              </template>
              <template v-else>
                <span class="detail-text">{{ selectedCompany.company_name }}</span>
              </template>
            </div>
            <div class="p-field p-col-12 p-md-4">
              <label for="detail_business_registration_number">사업자등록번호</label>
              <span class="detail-text">{{ selectedCompany.business_registration_number }}</span>
            </div>
            <div class="p-field p-col-12 p-md-4">
              <label for="detail_representative_name">대표자</label>
              <template v-if="isEditing">
                <InputText id="detail_representative_name" v-model="selectedCompany.representative_name" />
              </template>
              <template v-else>
                <span class="detail-text">{{ selectedCompany.representative_name }}</span>
              </template>
            </div>
            <div class="p-field p-col-12 p-md-8">
              <label for="detail_business_address">사업장 소재지</label>
              <template v-if="isEditing">
                <InputText id="detail_business_address" v-model="selectedCompany.business_address" />
              </template>
              <template v-else>
                <span class="detail-text">{{ selectedCompany.business_address }}</span>
              </template>
            </div>
            <div class="p-field p-col-12 p-md-4">
              <label for="detail_landline_phone">유선전화</label>
              <template v-if="isEditing">
                <InputText id="detail_landline_phone" v-model="selectedCompany.landline_phone" />
              </template>
              <template v-else>
                <span class="detail-text">{{ selectedCompany.landline_phone }}</span>
              </template>
            </div>
            <div class="p-field p-col-12 p-md-4">
              <label for="detail_contact_person_name">담당자</label>
              <template v-if="isEditing">
                <InputText id="detail_contact_person_name" v-model="selectedCompany.contact_person_name" />
              </template>
              <template v-else>
                <span class="detail-text">{{ selectedCompany.contact_person_name }}</span>
              </template>
            </div>
            <div class="p-field p-col-12 p-md-4">
              <label for="detail_mobile_phone">휴대폰 번호</label>
              <template v-if="isEditing">
                <InputText id="detail_mobile_phone" v-model="selectedCompany.mobile_phone" />
              </template>
              <template v-else>
                <span class="detail-text">{{ selectedCompany.mobile_phone }}</span>
              </template>
            </div>
            <div class="p-field p-col-12 p-md-4">
              <label for="detail_mobile_phone_2">휴대폰 번호 2</label>
              <template v-if="isEditing">
                <InputText id="detail_mobile_phone_2" v-model="selectedCompany.mobile_phone_2" />
              </template>
              <template v-else>
                <span class="detail-text">{{ selectedCompany.mobile_phone_2 }}</span>
              </template>
            </div>
            <div class="p-field p-col-12 p-md-4">
              <label for="detail_receive_email">이메일(수신용)</label>
              <template v-if="isEditing">
                <InputText id="detail_receive_email" v-model="selectedCompany.receive_email" />
              </template>
              <template v-else>
                <span class="detail-text">{{ selectedCompany.receive_email }}</span>
              </template>
            </div>
          </div>
        </div>
        <div class="dialog-section">
          <div class="p-grid p-formgrid">
            <div class="p-field p-col-12 p-md-4">
              <label for="detail_company_group">구분</label>
              <template v-if="isEditing">
                <InputText id="detail_company_group" v-model="selectedCompany.company_group" />
              </template>
              <template v-else>
                <span class="detail-text">{{ selectedCompany.company_group }}</span>
              </template>
            </div>
            <div class="p-field p-col-12 p-md-4">
              <label for="detail_default_commission_grade">수수료 등급</label>
              <template v-if="isEditing">
                <Dropdown id="detail_default_commission_grade" v-model="selectedCompany.default_commission_grade" :options="commissionGrades" optionLabel="name" optionValue="value" placeholder="등급 선택" />
              </template>
              <template v-else>
                <span class="detail-text">{{ selectedCompany.default_commission_grade }}</span>
              </template>
            </div>
            <div class="p-field p-col-12 p-md-4">
              <label for="detail_assigned_pharmacist_contact">관리자</label>
              <template v-if="isEditing">
                <InputText id="detail_assigned_pharmacist_contact" v-model="selectedCompany.assigned_pharmacist_contact" />
              </template>
              <template v-else>
                <span class="detail-text">{{ selectedCompany.assigned_pharmacist_contact }}</span>
              </template>
            </div>
            <div class="p-field p-col-12">
              <label for="detail_remarks">비고</label>
              <template v-if="isEditing">
                <Textarea id="detail_remarks" v-model="selectedCompany.remarks" rows="3" autoResize />
              </template>
              <template v-else>
                <span class="detail-text">{{ selectedCompany.remarks }}</span>
              </template>
            </div>
          </div>
        </div>
        <div class="dialog-section">
          <div class="p-grid p-formgrid">
            <div class="p-field p-col-12 p-md-4">
              <label>등록일시</label>
              <span class="detail-text">{{ formatDateTime(selectedCompany.created_at) }}</span>
            </div>
            <div class="p-field p-col-12 p-md-4">
              <label>최종 수정일시</label>
              <span class="detail-text">{{ formatDateTime(selectedCompany.updated_at) }}</span>
            </div>
            <div class="p-field p-col-12 p-md-4">
              <label>최종 수정자</label>
              <span class="detail-text">{{ getLastModifiedBy(selectedCompany) }}</span>
            </div>
          </div>
        </div>
      </div>
      <template #footer>
        <Button v-if="isEditing" label="취소" icon="pi pi-times" class="p-button-secondary" @click="cancelEditCompanyDetail" />
        <Button v-if="isEditing" label="저장" icon="pi pi-check" class="p-button-success" :disabled="!hasChanges" @click="saveCompanyDetail" />
        <Button v-if="!isEditing" label="수정" icon="pi pi-pencil" class="p-button-info" @click="startEditCompanyDetail" />
        <Button label="닫기" icon="pi pi-times" class="p-button-secondary" :disabled="isEditing" @click="closeCompanyDetailDialog" />
      </template>
    </Dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, reactive } from 'vue';
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
import Textarea from 'primevue/textarea';
import Dialog from 'primevue/dialog';
import { watch } from 'vue';

const pendingCompanies = ref([]);
const loading = ref(false);
const filters = ref({
    'global': { value: null, matchMode: 'contains' },
});
const confirm = useConfirm();
const toast = useToast();
const companyDetailDialog = ref(false);
const selectedCompany = reactive({});
const isEditing = ref(false);
const hasChanges = ref(false);
const originalCompanyDetail = ref({});

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
.dialog-section {
  border-top: 1px solid #e0e0e0;
  margin-top: 18px;
  padding-top: 18px;
  margin-bottom: 0;
}
.dialog-section:first-of-type {
  border-top: none;
  margin-top: 0;
  padding-top: 0;
}
.p-grid.p-formgrid {
  display: flex !important;
  flex-wrap: wrap !important;
}
.custom-col {
  flex: 0 0 33.3333% !important;
  max-width: 33.3333% !important;
  box-sizing: border-box;
  padding-right: 16px;
  margin-bottom: 16px;
}
.custom-col.full {
  flex: 0 0 100% !important;
  max-width: 100% !important;
}
.custom-col.two-thirds {
  flex: 0 0 66.6666% !important;
  max-width: 66.6666% !important;
}
.p-field > label {
  font-weight: 500;
  margin-bottom: 4px;
  display: block;
}
.detail-text {
  display: block;
  padding: 6px 0 6px 0;
  color: #495057;
  font-size: 1rem;
  line-height: 1.5;
}
.p-button-secondary {
  background: #e0e0e0 !important;
  color: #222 !important;
  border: none !important;
}
input,
button,
.p-inputtext,
.p-button {
  padding-top: 4px !important;
  padding-bottom: 4px !important;
}
</style> 