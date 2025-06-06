<template>
  <div class="admin-clients-view page-container">
    <div class="page-header-title-area">
      <div class="header-title">거래처 목록</div>
    </div>
    <div class="filter-card">
      <div class="filter-row">
        <span class="p-input-icon-left">
          <InputText
            v-model="filters['global'].value"
            placeholder="거래처코드, 병의원명, 사업자등록번호 검색"
            class="search-input"
          />
        </span>
      </div>
    </div>
    <div class="data-card">
      <div class="data-card-header">
        <div class="total-count-display">
          전체 {{ clients.length }} 건
        </div>
        <div class="action-buttons-group">
          <button class="btn-excell-template" @click="downloadTemplate">엑셀 템플릿</button>
          <button class="btn-excell-upload" @click="triggerFileUpload">엑셀 등록</button>
          <button class="btn-excell-download" @click="downloadExcel">엑셀 다운로드</button>
          <button class="btn-delete" @click="deleteAllClients">모두 삭제</button>
          <input
            ref="fileInput"
            type="file"
            accept=".xlsx,.xls"
            @change="handleFileUpload"
            style="display: none"
          />
          <button class="btn-save" @click="goCreate">개별 등록</button>
        </div>
      </div>
      <DataTable
        :value="clients"
        paginator
        :rows="20"
        :rowsPerPageOptions="[20, 50, 100]"
        scrollable
        scrollHeight="calc(100vh - 250px)"
        v-model:filters="filters"
        :globalFilterFields="['client_code', 'name', 'business_registration_number']"
        class="admin-clients-table"
        v-model:first="currentPageFirstIndex"
      >
        <template #empty>등록된 거래처가 없습니다.</template>
        <template #loading>거래처 목록을 불러오는 중입니다...</template>
        <Column header="No" :headerStyle="{ width: columnWidths.no }">
          <template #body="slotProps">
            {{ slotProps.index + currentPageFirstIndex + 1 }}
          </template>
        </Column>
        <Column
          field="client_code"
          header="거래처코드"
          :headerStyle="{ width: columnWidths.client_code }"
          :sortable="true"
        >
          <template #body="slotProps">
            <input
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.client_code"
              class="inline-edit-input"
            />
            <span v-else>{{ slotProps.data.client_code }}</span>
          </template>
        </Column>
        <Column field="name" header="병의원명" :headerStyle="{ width: columnWidths.name }" :sortable="true">
          <template #body="slotProps">
            <input
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.name"
              class="inline-edit-input"
            />
            <a v-else href="#" style="color: #1976d2; text-decoration: underline; cursor: pointer" @click.prevent="goToDetail(slotProps.data.id)">
              {{ slotProps.data.name }}
            </a>
          </template>
        </Column>
        <Column
          field="business_registration_number"
          header="사업자등록번호"
          :headerStyle="{ width: columnWidths.business_registration_number }"
          :sortable="true"
        >
          <template #body="slotProps">
            <input
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.business_registration_number"
              class="inline-edit-input"
            />
            <span v-else>{{ slotProps.data.business_registration_number }}</span>
          </template>
        </Column>
        <Column field="owner_name" header="원장명" :headerStyle="{ width: columnWidths.owner_name }" :sortable="true">
          <template #body="slotProps">
            <input
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.owner_name"
              class="inline-edit-input"
            />
            <span v-else>{{ slotProps.data.owner_name }}</span>
          </template>
        </Column>
        <Column field="address" header="주소" :headerStyle="{ width: columnWidths.address }" :sortable="true">
          <template #body="slotProps">
            <input
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.address"
              class="inline-edit-input"
            />
            <span v-else>{{ slotProps.data.address }}</span>
          </template>
        </Column>
        <Column field="remarks" header="비고" :headerStyle="{ width: columnWidths.remarks }" :sortable="true">
          <template #body="slotProps">
            <input
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.remarks"
              class="inline-edit-input"
            />
            <span v-else>{{ slotProps.data.remarks }}</span>
          </template>
        </Column>
        <Column field="created_at" header="등록일자" :headerStyle="{ width: columnWidths.created_at }" :sortable="true">
          <template #body="slotProps">
            <span>{{
              slotProps.data.created_at
                ? new Date(slotProps.data.created_at).toISOString().split('T')[0]
                : ''
            }}</span>
          </template>
        </Column>
        <Column field="status" header="상태" :headerStyle="{ width: columnWidths.status }" :sortable="true">
          <template #body="slotProps">
            <select
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.status"
              class="inline-edit-input"
            >
              <option value="active">활성</option>
              <option value="inactive">비활성</option>
            </select>
            <span
              v-else
              :class="slotProps.data.status === 'active' ? 'active-badge' : 'inactive-badge'"
            >
              {{ slotProps.data.status === 'active' ? '활성' : '비활성' }}
            </span>
          </template>
        </Column>
        <Column header="작업" :headerStyle="{ width: columnWidths.actions }">
          <template #body="slotProps">
            <div style="display: flex; gap: 4px; justify-content: center">
              <template v-if="slotProps.data.isEditing">
                <button class="btn-save-sm" @click="saveEdit(slotProps.data)" title="저장">
                  저장
                </button>
                <button class="btn-cancel-sm" @click="cancelEdit(slotProps.data)" title="취소">
                  취소
                </button>
              </template>
              <template v-else>
                <button class="btn-edit-sm" @click="startEdit(slotProps.data)" title="수정">
                  수정
                </button>
                <button class="btn-delete-sm" @click="deleteClient(slotProps.data)" title="삭제">
                  삭제
                </button>
              </template>
            </div>
          </template>
        </Column>
      </DataTable>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import InputText from 'primevue/inputtext'
import { useRouter } from 'vue-router'
import { supabase } from '@/supabase'
import * as XLSX from 'xlsx'

const clients = ref([])
const filters = ref({ global: { value: null, matchMode: 'contains' } })
const router = useRouter()
const fileInput = ref(null)
const currentPageFirstIndex = ref(0)

// 컬럼 너비 한 곳에서 관리
const columnWidths = {
  no: '4%',
  client_code: '7%',
  name: '18%',
  business_registration_number: '8%',
  owner_name: '7%',
  address: '24%',
  remarks: '10%',
  created_at: '8%',
  status: '6%',
  actions: '8%'
};

function goCreate() {
  router.push('/admin/clients/create')
}
function goToDetail(id) {
  router.push(`/admin/clients/${id}`)
}

const fetchClients = async () => {
  const { data, error } = await supabase
    .from('clients')
    .select('*')
    .order('client_code', { ascending: true })
  if (!error && data) {
    // 각 행에 편집 상태와 원본 데이터 백업 추가
    clients.value = data.map((item) => ({
      ...item,
      isEditing: false,
      originalData: { ...item },
    }))
  }
}

// 수정 시작
const startEdit = (row) => {
  // 다른 행이 편집 중이면 취소
  clients.value.forEach((item) => {
    if (item.isEditing && item.id !== row.id) {
      cancelEdit(item)
    }
  })

  // 원본 데이터 백업
  row.originalData = { ...row }
  row.isEditing = true
}

// 수정 취소
const cancelEdit = (row) => {
  // 원본 데이터로 복원
  Object.keys(row.originalData).forEach((key) => {
    if (key !== 'isEditing' && key !== 'originalData') {
      row[key] = row.originalData[key]
    }
  })
  row.isEditing = false
}

// 수정 저장
const saveEdit = async (row) => {
  try {
    // 필수 필드 검증
    if (!row.name || !row.business_registration_number) {
      alert('필수 항목을 모두 입력하세요. (병의원명, 사업자등록번호)')
      return
    }

    // 상태 값 검증
    if (!['active', 'inactive'].includes(row.status)) {
      alert('상태는 active 또는 inactive여야 합니다.')
      return
    }

    const updateData = {
      client_code: row.client_code || '',
      name: row.name,
      business_registration_number: row.business_registration_number,
      owner_name: row.owner_name || '',
      address: row.address || '',
      remarks: row.remarks || '',
      status: row.status,
    }

    const { error } = await supabase.from('clients').update(updateData).eq('id', row.id)

    if (error) {
      alert('수정 실패: ' + error.message)
      return
    }

    // 편집 모드 종료
    row.isEditing = false
    row.originalData = { ...row }

    alert('수정되었습니다.')
  } catch (error) {
    console.error('수정 오류:', error)
    alert('수정 중 오류가 발생했습니다.')
  }
}

// 삭제
const deleteClient = async (row) => {
  if (!confirm('정말 삭제하시겠습니까?')) {
    return
  }

  try {
    const { error } = await supabase.from('clients').delete().eq('id', row.id)

    if (error) {
      alert('삭제 실패: ' + error.message)
      return
    }

    // 목록에서 제거
    const index = clients.value.findIndex((item) => item.id === row.id)
    if (index > -1) {
      clients.value.splice(index, 1)
    }

    alert('삭제되었습니다.')
  } catch (error) {
    console.error('삭제 오류:', error)
    alert('삭제 중 오류가 발생했습니다.')
  }
}

// 엑셀 템플릿 다운로드
const downloadTemplate = () => {
  const templateData = [
    {
      거래처코드: '10001',
      병의원명: '강남사랑병원',
      사업자등록번호: '123-45-67890',
      원장명: '홍길동',
      주소: '서울시 강남구 테헤란로 123',
      비고: '',
      상태: '활성',
    },
  ]

  const ws = XLSX.utils.json_to_sheet(templateData)
  const wb = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(wb, ws, '거래처템플릿')

  // 컬럼 너비 설정
  ws['!cols'] = [
    { width: 12 }, // 거래처코드
    { width: 25 }, // 병의원명
    { width: 15 }, // 사업자등록번호
    { width: 12 }, // 원장명
    { width: 40 }, // 주소
    { width: 20 }, // 비고
    { width: 10 }, // 상태
  ]

  XLSX.writeFile(wb, '거래처_엑셀등록_템플릿.xlsx')
}

// 파일 업로드 트리거
const triggerFileUpload = () => {
  fileInput.value.click()
}

// 엑셀 파일 업로드 처리
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

    // 데이터 변환 및 검증
    const uploadData = []
    const errors = []

    jsonData.forEach((row, index) => {
      const rowNum = index + 2 // 엑셀 행 번호 (헤더 제외)

      // 필수 필드 검증
      if (!row['병의원명']) {
        errors.push(`${rowNum}행: 병의원명이 필요합니다.`)
        return
      }
      if (!row['사업자등록번호']) {
        errors.push(`${rowNum}행: 사업자등록번호가 필요합니다.`)
        return
      }

      // 상태 값 검증 및 변환
      let statusValue = 'active' // 기본값
      if (row['상태']) {
        if (row['상태'] === '활성') {
          statusValue = 'active'
        } else if (row['상태'] === '비활성') {
          statusValue = 'inactive'
        } else {
          errors.push(`${rowNum}행: 상태는 '활성' 또는 '비활성'이어야 합니다.`)
          return
        }
      } else {
        // 상태 값이 비어있으면 기본값 '활성'('active') 사용
        statusValue = 'active'
      }

      uploadData.push({
        client_code: row['거래처코드'] || '',
        name: row['병의원명'],
        business_registration_number: row['사업자등록번호'],
        owner_name: row['원장명'] || '',
        address: row['주소'] || '',
        remarks: row['비고'] || '',
        status: statusValue, // 변환된 값 사용
      })
    })

    if (errors.length > 0) {
      alert('데이터 오류:\n' + errors.join('\n'))
      return
    }

    // 데이터베이스에 일괄 삽입
    const { error } = await supabase.from('clients').insert(uploadData)

    if (error) {
      alert('업로드 실패: ' + error.message)
    } else {
      alert(`${uploadData.length}건의 거래처 데이터가 업로드되었습니다.`)
      await fetchClients() // 목록 새로고침
    }
  } catch (error) {
    console.error('파일 처리 오류:', error)
    alert('파일 처리 중 오류가 발생했습니다.')
  } finally {
    // 파일 입력 초기화
    event.target.value = ''
  }
}

// 엑셀 다운로드 (현재 목록)
const downloadExcel = () => {
  if (clients.value.length === 0) {
    alert('다운로드할 데이터가 없습니다.')
    return
  }

  // 데이터 변환
  const excelData = clients.value.map((client) => ({
    ID: client.id,
    거래처코드: client.client_code || '',
    병의원명: client.name || '',
    사업자등록번호: client.business_registration_number || '',
    원장명: client.owner_name || '',
    주소: client.address || '',
    비고: client.remarks || '',
    상태: client.status === 'active' ? '활성' : '비활성',
    등록일: client.created_at ? new Date(client.created_at).toISOString().split('T')[0] : '',
    수정일: client.updated_at ? new Date(client.updated_at).toISOString().split('T')[0] : '',
  }))

  const ws = XLSX.utils.json_to_sheet(excelData)
  const wb = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(wb, ws, '거래처목록')

  // 컬럼 너비 설정
  ws['!cols'] = [
    { width: 10 }, // ID
    { width: 12 }, // 거래처코드
    { width: 20 }, // 병의원명
    { width: 15 }, // 사업자등록번호
    { width: 12 }, // 원장명
    { width: 30 }, // 주소
    { width: 20 }, // 비고
    { width: 10 }, // 상태
    { width: 12 }, // 등록일
    { width: 12 }, // 수정일
  ]

  // 파일명에 현재 날짜 포함
  const today = new Date().toISOString().split('T')[0]
  const fileName = `거래처목록_${today}.xlsx`

  XLSX.writeFile(wb, fileName)
}

async function deleteAllClients() {
  if (!confirm('정말 모든 거래처를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.')) return;
  // 거래처 전체 삭제
  const { error: clientError } = await supabase.from('clients').delete().neq('id', 0);
  // 담당업체 지정 전체 삭제
  await supabase.from('client_company_assignments').delete().neq('id', 0);
  // 문전약국 지정 전체 삭제
  await supabase.from('client_pharmacy_assignments').delete().neq('id', 0);
  if (clientError) {
    alert('삭제 중 오류가 발생했습니다: ' + clientError.message);
    return;
  }
  clients.value = [];
  alert('모든 거래처 및 관련 지정 데이터가 삭제되었습니다.');
}

onMounted(() => {
  fetchClients()
})
</script>
