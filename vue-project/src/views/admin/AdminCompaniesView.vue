<template>
  <div class="admin-companies-view">
    <h2>업체 목록</h2>
    <ConfirmDialog></ConfirmDialog>
    <Toast />
    <TabView @tab-change="onTabChange">
      <TabPanel header="승인 업체 목록">
        <DataTable :value="approvedCompanies" :paginator="true" :rows="10" 
                   :loading="loading" responsiveLayout="scroll" v-model:filters="filters" 
                   filterDisplay="menu" :globalFilterFields="['company_name', 'business_registration_number', 'representative_name']">
          <template #header>
            <div class="table-header">
              <span class="p-input-icon-left">
                <i class="pi pi-search"></i>
                <InputText v-model="filters['global'].value" placeholder="전체 검색" />
              </span>
              <Button label="신규 업체 추가" icon="pi pi-plus" class="p-button-success" @click="openNewCompanyDialog" />
            </div>
          </template>
          <template #empty>
            승인된 업체가 없습니다.
          </template>
          <template #loading>
            승인된 업체 목록을 불러오는 중입니다...
          </template>
          <Column field="company_group" header="구분" sortable></Column>
          <Column field="company_name" header="업체명" sortable></Column>
          <Column field="business_registration_number" header="사업자등록번호"></Column>
          <Column field="representative_name" header="대표자"></Column>
          <Column field="business_address" header="사업장소재지"></Column>
          <Column field="default_commission_grade" header="수수료 등급"></Column>
          <Column field="assigned_pharmacist_contact" header="관리자"></Column> 
          <Column field="remarks" header="비고"></Column>
          <Column field="approval_status" header="승인 처리" :exportable="false" style="min-width:10rem">
            <template #body="slotProps">
              <Button label="승인 취소" icon="pi pi-times" class="p-button-rounded p-button-warning p-button-sm" @click="confirmApprovalChange(slotProps.data, 'pending')" />
            </template>
          </Column>
        </DataTable>
      </TabPanel>
      <TabPanel header="미승인 업체 목록">
        <DataTable :value="pendingCompanies" :paginator="true" :rows="10" 
                   :loading="loading" responsiveLayout="scroll" v-model:filters="filters" 
                   filterDisplay="menu" :globalFilterFields="['company_name', 'business_registration_number', 'representative_name']">
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
          <Column field="company_name" header="업체명" sortable></Column>
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
      </TabPanel>
    </TabView>

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
        
        <h3>기본 정보</h3>
        <div class="p-grid p-formgrid">
          <div class="p-field p-col-12 p-md-4">
            <label for="company_group">구분</label>
            <InputText id="company_group" v-model="newCompany.company_group" />
          </div>
          
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
          
          <div class="p-field p-col-12 p-md-4">
            <label for="default_commission_grade">수수료 등급</label>
            <Dropdown id="default_commission_grade" v-model="newCompany.default_commission_grade" :options="commissionGrades" optionLabel="name" optionValue="value" placeholder="등급 선택" />
          </div>
          
          <div class="p-field p-col-12 p-md-4">
            <label for="assigned_pharmacist_contact">관리자</label>
            <InputText id="assigned_pharmacist_contact" v-model="newCompany.assigned_pharmacist_contact" />
          </div>
        </div>
        
        <h3>기타 정보</h3>
        <div class="p-grid p-formgrid">
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
  </div>
</template>

<script setup>
import { ref, onMounted, reactive } from 'vue';
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
    
    // 관리자 계정으로 신규 사용자 생성 (Admin API 활용)
    const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
      email: newCompany.email,
      password: newCompany.password,
      email_confirm: true,  // 이메일 인증 자동 처리
      user_metadata: {
        company_name: newCompany.company_name
      }
    });
    
    if (authError) {
      console.error('Authentication 사용자 생성 오류:', authError);
      throw authError;
    }
    
    // 생성된 사용자의 UID
    const userId = authUser.user.id;
    
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
</style>