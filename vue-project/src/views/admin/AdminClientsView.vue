<template>
  <div class="admin-clients-view page-container">
    <div class="page-header-title-area">
      <div class="header-title">병의원 목록</div>
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
        <div class="total-count-display">
          전체 {{ filteredClients.length }} 건
        </div>
        <div class="action-buttons-group">
          <button class="btn-excell-template" @click="downloadTemplate" style="margin-right: 1rem;">엑셀 템플릿</button>
          <button class="btn-excell-upload" @click="triggerFileUpload" style="margin-right: 1rem;">엑셀 등록</button>
          <button class="btn-excell-download" @click="downloadExcel" style="margin-right: 1rem;">엑셀 다운로드</button>
          <button class="btn-delete" @click="deleteAllClients" style="margin-right: 1rem;">모두 삭제</button>
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
        :value="filteredClients"
        :loading="loading"
        paginator
        :rows="50"
        :rowsPerPageOptions="[20, 50, 100]"
        scrollable
        scrollHeight="calc(100vh - 250px)"
        class="admin-clients-table"
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
              :id="`name_${slotProps.data.id}`"
            />
            <a v-else href="#" class="text-link ellipsis-cell" :title="slotProps.data.name" @click.prevent="goToDetail(slotProps.data.id)" @mouseenter="checkOverflow" @mouseleave="removeOverflowClass">
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
              :id="`business_registration_number_${slotProps.data.id}`"
              @input="formatBusinessNumber"
              @keypress="allowOnlyNumbers"
              @keydown="handleBackspace"
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
            <span v-else class="ellipsis-cell" :title="slotProps.data.address" @mouseenter="checkOverflow" @mouseleave="removeOverflowClass">{{ slotProps.data.address }}</span>
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
                <button class="btn-save-sm" @click="saveEdit(slotProps.data)" :disabled="!isEditValid(slotProps.data)" title="저장">
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
import { ref, onMounted, watch } from 'vue'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import InputText from 'primevue/inputtext'
import { useRouter } from 'vue-router'
import { supabase } from '@/supabase'
import * as XLSX from 'xlsx'
import { generateExcelFileName } from '@/utils/excelUtils'

const clients = ref([])
const loading = ref(false)
const searchInput = ref('');
const searchKeyword = ref('');
const filteredClients = ref([]);
const currentPageFirstIndex = ref(0)
const filterBackup = ref(null)

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

const isAnyEditing = ref(false); // 편집 중인 행이 있는지 확인
const router = useRouter();
const fileInput = ref(null)

function goCreate() {
  router.push('/admin/clients/create')
}
function goToDetail(id) {
  router.push(`/admin/clients/${id}`)
}

const fetchClients = async () => {
  loading.value = true;
  try {
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
      filteredClients.value = clients.value;
    }
  } finally {
    loading.value = false;
  }
}

// 수정 시작
const startEdit = (row) => {
  // 편집 시작 시 검색어 백업 및 필터 해제
  if (filterBackup.value === null) {
    filterBackup.value = searchInput.value
    searchInput.value = ''
  }
  // 다른 행이 편집 중이면 취소
  clients.value.forEach((item) => {
    if (item.isEditing && item.id !== row.id) {
      cancelEdit(item)
    }
  })

  // 원본 데이터 백업
  row.originalData = { ...row }
  row.isEditing = true
  isAnyEditing.value = true; // 편집 중인 행이 있음을 표시
}

// 변경값 감지 및 필수값 검증
const isEditValid = (row) => {
  // 필수값 검증
  const hasRequiredFields = row.name && row.name.trim() !== '' && 
                           row.business_registration_number && row.business_registration_number.trim() !== '';
  
  // 변경값 감지
  const hasChanges = row.client_code !== row.originalData.client_code ||
                    row.name !== row.originalData.name ||
                    row.business_registration_number !== row.originalData.business_registration_number ||
                    row.owner_name !== row.originalData.owner_name ||
                    row.address !== row.originalData.address ||
                    row.status !== row.originalData.status ||
                    row.remarks !== row.originalData.remarks;
  
  return hasRequiredFields && hasChanges;
}

// 수정 취소
const cancelEdit = (row) => {
  // 편집 취소 시 검색어 복원
  if (filterBackup.value !== null) {
    searchInput.value = filterBackup.value
    filterBackup.value = null
  }
  // 원본 데이터로 복원
  Object.keys(row.originalData).forEach((key) => {
    if (key !== 'isEditing' && key !== 'originalData') {
      row[key] = row.originalData[key]
    }
  })
  row.isEditing = false
  isAnyEditing.value = false; // 편집 중인 행이 없음을 표시
}

// 수정 저장
const saveEdit = async (row) => {
  try {
    // 필수 필드 검증
    if (!row.name || row.name.trim() === '') {
      alert('병의원명은 필수 입력 항목입니다.');
      setTimeout(() => {
        const nameInput = document.getElementById(`name_${row.id}`);
        if (nameInput) {
          nameInput.focus();
          nameInput.select();
        }
      }, 100);
      return;
    }

    if (!row.business_registration_number || row.business_registration_number.trim() === '') {
      alert('사업자등록번호는 필수 입력 항목입니다.');
      setTimeout(() => {
        const businessNumberInput = document.getElementById(`business_registration_number_${row.id}`);
        if (businessNumberInput) {
          businessNumberInput.focus();
          businessNumberInput.select();
        }
      }, 100);
      return;
    }

    // 사업자등록번호 형식 검증 (10자리 숫자)
    const businessNumberDigits = row.business_registration_number.replace(/[^0-9]/g, '');
    if (businessNumberDigits.length !== 10) {
      alert('사업자등록번호는 10자리여야 합니다.');
      setTimeout(() => {
        const businessNumberInput = document.getElementById(`business_registration_number_${row.id}`);
        if (businessNumberInput) {
          businessNumberInput.focus();
          businessNumberInput.select();
        }
      }, 100);
      return;
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
    // 편집 저장 후 검색어 복원
    if (filterBackup.value !== null) {
      searchInput.value = filterBackup.value
      filterBackup.value = null
    }

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
      병의원코드: '10001',
      병의원명: '강남사랑병원',
      사업자등록번호: '123-45-67890',
      원장명: '홍길동',
      주소: '서울시 강남구 테헤란로 123',
      비고: '',
      상태: '활성',
    },
    {
      병의원코드: '10002',
      병의원명: '테스트병원',
      사업자등록번호: '012-34-56789', // 앞자리 0이 있는 예시
      원장명: '김철수',
      주소: '서울시 서초구 서초대로 456',
      비고: '예시',
      상태: '활성',
    },
  ]

  const ws = XLSX.utils.json_to_sheet(templateData)
  const wb = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(wb, ws, '병의원템플릿')

  // 컬럼 너비 설정
  ws['!cols'] = [
    { width: 12 }, // 병의원코드
    { width: 25 }, // 병의원명
    { width: 15 }, // 사업자등록번호
    { width: 12 }, // 원장명
    { width: 40 }, // 주소
    { width: 20 }, // 비고
    { width: 10 }, // 상태
  ]

  // 사업자등록번호(C열) 전체를 텍스트 형식으로 설정 (1000행까지)
  const maxRows = 1000;
  
  for (let row = 0; row < maxRows; row++) {
    // C열 (사업자등록번호) - 빈 셀이라도 텍스트 형식으로 설정
    const cellC = XLSX.utils.encode_cell({ r: row, c: 2 })
    if (!ws[cellC]) {
      ws[cellC] = { t: 's', v: '', z: '@' } // 빈 텍스트 셀 생성
    } else {
      ws[cellC].t = 's' // 문자열 타입
      ws[cellC].z = '@' // 텍스트 형식
    }
  }
  
  // 워크시트 범위 업데이트 (1000행까지 확장)
  ws['!ref'] = XLSX.utils.encode_range({
    s: { c: 0, r: 0 },
    e: { c: 6, r: maxRows - 1 }
  })

  XLSX.writeFile(wb, '병의원_엑셀등록_템플릿.xlsx')
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

    // 기존 데이터 확인
    const hasExistingData = clients.value.length > 0

    // 1단계: 기존 데이터 존재 시 확인
    let isAppendMode = false
    if (hasExistingData) {
      if (!confirm('기존 데이터가 있습니다.\n계속 등록하시겠습니까?')) {
        event.target.value = ''
        return
      }

      // 2단계: 추가 vs 대체 선택
      isAppendMode = confirm('기존 데이터에 추가하시겠습니까? 대체하시겠습니까?\n\n확인: 기존 데이터는 그대로 추가 등록\n취소: 기존 데이터를 모두 지우고 등록')
      
      if (!isAppendMode) {
        // 대체 모드: 기존 데이터 삭제
        const { error: deleteError } = await supabase.from('clients').delete().neq('id', 0)
        
        if (deleteError) {
          alert('기존 데이터 삭제 실패: ' + deleteError.message)
          event.target.value = ''
          return
        }
        // 로컬 데이터도 초기화
        clients.value = []
      }
    }

    // 데이터 변환 및 검증
    let uploadData = []
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

      // 사업자등록번호 형식 검증 및 변환 (10자리 숫자)
      const businessNumber = row['사업자등록번호'].toString().replace(/[^0-9]/g, '');
      if (businessNumber.length !== 10) {
        errors.push(`${rowNum}행: 사업자등록번호는 10자리 숫자여야 합니다.`)
        return
      }
      
      // 사업자등록번호 형식 변환: ###-##-#####
      const formattedBusinessNumber = businessNumber.substring(0, 3) + '-' + 
                                     businessNumber.substring(3, 5) + '-' + 
                                     businessNumber.substring(5);

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
        statusValue = 'active'
      }

      uploadData.push({
        client_code: row['병의원코드'] || '',
        name: row['병의원명'],
        business_registration_number: formattedBusinessNumber,
        owner_name: row['원장명'] || '',
        address: row['주소'] || '',
        remarks: row['비고'] || '',
        status: statusValue,
        rowNum: rowNum // 에러 표시용
      })
    })

    if (errors.length > 0) {
      alert('데이터 오류:\n' + errors.join('\n'))
      return
    }

    // 3단계: 추가 모드일 때만 사업자등록번호 중복 체크
    if (hasExistingData && isAppendMode) {
      const duplicateErrors = []
      const duplicateClients = []
      
      for (const newClient of uploadData) {
        if (newClient.business_registration_number) {
          // 기존 데이터에서 동일한 사업자등록번호 중복 확인
          const existingClient = clients.value.find(c => 
            c.business_registration_number === newClient.business_registration_number
          )
          
          if (existingClient) {
            duplicateErrors.push(`${newClient.rowNum}행: 이미 동일한 사업자등록번호의 병의원이 등록되어 있습니다.`)
            duplicateClients.push(newClient)
          }
        }
      }

      if (duplicateErrors.length > 0) {
        // 4단계: 중복 발견 시 계속 진행 여부 확인
        if (!confirm('중복 오류:\n' + duplicateErrors.join('\n') + '\n\n계속 등록 작업을 진행하시겠습니까?')) {
          return
        }

        // 5단계: 중복 해결 방법 선택
        const shouldReplace = confirm('이미 동일한 사업자등록번호 병의원을 어떻게 처리하시겠습니까?\n\n확인: 기존 병의원 정보를 신규 병의원 정보로 교체하기\n취소: 기존 병의원 정보는 그대로 두고 신규 병의원만 등록하기')
        
        if (shouldReplace) {
          // 교체 모드: 중복되는 기존 병의원들 삭제
          for (const duplicateClient of duplicateClients) {
            const { error: deleteError } = await supabase
              .from('clients')
              .delete()
              .eq('business_registration_number', duplicateClient.business_registration_number)
            
            if (deleteError) {
              alert('기존 병의원 삭제 실패: ' + deleteError.message)
              return
            }
          }
          // 로컬 데이터에서도 삭제
          for (const duplicateClient of duplicateClients) {
            const index = clients.value.findIndex(c => 
              c.business_registration_number === duplicateClient.business_registration_number
            )
            if (index > -1) {
              clients.value.splice(index, 1)
            }
          }
        } else {
          // 기존 유지 모드: 중복되는 신규 병의원들 제외
          const duplicateBusinessNumbers = duplicateClients.map(c => c.business_registration_number)
          uploadData = uploadData.filter(item => !duplicateBusinessNumbers.includes(item.business_registration_number))
        }
      }
    }

    // 최종 등록
    const insertData = uploadData.map(item => {
      const { rowNum, ...data } = item
      return data
    })

    if (insertData.length === 0) {
      alert('등록할 데이터가 없습니다.')
      return
    }

    // 데이터베이스에 일괄 삽입
    const { error } = await supabase.from('clients').insert(insertData)

    if (error) {
      alert('업로드 실패: ' + error.message)
    } else {
      alert(`${insertData.length}건의 병의원 정보가 업로드되었습니다.`)
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
    병의원코드: client.client_code || '',
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
  XLSX.utils.book_append_sheet(wb, ws, '병의원목록')

  // 컬럼 너비 설정
  ws['!cols'] = [
    { width: 10 }, // ID
    { width: 12 }, // 병의원코드
    { width: 20 }, // 병의원명
    { width: 15 }, // 사업자등록번호
    { width: 12 }, // 원장명
    { width: 30 }, // 주소
    { width: 20 }, // 비고
    { width: 10 }, // 상태
    { width: 12 }, // 등록일
    { width: 12 }, // 수정일
  ]

  const range = XLSX.utils.decode_range(ws['!ref'])
  
  // 모든 행에 대해 형식 설정
  for (let row = 0; row <= range.e.r; row++) {
    // D열 (사업자등록번호) - 텍스트 형식으로 설정
    const cellD = XLSX.utils.encode_cell({ r: row, c: 3 })
    if (ws[cellD]) {
      ws[cellD].t = 's' // 문자열 타입
      ws[cellD].z = '@' // 텍스트 형식
    }
  }

  const fileName = generateExcelFileName('병의원목록')

  XLSX.writeFile(wb, fileName)
}

async function deleteAllClients() {
  if (!confirm('정말 모든 병의원 정보를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.')) return;
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
  alert('모든 병의원 및 관련 지정 데이터가 삭제되었습니다.');
}

// 오버플로우 감지 및 툴팁 제어 함수들
const checkOverflow = (event) => {
  const element = event.target;
  
  // 실제 오버플로우 감지
  const rect = element.getBoundingClientRect();
  const computedStyle = window.getComputedStyle(element);
  const fontSize = parseFloat(computedStyle.fontSize);
  const fontFamily = computedStyle.fontFamily;
  
  // 임시 캔버스를 만들어서 텍스트의 실제 너비 측정
  const canvas = document.createElement('canvas');
  const context = canvas.getContext('2d');
  context.font = `${fontSize}px ${fontFamily}`;
  const textWidth = context.measureText(element.textContent).width;
  
  // 패딩과 보더 고려
  const paddingLeft = parseFloat(computedStyle.paddingLeft) || 0;
  const paddingRight = parseFloat(computedStyle.paddingRight) || 0;
  const borderLeft = parseFloat(computedStyle.borderLeftWidth) || 0;
  const borderRight = parseFloat(computedStyle.borderRightWidth) || 0;
  
  const availableWidth = rect.width - paddingLeft - paddingRight - borderLeft - borderRight;
  const isOverflowed = textWidth > availableWidth;
  
  console.log('병의원 오버플로우 체크:', {
    text: element.textContent,
    textWidth,
    availableWidth,
    isOverflowed
  });
  
  if (isOverflowed) {
    element.classList.add('overflowed');
    console.log('병의원 오버플로우 클래스 추가됨');
  } else {
    element.classList.remove('overflowed'); // Ensure class is removed if not overflowed
    console.log('병의원 오버플로우 아님 - 클래스 제거됨');
  }
}

const removeOverflowClass = (event) => {
  const element = event.target;
  element.classList.remove('overflowed');
  console.log('병의원 오버플로우 클래스 제거됨');
}

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

// 숫자만 입력 허용
const allowOnlyNumbers = (event) => {
  const charCode = event.which ? event.which : event.keyCode;
  if (charCode > 31 && (charCode < 48 || charCode > 57)) {
    event.preventDefault();
  }
};

// 사업자등록번호 형식 변환
const formatBusinessNumber = (event) => {
  const target = event.target;
  let value = target.value.replace(/[^0-9]/g, ''); // 숫자만 추출
  
  if (value.length > 10) {
    value = value.substring(0, 10); // 최대 10자리로 제한
  }
  
  // 형식 변환: ###-##-#####
  if (value.length >= 3) {
    value = value.substring(0, 3) + '-' + value.substring(3);
  }
  if (value.length >= 6) {
    value = value.substring(0, 6) + '-' + value.substring(6);
  }
  
  // 최대 12자리(하이픈 포함)로 제한
  if (value.length > 12) {
    value = value.substring(0, 12);
  }
  
  target.value = value;
};

// 백스페이스 처리 (하이픈 건너뛰기)
const handleBackspace = (event) => {
  if (event.key === 'Backspace') {
    const cursorPosition = event.target.selectionStart;
    const value = event.target.value;
    
    // 커서 위치에 하이픈이 있으면 한 칸 더 뒤로 이동
    if (value[cursorPosition - 1] === '-') {
      event.preventDefault();
      const newPosition = cursorPosition - 2;
      event.target.value = value.substring(0, newPosition) + value.substring(cursorPosition);
      
      // 커서 위치 조정
      setTimeout(() => {
        event.target.setSelectionRange(newPosition, newPosition);
      }, 0);
    }
  }
};

onMounted(() => {
  fetchClients()
})
</script>

<style scoped>
.btn-save-sm:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
</style>
