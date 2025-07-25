<template>
  <div class="admin-clients-assign-companies page-container">
    <div class="page-header-title-area">
      <div class="header-title">담당업체 지정</div>
    </div>
    <div class="filter-card">
      <div class="filter-row" style="display:flex; align-items:center; justify-content:flex-start;">
        <div style="display:flex; align-items:center;">
          <span class="filter-item p-input-icon-left" style="position:relative; width:320px;">
            <InputText
              v-model="searchInput"
              placeholder="병의원코드, 병의원명, 사업자등록번호 검색"
              class="search-input"
              @keyup.enter="doSearch"
              style="width:100%;"
            />
            <button
              v-if="searchInput.length > 0"
              class="clear-btn"
              @click="clearSearch"
              title="검색어 초기화">
              ×
            </button>
          </span>
          <button
            class="search-btn"
            :disabled="searchInput.length < 2"
            @click="doSearch">
            검색
          </button>
        </div>
      </div>
    </div>
    <div class="data-card">
      <div class="data-card-header">
        <div class="total-count-display">전체 {{ filteredClients.length }} 건</div>
        <div class="action-buttons-group">
          <button class="btn-excell-template" @click="downloadTemplate" style="margin-right: 1rem;">엑셀 템플릿</button>
          <button class="btn-excell-upload" @click="triggerFileUpload" style="margin-right: 1rem;">엑셀 등록</button>
          <button class="btn-excell-download" @click="downloadExcel" style="margin-right: 1rem;">엑셀 다운로드</button>
          <button class="btn-delete" @click="deleteAllAssignments">모두 삭제</button>
          <input
            ref="fileInput"
            type="file"
            accept=".xlsx,.xls"
            @change="handleFileUpload"
            style="display: none"
          />
        </div>
      </div>

      <DataTable
        :value="filteredClients"
        :loading="loading"
        paginator
        :rows="50"
        :rowsPerPageOptions="[20, 50, 100]"
        scrollable
        scrollHeight="calc(100vh - 250px)"
        v-model:filters="filters"
        :globalFilterFields="['client_code', 'name', 'business_registration_number']"
        class="admin-assign-companies-table"
        v-model:first="currentPageFirstIndex"
      >
        <template #empty>
          <div v-if="!loading">등록된 병의원이 없습니다.</div>
        </template>
        <template #loading>병의원 목록을 불러오는 중입니다...</template>

        <Column header="No" :headerStyle="{ width: columnWidths.no }">
          <template #body="slotProps">
            {{ slotProps.index + currentPageFirstIndex + 1 }}
          </template>
        </Column>
        <Column
          field="client_code"
          header="병의원코드"
          :headerStyle="{ width: columnWidths.client_code }"
          :sortable="true"
        />
        <Column
          field="name"
          header="병의원명"
          :headerStyle="{ width: columnWidths.name }"
          :style="{ fontWeight: '500 !important' }"  
          :sortable="true"
        >
          <template #body="slotProps">
            <span class="ellipsis-cell" :title="slotProps.data.name" @mouseenter="checkOverflow" @mouseleave="removeOverflowClass">{{ slotProps.data.name }}</span>
          </template>
        </Column>
        <Column
          field="business_registration_number"
          header="사업자등록번호"
          :headerStyle="{ width: columnWidths.business_registration_number }"
          :sortable="true"
        />
        <Column
          field="owner_name"
          header="원장명"
          :headerStyle="{ width: columnWidths.owner_name }"
          :sortable="true"
        />
        <Column
          field="address"
          header="주소"
          :headerStyle="{ width: columnWidths.address }"
          :sortable="true"
        >
          <template #body="slotProps">
            <span class="ellipsis-cell" :title="slotProps.data.address" @mouseenter="checkOverflow" @mouseleave="removeOverflowClass">{{ slotProps.data.address }}</span>
          </template>
        </Column>
        <Column header="업체명" :headerStyle="{ width: columnWidths.company_name }">
          <template #body="slotProps">
            <div v-if="slotProps.data.companies && slotProps.data.companies.length > 0">
              <div
                v-for="(company, idx) in slotProps.data.companies"
                :key="company.id"
                style="min-height: 32px; display: flex; align-items: center !important; font-weight: 500 !important;"
              >
                {{ company.company_name }}
              </div>
            </div>
            <div v-else style="min-height: 32px">-</div>
          </template>
        </Column>
        <Column header="사업자등록번호" :headerStyle="{ width: columnWidths.company_brn }">
          <template #body="slotProps">
            <div v-if="slotProps.data.companies && slotProps.data.companies.length > 0">
              <div
                v-for="(company, idx) in slotProps.data.companies"
                :key="company.id"
                style="min-height: 32px; display: flex; align-items: center !important;"
              >
                {{ company.business_registration_number }}
              </div>
            </div>
            <div v-else style="min-height: 32px">-</div>
          </template>
        </Column>
        <Column header="작업" :headerStyle="{ width: columnWidths.actions }">
          <template #body="slotProps">
            <div v-if="slotProps.data.companies && slotProps.data.companies.length > 0">
              <div
                v-for="(company, idx) in slotProps.data.companies"
                :key="company.id"
                style="min-height: 32px; display: flex; align-items: center; gap: 4px"
              >
                <button class="btn-delete-sm" @click="deleteAssignment(slotProps.data, company)">
                  삭제
                </button>
                <button
                  v-if="idx === slotProps.data.companies.length - 1"
                  class="btn-add-sm"
                  @click="openAssignModal(slotProps.data)"
                >
                  추가
                </button>
              </div>
            </div>
            <div v-else style="min-height: 32px; display: flex; align-items: center">
              <button class="btn-add-sm" @click="openAssignModal(slotProps.data)">추가</button>
            </div>
          </template>
        </Column>
      </DataTable>
    </div>

    <!-- 담당업체 지정 모달 -->
    <Dialog v-model:visible="assignModalVisible" header="업체 지정" :modal="true" :style="{ width: '60vw' }">
      <div>
        <InputText
          v-model="companySearch"
          placeholder="업체명, 사업자등록번호, 대표자명 검색"
          style="width: 100%; margin-bottom: 12px; margin-top: 0px"
          class="modal-search-input"
        />
        <DataTable
          :value="filteredCompanies"
          v-model:selection="selectedCompanies"
          selectionMode="multiple"
          class="custom-table modal-assign-companies-table"
          scrollable
          scrollHeight="480px"
        >
          <Column selectionMode="multiple" :headerStyle="{ width: '6%' }" />
          <Column
            field="company_name"
            header="업체명"
            :headerStyle="{ width: '20%' }"
            :sortable="true"
          />
          <Column
            field="business_registration_number"
            header="사업자등록번호"
            :headerStyle="{ width: '16%' }"
            :sortable="true"
          />
          <Column
            field="representative_name"
            header="대표자명"
            :headerStyle="{ width: '12%' }"
            :sortable="true"
          />
          <Column
            field="business_address"
            header="사업장 소재지"
            :headerStyle="{ width: '46%' }"
            :sortable="true"
          />
        </DataTable>
        <div style="display:flex; align-items:center; justify-content:flex-end; margin-top: 1rem;">
          <div class="btn-row">
            <button class="btn-cancel" @click="closeAssignModal" style="margin-right: 1rem;">취소</button>
            <button class="btn-save" :disabled="selectedCompanies.length === 0" @click="assignCompanies">지정</button>
          </div>
        </div>
      </div>
    </Dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, watch, computed } from 'vue'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import InputText from 'primevue/inputtext'
import Dialog from 'primevue/dialog'
import { supabase } from '@/supabase'
import * as XLSX from 'xlsx'

const clients = ref([])
const loading = ref(false)
const companies = ref([])
const filters = ref({ global: { value: null, matchMode: 'contains' } })
const assignModalVisible = ref(false)
const selectedClient = ref(null)
const selectedCompanies = ref([])
const companySearch = ref('')
const currentPageFirstIndex = ref(0)
const fileInput = ref(null)

// 컬럼 너비 한 곳에서 관리
const columnWidths = {
  no: '4%',
  client_code: '7%',
  name: '18%',
  business_registration_number: '8%',
  owner_name: '7%',
  address: '24%',
  company_name: '16%',
  company_brn: '8%',
  actions: '8%',
}

const fetchClients = async () => {
  loading.value = true;
  try {
    const { data: clientsData, error } = await supabase
      .from('clients')
      .select(
        `*, companies:client_company_assignments(company:companies(id, company_name, business_registration_number))`,
      )
      .eq('status', 'active')
    console.log('clientsData:', clientsData, 'error:', error); // ← 추가
    if (!error && clientsData) {
      clients.value = clientsData.map((client) => {
        const companiesArr = client.companies.map((c) => c.company)
        return {
          ...client,
          companies: companiesArr,
        }
      })
      filteredClients.value = clients.value;
    }
  } finally {
    loading.value = false;
  }
}
const fetchCompanies = async () => {
  const { data, error } = await supabase
    .from('companies')
    .select('*')
    .eq('approval_status', 'approved')
    .eq('status', 'active')
    .eq('user_type', 'user') // user만 불러오기
  if (!error && data) companies.value = data
}
const searchInput = ref('');
const searchKeyword = ref('');
const filteredClients = ref([]);

function doSearch() {
  if (searchInput.value.length >= 2) {
    searchKeyword.value = searchInput.value;
    const keyword = searchKeyword.value.toLowerCase();
    filteredClients.value = clients.value.filter(c =>
      (c.name && c.name.toLowerCase().includes(keyword)) ||
      (c.business_registration_number && c.business_registration_number.toLowerCase().includes(keyword)) ||
      (c.client_code && c.client_code.toLowerCase().includes(keyword))
    );
  }
}
function clearSearch() {
  searchInput.value = '';
  searchKeyword.value = '';
  filteredClients.value = clients.value;
}

// (filteredClients를 ref로만 관리, 검색 버튼/X버튼/검색 버튼 클릭 시에만 갱신)

const filteredCompanies = computed(() => {
  if (!companySearch.value) return companies.value
  const search = companySearch.value.toLowerCase()
  return companies.value.filter(
    (c) =>
      c.company_name.toLowerCase().includes(search) ||
      c.business_registration_number.includes(search) ||
      c.representative_name.toLowerCase().includes(search),
  )
})
function openAssignModal(client) {
  selectedClient.value = client
  selectedCompanies.value = []
  assignModalVisible.value = true
}
function closeAssignModal() {
  assignModalVisible.value = false
  selectedClient.value = null
  selectedCompanies.value = []
}
async function assignCompanies() {
  if (!selectedClient.value || selectedCompanies.value.length === 0) return
  const assignments = selectedCompanies.value.map((company) => ({
    client_id: selectedClient.value.id,
    company_id: company.id,
  }))
  await supabase
    .from('client_company_assignments')
    .upsert(assignments, { onConflict: 'client_id,company_id' })
  closeAssignModal()
  await fetchClients()
}
async function deleteAssignment(client, company = null) {
  let query = supabase.from('client_company_assignments').delete().eq('client_id', client.id)
  if (company) query = query.eq('company_id', company.id)
  await query
  await fetchClients()
}

const downloadTemplate = () => {
  const templateData = [
    { '병의원 사업자등록번호': '123-45-67890', '업체 사업자등록번호': '111-22-33333' },
    { '병의원 사업자등록번호': '987-65-43210', '업체 사업자등록번호': '444-55-66666' },
  ]
  const ws = XLSX.utils.json_to_sheet(templateData)
  const wb = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(wb, ws, '담당업체지정템플릿')
  ws['!cols'] = [{ width: 20 }, { width: 20 }] // 컬럼 너비 조정
  XLSX.writeFile(wb, '병의원-업체매핑_엑셀등록_템플릿.xlsx') // 파일명 변경
}

const triggerFileUpload = () => {
  if (fileInput.value) {
    fileInput.value.click()
  }
}

const handleFileUpload = async (event) => {
  const file = event.target.files[0]
  if (!file) return

  try {
    const data = await file.arrayBuffer()
    const workbook = XLSX.read(data)
    const worksheet = workbook.Sheets[workbook.SheetNames[0]]
    const jsonData = XLSX.utils.sheet_to_json(worksheet)

    if (jsonData.length === 0) {
      alert('엑셀 파일에 데이터가 없습니다.')
      return
    }

    const assignmentsToUpload = []
    const errors = []

    // 모든 병의원 및 업체 정보를 미리 로드하여 ID 조회용으로 사용 (성능 최적화)
    const { data: allClientsData, error: clientError } = await supabase
      .from('clients')
      .select('id, business_registration_number')
    const { data: allCompaniesData, error: companyError } = await supabase
      .from('companies')
      .select('id, business_registration_number')

    if (clientError || companyError) {
      alert('병의원 또는 업체 정보 조회 중 오류가 발생했습니다.')
      console.error(clientError || companyError)
      return
    }

    const clientMap = new Map(allClientsData.map((c) => [c.business_registration_number, c.id]))
    const companyMap = new Map(allCompaniesData.map((c) => [c.business_registration_number, c.id]))

    for (const [index, row] of jsonData.entries()) {
      const rowNum = index + 2
      const clientBrn = row['병의원 사업자등록번호']
      const companyBrn = row['업체 사업자등록번호']

      if (!clientBrn || !companyBrn) {
        errors.push(`${rowNum}행: 병의원 또는 업체의 사업자등록번호가 비어있습니다.`)
        continue
      }

      const clientId = clientMap.get(String(clientBrn))
      const companyId = companyMap.get(String(companyBrn))

      if (!clientId) {
        errors.push(
          `${rowNum}행: 병의원 사업자등록번호 '${clientBrn}'에 해당하는 병의원을 찾을 수 없습니다.`,
        )
      }
      if (!companyId) {
        errors.push(
          `${rowNum}행: 업체 사업자등록번호 '${companyBrn}'에 해당하는 업체를 찾을 수 없습니다.`,
        )
      }

      if (clientId && companyId) {
        assignmentsToUpload.push({ client_id: clientId, company_id: companyId })
      }
    }

    if (errors.length > 0) {
      alert('데이터 오류:\n' + errors.join('\n'))
      return
    }

    if (assignmentsToUpload.length > 0) {
      const { error } = await supabase
        .from('client_company_assignments')
        .upsert(assignmentsToUpload, { onConflict: 'client_id,company_id' })
      if (error) {
        alert('업로드 실패: ' + error.message)
      } else {
        alert(`${assignmentsToUpload.length}건의 담당업체 지정 정보가 업로드/갱신되었습니다.`)
        await fetchClients() // 목록 새로고침
      }
    }
  } catch (error) {
    console.error('파일 처리 오류:', error)
    alert('파일 처리 중 오류가 발생했습니다.')
  } finally {
    if (event.target) {
      event.target.value = ''
    }
  }
}

const downloadExcel = () => {
  if (filteredClients.value.length === 0) {
    alert('다운로드할 데이터가 없습니다.')
    return
  }
  const excelData = []
  filteredClients.value.forEach((client) => {
    if (client.companies && client.companies.length > 0) {
      client.companies.forEach((company) => {
        excelData.push({
          병의원ID: client.id,
          병의원코드: client.client_code,
          병의원명: client.name,
          사업자등록번호: client.business_registration_number,
          원장명: client.owner_name,
          주소: client.address,
          업체ID: company.id,
          '지정된 업체명': company.company_name,
          '지정된 업체 사업자번호': company.business_registration_number,
        })
      })
    } else {
      excelData.push({
        병의원ID: client.id,
        병의원코드: client.client_code,
        병의원명: client.name,
        사업자등록번호: client.business_registration_number,
        원장명: client.owner_name,
        주소: client.address,
        업체ID: '-',
        '지정된 업체명': '-',
        '지정된 업체 사업자번호': '-',
      })
    }
  })

  const ws = XLSX.utils.json_to_sheet(excelData)
  const wb = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(wb, ws, '담당업체지정현황')
  const today = new Date().toISOString().split('T')[0]
  XLSX.writeFile(wb, `담당업체지정현황_${today}.xlsx`)
}

onMounted(() => {
  fetchClients()
  fetchCompanies()
})
</script>