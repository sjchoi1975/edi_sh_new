<template>
  <div class="admin-companies-view">
    <h2>업체 목록</h2>
    <ConfirmDialog></ConfirmDialog>
    <Toast />
    <DataTable
      v-if="$route.meta.companyStatus === 'approved'"
      :value="approvedCompanies"
      :paginator="true"
      :rows="10"
      :loading="loading"
      responsiveLayout="scroll"
      v-model:filters="filters"
      filterDisplay="menu"
      :globalFilterFields="['company_name', 'business_registration_number', 'representative_name']"
    >
      <template #header>
        <div class="table-header">
          <span class="p-input-icon-left">
            <i class="pi pi-search"></i>
            <InputText v-model="filters['global'].value" placeholder="전체 검색" />
          </span>
          <div>
            <Button label="신규 업체 추가" icon="pi pi-plus" class="p-button-success" @click="openNewCompanyDialog" />
          </div>
        </div>
      </template>
      <template #empty>
        승인된 업체가 없습니다.
      </template>
      <template #loading>
        승인된 업체 목록을 불러오는 중입니다...
      </template>
      <Column field="company_group" header="구분" sortable :editor="getTextEditor"></Column>
      <Column field="company_name" header="업체명" sortable>
        <template #body="slotProps">
          <span class="company-link" @click="openCompanyDetailDialog(slotProps.data)">{{ slotProps.data.company_name }}</span>
        </template>
      </Column>
      <Column field="business_registration_number" header="사업자등록번호" :editor="getTextEditor"></Column>
      <Column field="representative_name" header="대표자" :editor="getTextEditor"></Column>
      <Column field="business_address" header="사업장소재지" :editor="getTextEditor"></Column>
      <Column field="default_commission_grade" header="수수료 등급" :editor="getDropdownEditor">
        <template #editor="{ data, field }">
          <Dropdown v-model="data[field]" :options="commissionGrades" optionLabel="name" optionValue="value" />
        </template>
      </Column>
      <Column field="assigned_pharmacist_contact" header="관리자" :editor="getTextEditor"></Column>
      <Column field="remarks" header="비고" :editor="getTextEditor"></Column>
      <Column field="approval_status" header="승인 처리" :exportable="false" style="min-width:10rem">
        <template #body="slotProps">
          <Button label="승인 취소" icon="pi pi-times" class="p-button-rounded p-button-warning p-button-sm" @click="confirmApprovalChange(slotProps.data, 'pending')" />
        </template>
      </Column>
    </DataTable>
    <DataTable
      v-else-if="$route.meta.companyStatus === 'pending'"
      :value="pendingCompanies"
      :paginator="true"
      :rows="10"
      :loading="loading"
      responsiveLayout="scroll"
      v-model:filters="filters"
      filterDisplay="menu"
      :globalFilterFields="['company_name', 'business_registration_number', 'representative_name']"
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

    <!-- 신규 업체 추가 다이얼로그 -->
    <Dialog v-model:visible="newCompanyDialog" header="신규 업체 추가" :style="{ width: '80vw' }" :modal="true">
      <div class="p-fluid">
        <h3>계정 정보</h3>
        <div class="p-grid p-formgrid">
          <div class="p-field p-col-12 p-md-4">
            <label for="email">아이디(이메일) <span class="p-error">*</span></label>
            <InputText id="email" v-model="newCompany.email" :class="{'p-invalid': submitted && !newCompany.email}" />
            <small class="p-error" v-if="submitted && !newCompany.email">아이디는 필수 항목입니다.</small>
          </div>
          <div class="p-field p-col-12 p-md-4">
            <label for="password">비밀번호 <span class="p-error">*</span></label>
            <Password id="password" v-model="newCompany.password" toggleMask :class="{'p-invalid': submitted && !newCompany.password}" inputClass="p-password" :feedback="false" />
            <small class="p-error" v-if="submitted && !newCompany.password">비밀번호는 필수 항목입니다.</small>
          </div>
          <div class="p-field p-col-12 p-md-4">
            <label for="confirmPassword">비밀번호 확인 <span class="p-error">*</span></label>
            <Password id="confirmPassword" v-model="confirmPassword" toggleMask :class="{'p-invalid': submitted && passwordsDoNotMatch}" inputClass="p-password" :feedback="false" />
            <small class="p-error" v-if="submitted && passwordsDoNotMatch">비밀번호가 일치하지 않습니다.</small>
          </div>
        </div>
        
        <h3>업체 정보</h3>
        <div class="p-grid p-formgrid">
          <div class="p-field p-col-12 p-md-4">
            <label for="company_name">업체명 <span class="p-error">*</span></label>
            <InputText id="company_name" v-model="newCompany.company_name" :class="{'p-invalid': submitted && !newCompany.company_name}" />
            <small class="p-error" v-if="submitted && !newCompany.company_name">업체명은 필수 항목입니다.</small>
          </div>
          
          <div class="p-field p-col-12 p-md-4">
            <label for="business_registration_number">사업자등록번호 <span class="p-error">*</span></label>
            <InputText id="business_registration_number" v-model="newCompany.business_registration_number" :class="{'p-invalid': submitted && !newCompany.business_registration_number}" />
            <small class="p-error" v-if="submitted && !newCompany.business_registration_number">사업자등록번호는 필수 항목입니다.</small>
          </div>
          
          <div class="p-field p-col-12 p-md-4">
            <label for="representative_name">대표자 <span class="p-error">*</span></label>
            <InputText id="representative_name" v-model="newCompany.representative_name" :class="{'p-invalid': submitted && !newCompany.representative_name}" />
            <small class="p-error" v-if="submitted && !newCompany.representative_name">대표자는 필수 항목입니다.</small>
          </div>
          
          <div class="p-field p-col-12 p-md-8">
            <label for="business_address">사업장 소재지 <span class="p-error">*</span></label>
            <InputText id="business_address" v-model="newCompany.business_address" :class="{'p-invalid': submitted && !newCompany.business_address}" />
            <small class="p-error" v-if="submitted && !newCompany.business_address">사업장 소재지는 필수 항목입니다.</small>
          </div>
          
          <div class="p-field p-col-12 p-md-4">
            <label for="landline_phone">유선전화</label>
            <InputText id="landline_phone" v-model="newCompany.landline_phone" />
          </div>
          
          <div class="p-field p-col-12 p-md-4">
            <label for="contact_person_name">담당자 <span class="p-error">*</span></label>
            <InputText id="contact_person_name" v-model="newCompany.contact_person_name" :class="{'p-invalid': submitted && !newCompany.contact_person_name}" />
            <small class="p-error" v-if="submitted && !newCompany.contact_person_name">담당자는 필수 항목입니다.</small>
          </div>
          
          <div class="p-field p-col-12 p-md-4">
            <label for="mobile_phone">휴대폰 번호 <span class="p-error">*</span></label>
            <InputText id="mobile_phone" v-model="newCompany.mobile_phone" :class="{'p-invalid': submitted && !newCompany.mobile_phone}" />
            <small class="p-error" v-if="submitted && !newCompany.mobile_phone">휴대폰 번호는 필수 항목입니다.</small>
          </div>
          
          <div class="p-field p-col-12 p-md-4">
            <label for="mobile_phone_2">휴대폰 번호 2</label>
            <InputText id="mobile_phone_2" v-model="newCompany.mobile_phone_2" />
          </div>
          
          <div class="p-field p-col-12 p-md-4">
            <label for="receive_email">이메일 수신</label>
            <InputText id="receive_email" v-model="newCompany.receive_email" type="email" placeholder="수신용 이메일 주소" />
          </div>
        </div>
        
        <h3>관리 정보</h3>
        <div class="p-grid p-formgrid">
          <div class="p-field p-col-12 p-md-4">
            <label for="company_group">구분</label>
            <InputText id="company_group" v-model="newCompany.company_group" />
          </div>
          
          <div class="p-field p-col-12 p-md-4">
            <label for="default_commission_grade">수수료 등급</label>
            <Dropdown id="default_commission_grade" v-model="newCompany.default_commission_grade" :options="commissionGrades" optionLabel="name" optionValue="value" placeholder="등급 선택" />
          </div>
          
          <div class="p-field p-col-12 p-md-4">
            <label for="assigned_pharmacist_contact">관리자</label>
            <InputText id="assigned_pharmacist_contact" v-model="newCompany.assigned_pharmacist_contact" />
          </div>
          
          <div class="p-field p-col-12">
            <label for="remarks">비고</label>
            <Textarea id="remarks" v-model="newCompany.remarks" rows="3" autoResize />
          </div>
          
          <div class="p-field p-col-12 p-md-4">
            <label for="approval_status">승인여부</label>
            <Dropdown id="approval_status" v-model="newCompany.approval_status" :options="approvalStatuses" optionLabel="name" optionValue="value" placeholder="승인여부 선택" />
          </div>
        </div>
      </div>
      
      <template #footer>
        <Button label="취소" icon="pi pi-times" class="p-button-text" @click="hideDialog" />
        <Button label="저장" icon="pi pi-check" class="p-button-success" @click="saveCompany" />
      </template>
    </Dialog>

    <Dialog v-model:visible="companyDetailDialog" header="업체 상세/수정" :style="{ width: '80vw' }" :modal="true">
      <div class="p-fluid">
        <h3>계정 정보</h3>
        <div class="p-grid p-formgrid">
          <div class="p-field p-col-12 p-md-4">
            <label for="detail_email">아이디(이메일)</label>
            <span class="detail-text">{{ selectedCompany.email }}</span>
          </div>
          <div class="p-field p-col-12 p-md-4" style="display: flex; align-items: flex-end;">
            <Button label="비밀번호 초기화" class="p-button-warning" @click="resetCompanyPassword" style="margin-top: 1.5rem;" />
          </div>
        </div>

        <h3>업체 정보</h3>
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
            <label for="detail_receive_email">이메일 수신</label>
            <template v-if="isEditing">
              <InputText id="detail_receive_email" v-model="selectedCompany.receive_email" />
            </template>
            <template v-else>
              <span class="detail-text">{{ selectedCompany.receive_email }}</span>
            </template>
          </div>
        </div>

        <h3>관리 정보</h3>
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
          <div class="p-field p-col-12 p-md-4">
            <label for="detail_approval_status">승인여부</label>
            <template v-if="isEditing">
              <Dropdown id="detail_approval_status" v-model="selectedCompany.approval_status" :options="approvalStatuses" optionLabel="name" optionValue="value" placeholder="승인여부 선택" />
            </template>
            <template v-else>
              <span class="detail-text">
                {{ approvalStatuses.find(opt => opt.value === selectedCompany.approval_status)?.name || selectedCompany.approval_status }}
              </span>
            </template>
          </div>
        </div>

        <h3>등록 정보</h3>
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
      <template #footer>
        <Button v-if="isEditing" label="취소" icon="pi pi-times" class="p-button-text" @click="cancelEditCompanyDetail" />
        <Button v-if="isEditing" label="수정" icon="pi pi-check" class="p-button-success" :disabled="!hasChanges" @click="saveCompanyDetail" />
        <Button v-if="!isEditing" label="수정" icon="pi pi-pencil" class="p-button-info" @click="startEditCompanyDetail" />
        <Button label="닫기" icon="pi pi-times" class="p-button-text" :disabled="isEditing" @click="closeCompanyDetailDialog" />
      </template>
    </Dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, reactive, toRaw, watch } from 'vue';
import TabView from 'primevue/tabview';
import TabPanel from 'primevue/tabpanel';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Button from 'primevue/button';
import ConfirmDialog from 'primevue/confirmdialog';
import Toast from 'primevue/toast';
import InputText from 'primevue/inputtext';
import Dialog from 'primevue/dialog';
import Dropdown from 'primevue/dropdown';
import Textarea from 'primevue/textarea';
import Password from 'primevue/password';
import { useConfirm } from "primevue/useconfirm";
import { useToast } from "primevue/usetoast";
import { supabase } from '@/supabase';
import { useRouter } from 'vue-router';

// FilterMatchMode를 직접 정의
const FilterMatchMode = {
  STARTS_WITH: 'startsWith',
  CONTAINS: 'contains',
  ENDS_WITH: 'endsWith',
  EQUALS: 'equals',
  NOT_EQUALS: 'notEquals',
  IN: 'in',
  LESS_THAN: 'lt',
  LESS_THAN_OR_EQUAL_TO: 'lte',
  GREATER_THAN: 'gt',
  GREATER_THAN_OR_EQUAL_TO: 'gte',
  BETWEEN: 'between',
  DATE_IS: 'dateIs',
  DATE_IS_NOT: 'dateIsNot',
  DATE_BEFORE: 'dateBefore',
  DATE_AFTER: 'dateAfter'
};

const confirm = useConfirm();
const toast = useToast();

const approvedCompanies = ref([]);
const pendingCompanies = ref([]);
const loading = ref(false);
const error = ref(null);
const activeTabIndex = ref(0);
const newCompanyDialog = ref(false);
const submitted = ref(false);
const passwordsDoNotMatch = ref(false);

// 드롭다운 옵션
const commissionGrades = [
  { name: 'A', value: 'A' },
  { name: 'B', value: 'B' },
  { name: 'C', value: 'C' }
];

const approvalStatuses = [
  { name: '승인', value: 'approved' },
  { name: '미승인', value: 'pending' }
];

// 신규 업체 기본값
const defaultNewCompany = {
  company_name: '',
  business_registration_number: '',
  representative_name: '',
  contact_person_name: '',
  mobile_phone: '',
  mobile_phone_2: '',
  approval_status: 'pending',
  status: 'active',
  user_type: 'user',
  email: '',
  password: '',
  landline_phone: '',
  business_address: '',
  receive_email: '',
  default_commission_grade: 'A',
  remarks: '',
  company_group: '',
  assigned_pharmacist_contact: '',
  registration_request_date: new Date().toISOString()
};

const newCompany = reactive({...defaultNewCompany});
const confirmPassword = ref('');

const filters = ref({
    'global': { value: null, matchMode: FilterMatchMode.CONTAINS },
});

const companyDetailDialog = ref(false);
const selectedCompany = reactive({});
const isEditing = ref(false);
const hasChanges = ref(false);
const editingRows = ref({});
const isTableEditing = ref(false);
const hasTableChanges = ref(false);
const originalData = ref({});
const originalCompanyDetail = ref({});

const fetchCompanies = async () => {
  loading.value = true;
  error.value = null;
  try {
    const { data, error: fetchError } = await supabase
      .from('companies')
      .select('id, company_name, business_registration_number, representative_name, contact_person_name, mobile_phone, approval_status, status, user_type, email, landline_phone, business_address, receive_email, default_commission_grade, remarks, company_group, assigned_pharmacist_contact, registration_request_date, created_at, updated_at');

    if (fetchError) throw fetchError;

    // 일반 사용자(user)만 필터링
    const userCompanies = data.filter(company => company.user_type === 'user');
    
    approvedCompanies.value = userCompanies.filter(company => company.approval_status === 'approved');
    pendingCompanies.value = userCompanies.filter(company => company.approval_status === 'pending');

  } catch (err) {
    console.error('Error fetching companies:', err);
    error.value = err.message || '업체 정보를 불러오는데 실패했습니다.';
    toast.add({ severity: 'error', summary: '오류', detail: error.value, life: 3000 });
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  fetchCompanies();
});

const onTabChange = (event) => {
  activeTabIndex.value = event.index;
  filters.value.global.value = null; 
};

const confirmApprovalChange = (company, newStatus) => {
  const actionText = newStatus === 'approved' ? '승인' : '승인 취소';
  const currentStatusText = company.approval_status === 'approved' ? '승인된' : '미승인';

  confirm.require({
    message: `${company.company_name} 업체를 ${actionText} 처리하시겠습니까? (현재: ${currentStatusText})`,
    header: `업체 ${actionText} 확인`,
    icon: newStatus === 'approved' ? 'pi pi-check-circle' : 'pi pi-exclamation-triangle',
    acceptLabel: actionText,
    rejectLabel: '취소',
    acceptClass: newStatus === 'approved' ? 'p-button-success' : 'p-button-danger',
    accept: async () => {
      await updateApprovalStatus(company.id, newStatus);
    },
    reject: () => {
      toast.add({ severity: 'info', summary: '알림', detail: `${actionText} 처리가 취소되었습니다.`, life: 3000 });
    }
  });
};

const updateApprovalStatus = async (companyId, newStatus) => {
  loading.value = true;
  try {
    const { error: updateError } = await supabase
      .from('companies')
      .update({ approval_status: newStatus, updated_at: new Date().toISOString() })
      .eq('id', companyId);

    if (updateError) throw updateError;

    toast.add({ 
      severity: 'success', 
      summary: '성공', 
      detail: `업체 상태가 성공적으로 ${newStatus === 'approved' ? '승인' : '미승인(으)'}로 변경되었습니다.`, 
      life: 3000 
    });
    await fetchCompanies();

  } catch (err) {
    console.error('Error updating approval status:', err);
    toast.add({ 
      severity: 'error', 
      summary: '오류', 
      detail: err.message || '업체 상태 변경 중 오류가 발생했습니다.', 
      life: 3000 
    });
  } finally {
    loading.value = false;
  }
};

const openNewCompanyDialog = () => {
  newCompanyDialog.value = true;
  submitted.value = false;
  Object.assign(newCompany, defaultNewCompany);
};

const hideDialog = () => {
  newCompanyDialog.value = false;
  submitted.value = false;
};

const saveCompany = async () => {
  submitted.value = true;
  passwordsDoNotMatch.value = newCompany.password !== confirmPassword.value;
  
  // 필수 필드 검증 (company_group 제외)
  if (!newCompany.company_name || !newCompany.business_registration_number || 
      !newCompany.representative_name || !newCompany.business_address || 
      !newCompany.contact_person_name || !newCompany.mobile_phone || 
      !newCompany.email || !newCompany.password ||
      passwordsDoNotMatch.value) {
    toast.add({ severity: 'warn', summary: '필수 항목 누락', detail: '필수 입력 항목을 모두 입력해주세요.', life: 3000 });
    return;
  }
  
  try {
    loading.value = true;
    
    // 서버리스 함수로 계정 생성 요청
    const response = await fetch('/api/create-user', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: newCompany.email,
        password: newCompany.password,
        company_name: newCompany.company_name
      })
    });
    const result = await response.json();

    if (!response.ok) {
      toast.add({ severity: 'error', summary: '오류', detail: result.error || '계정 생성 실패', life: 3000 });
      loading.value = false;
      return;
    }

    // 생성된 사용자 ID
    const userId = result.user.id;
    
    // companies 테이블에 데이터 저장 (user_id 연결)
    const { data, error: insertError } = await supabase
      .from('companies')
      .insert([{
        company_name: newCompany.company_name,
        business_registration_number: newCompany.business_registration_number,
        representative_name: newCompany.representative_name,
        contact_person_name: newCompany.contact_person_name,
        mobile_phone: newCompany.mobile_phone,
        mobile_phone_2: newCompany.mobile_phone_2,
        approval_status: newCompany.approval_status,
        status: 'active',
        user_type: 'user',
        email: newCompany.email,
        landline_phone: newCompany.landline_phone,
        business_address: newCompany.business_address,
        receive_email: newCompany.receive_email,
        default_commission_grade: newCompany.default_commission_grade,
        remarks: newCompany.remarks,
        company_group: newCompany.company_group,
        assigned_pharmacist_contact: newCompany.assigned_pharmacist_contact,
        registration_request_date: new Date().toISOString(),
        user_id: userId,  // Auth 사용자와 연결
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }])
      .select();

    if (insertError) throw insertError;

    toast.add({ 
      severity: 'success', 
      summary: '성공', 
      detail: '신규 업체가 성공적으로 추가되었습니다.', 
      life: 3000 
    });
    
    newCompanyDialog.value = false;
    confirmPassword.value = '';
    await fetchCompanies();
    
  } catch (err) {
    console.error('Error adding new company:', err);
    toast.add({ 
      severity: 'error', 
      summary: '오류', 
      detail: err.message || '업체 추가 중 오류가 발생했습니다.', 
      life: 3000 
    });
  } finally {
    loading.value = false;
  }
};

const openCompanyDetailDialog = (company) => {
  Object.assign(selectedCompany, company);
  // 원본 데이터 깊은 복사 저장
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
  // 원본 데이터로 복원
  Object.assign(selectedCompany, JSON.parse(JSON.stringify(originalCompanyDetail.value)));
  isEditing.value = false;
  hasChanges.value = false;
};

const saveCompanyDetail = async () => {
  try {
    loading.value = true;
    // DB 업데이트
    const { error } = await supabase
      .from('companies')
      .update({
        company_name: selectedCompany.company_name,
        business_registration_number: selectedCompany.business_registration_number,
        representative_name: selectedCompany.representative_name,
        contact_person_name: selectedCompany.contact_person_name,
        mobile_phone: selectedCompany.mobile_phone,
        mobile_phone_2: selectedCompany.mobile_phone_2,
        approval_status: selectedCompany.approval_status,
        status: selectedCompany.status,
        user_type: selectedCompany.user_type,
        email: selectedCompany.email,
        landline_phone: selectedCompany.landline_phone,
        business_address: selectedCompany.business_address,
        receive_email: selectedCompany.receive_email,
        default_commission_grade: selectedCompany.default_commission_grade,
        remarks: selectedCompany.remarks,
        company_group: selectedCompany.company_group,
        assigned_pharmacist_contact: selectedCompany.assigned_pharmacist_contact,
        updated_at: new Date().toISOString()
      })
      .eq('id', selectedCompany.id);
    if (error) throw error;
    toast.add({ severity: 'success', summary: '성공', detail: '업체 정보가 성공적으로 수정되었습니다.', life: 3000 });
    isEditing.value = false;
    hasChanges.value = false;
    // 원본 데이터 갱신
    originalCompanyDetail.value = JSON.parse(JSON.stringify(selectedCompany));
    await fetchCompanies();
  } catch (err) {
    toast.add({ severity: 'error', summary: '오류', detail: err.message || '업체 정보 수정 중 오류가 발생했습니다.', life: 3000 });
  } finally {
    loading.value = false;
  }
};

const resetCompanyPassword = () => {
  // 비밀번호 초기화 로직 구현 예정
  alert('비밀번호가 asdf1234로 초기화됩니다.');
};

const getTextEditor = (options) => {
  return {
    template: `<InputText v-model="data[field]" :disabled="!isTableEditing" />`,
    props: ['data', 'field']
  };
};

const getDropdownEditor = (options) => {
  return {
    template: `<Dropdown v-model="data[field]" :options="commissionGrades" optionLabel="name" optionValue="value" :disabled="!isTableEditing" />`,
    props: ['data', 'field']
  };
};

const startTableEdit = () => {
  isTableEditing.value = true;
  // 원본 데이터 저장
  originalData.value = JSON.parse(JSON.stringify(approvedCompanies.value));
};

const cancelTableEdit = () => {
  if (hasTableChanges.value) {
    confirm.require({
      message: '변경사항이 있습니다. 취소하시겠습니까?',
      header: '편집 취소 확인',
      icon: 'pi pi-exclamation-triangle',
      acceptLabel: '확인',
      rejectLabel: '취소',
      accept: () => {
        // 원본 데이터로 복원
        approvedCompanies.value = JSON.parse(JSON.stringify(originalData.value));
        isTableEditing.value = false;
        hasTableChanges.value = false;
        editingRows.value = {};
      }
    });
  } else {
    isTableEditing.value = false;
    editingRows.value = {};
  }
};

const onRowEditSave = (event) => {
  const { data, newData } = event;
  hasTableChanges.value = true;
};

const saveTableChanges = async () => {
  try {
    loading.value = true;
    
    // 변경된 데이터만 필터링
    const changedCompanies = approvedCompanies.value.filter((company, index) => {
      const original = originalData.value[index];
      return JSON.stringify(company) !== JSON.stringify(original);
    });

    // 변경된 데이터 업데이트
    for (const company of changedCompanies) {
      const { error } = await supabase
        .from('companies')
        .update({
          ...company,
          updated_at: new Date().toISOString()
        })
        .eq('id', company.id);

      if (error) throw error;
    }

    toast.add({
      severity: 'success',
      summary: '성공',
      detail: '업체 정보가 성공적으로 수정되었습니다.',
      life: 3000
    });

    isTableEditing.value = false;
    hasTableChanges.value = false;
    editingRows.value = {};
    await fetchCompanies();

  } catch (err) {
    console.error('Error updating companies:', err);
    toast.add({
      severity: 'error',
      summary: '오류',
      detail: err.message || '업체 정보 수정 중 오류가 발생했습니다.',
      life: 3000
    });
  } finally {
    loading.value = false;
  }
};

// 라우터 가드 추가
const router = useRouter();
router.beforeEach((to, from, next) => {
  if (isTableEditing.value && hasTableChanges.value) {
    confirm.require({
      message: '저장하지 않은 변경사항이 있습니다. 계속하시겠습니까?',
      header: '변경사항 확인',
      icon: 'pi pi-exclamation-triangle',
      acceptLabel: '계속',
      rejectLabel: '취소',
      accept: () => {
        next();
      },
      reject: () => {
        next(false);
      }
    });
  } else {
    next();
  }
});

// 날짜 포맷 함수 추가
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

// 최종 수정자 표시 함수 추가
const getLastModifiedBy = (company) => {
  if (!company) return '';
  if (company.user_type === 'admin') {
    return `관리자(${company.email})`;
  } else {
    return `${company.company_name}(${company.email})`;
  }
};

// 입력값 변경 감지하여 hasChanges 업데이트
watch(selectedCompany, (newVal) => {
  hasChanges.value = JSON.stringify(newVal) !== JSON.stringify(originalCompanyDetail.value);
}, { deep: true });

</script>

<style scoped>
.admin-companies-view {
  padding: 1rem;
}
.table-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 1rem;
}

.p-field {
  margin-bottom: 1.5rem;
}

.p-grid {
  display: flex;
  flex-wrap: wrap;
  margin-right: -0.5rem;
  margin-left: -0.5rem;
  margin-top: -0.5rem;
}

.p-grid > div {
  padding: 0.5rem;
}

.p-col-12 {
  width: 100%;
}

@media screen and (min-width: 768px) {
  .p-md-4 {
    width: 33.3333%;
  }
  
  .p-md-8 {
    width: 66.6667%;
  }
}

:deep(.p-inputtext),
:deep(.p-dropdown),
:deep(.p-password input) {
  width: 100%;
  height: 40px;
}

:deep(.p-dropdown-panel) {
  z-index: 1100;
}

:deep(.p-dialog-content) {
  padding: 1.5rem 2rem;
}

h3 {
  margin-top: 1.5rem;
  margin-bottom: 1rem;
  border-bottom: 1px solid #e0e0e0;
  padding-bottom: 0.5rem;
}

.company-link {
  font-weight: 700;
  color: #1976d2;
  text-decoration: underline;
  cursor: pointer;
}

.detail-text {
  display: block;
  padding: 0.5rem;
  color: #495057;
  font-size: 1rem;
  line-height: 1.5;
}

input,
button,
.p-inputtext,
.p-button {
  padding-top: 6px !important;
  padding-bottom: 6px !important;
}
</style>