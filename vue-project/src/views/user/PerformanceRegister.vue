<template>
  <div class="performance-register-view page-container">
    <div class="page-header-title-area">
      <div class="header-title">실적 등록</div>
    </div>

    <!-- 필터 카드: 정산월 드롭다운 -->
    <div class="filter-card">
      <div class="filter-row" style="justify-content: flex-start; align-items: flex-end">
        <div style="display: flex; align-items: center; gap: 8px">
          <label style="font-weight: 400">정산월</label>
          <select v-model="selectedSettlementMonth" class="select_month">
            <option v-for="month in availableMonths" :key="month" :value="month">
              {{ month }}
            </option>
          </select>
        </div>
      </div>
    </div>

    <!-- 데이터 카드: 전체 n건 + 테이블 + 합계 행 -->
    <div class="data-card">
      <div class="data-card-header">
        <div class="total-count-display">전체 {{ clientList.length }} 건</div>
        <div class="data-card-buttons">
          <button
            class="btn-excell-template"
            @click="downloadExcelTemplate"
            :disabled="!selectedSettlementMonth"
          >
            엑셀 템플릿 다운로드
          </button>
          <button
            class="btn-excell-download"
            @click="triggerExcelUpload"
            :disabled="!selectedSettlementMonth"
          >
            엑셀 일괄 등록
          </button>
          <input
            ref="excelFileInput"
            type="file"
            accept=".xlsx,.xls"
            @change="handleExcelUpload"
            style="display: none"
          />
          <button
            class="btn-excell-download"
            @click="downloadExcel"
            :disabled="clientList.length === 0"
          >
            엑셀 다운로드
          </button>
        </div>
      </div>
      <DataTable
        :value="clientList"
        scrollable
        scrollHeight="calc(100vh - 250px)"
        class="custom-table performance-register-table"
      >
        <template #empty>등록된 거래처가 없습니다.</template>
        <template #loading>거래처 목록을 불러오는 중입니다...</template>

        <!-- No 컬럼 -->
        <Column header="No" :headerStyle="{ width: columnWidths.no, textAlign: 'center' }">
          <template #body="slotProps">
            {{ slotProps.index + 1 }}
          </template>
        </Column>
        <!-- 거래처 정보 -->
        <Column
          field="client_code"
          header="거래처코드"
          :headerStyle="{ width: columnWidths.client_code, textAlign: 'center' }"
        />
        <Column header="병의원명" :headerStyle="{ width: columnWidths.name, textAlign: 'center' }">
          <template #body="slotProps">
            <span
              :title="slotProps.data.name"
              style="
                display: block;
                width: 100%;
                overflow: hidden;
                text-overflow: ellipsis;
                white-space: nowrap;
                font-weight: 500;
              "
            >
              {{ slotProps.data.name }}
            </span>
          </template>
        </Column>
        <Column
          field="business_registration_number"
          header="사업자등록번호"
          :headerStyle="{ width: columnWidths.business_registration_number, textAlign: 'center' }"
        />
        <Column header="주소" :headerStyle="{ width: columnWidths.address, textAlign: 'center' }">
          <template #body="slotProps">
            <span
              :title="slotProps.data.address"
              style="
                display: block;
                max-width: 100%;
                width: 100%;
                overflow: hidden;
                text-overflow: ellipsis;
                white-space: nowrap;
                box-sizing: border-box;
              "
            >
              {{ slotProps.data.address }}
            </span>
          </template>
        </Column>

        <!-- 실적 정보 -->
        <Column
          header="처방건수"
          :headerStyle="{ width: columnWidths.performance_count, textAlign: 'center' }"
        >
          <template #body="slotProps">
            {{ slotProps.data.performance_count ? slotProps.data.performance_count : '-' }}
          </template>
        </Column>
        <Column
          header="처방액"
          :headerStyle="{ width: columnWidths.total_prescription_amount, textAlign: 'center' }"
        >
          <template #body="slotProps">
            {{
              slotProps.data.total_prescription_amount
                ? formatNumber(slotProps.data.total_prescription_amount)
                : '-'
            }}
          </template>
        </Column>

        <!-- 버튼 영역 -->
        <Column
          header="조회"
          :headerStyle="{ width: columnWidths.view_button, textAlign: 'center' }"
        >
          <template #body="slotProps">
            <button
              class="btn-view-sm"
              @click="viewDetails(slotProps.data)"
              :disabled="!isInputPeriod || !(slotProps.data.performance_count > 0)"
            >
              조회
            </button>
          </template>
        </Column>
        <Column
          header="등록"
          :headerStyle="{ width: columnWidths.input_button, textAlign: 'center' }"
        >
          <template #body="slotProps">
            <button
              class="btn-input-sm"
              @click="registerPerformance(slotProps.data)"
              :disabled="!isInputPeriod"
            >
              등록
            </button>
          </template>
        </Column>
        <Column
          header="증빙 파일"
          :headerStyle="{ width: columnWidths.evidence_files_count, textAlign: 'center' }"
        >
          <template #body="slotProps">
            {{ slotProps.data.evidence_files_count ? slotProps.data.evidence_files_count : '-' }}
          </template>
        </Column>
        <Column
          header="파일 보기"
          :headerStyle="{ width: columnWidths.view_files_button, textAlign: 'center' }"
        >
          <template #body="slotProps">
            <button
              class="btn-view-sm"
              @click="openDetailModal(slotProps.data)"
              :disabled="!isInputPeriod || !(slotProps.data.evidence_files_count > 0)"
            >
              보기
            </button>
          </template>
        </Column>
        <Column
          header="업로드"
          :headerStyle="{ width: columnWidths.upload_button, textAlign: 'center' }"
        >
          <template #body="slotProps">
            <button
              class="btn-upload-sm"
              @click="openUploadModal(slotProps.data)"
              :disabled="!isInputPeriod"
            >
              업로드
            </button>
          </template>
        </Column>
      </DataTable>
      <!-- 합계 행: 테이블 하단 고정 -->
      <div
        class="table-footer-wrapper"
        style="
          width: 100%;
          padding: 0 2rem 0 0;
          background: #f8f9fa;
          height: 38px;
          border: 1px solid #dee2e6;
          border-bottom: 2px solid #aaa;
          position: sticky;
          bottom: 0;
          z-index: 2;
        "
      >
        <table style="width: 100%; table-layout: fixed">
          <tr>
            <td style="width: 52%; text-align: center; font-weight: 600">합계</td>
            <td style="width: 7%; text-align: center; font-weight: 600">
              {{ totalPerformanceCount }}
            </td>
            <td style="width: 7%; text-align: right; font-weight: 600">
              {{ formatNumber(totalPrescriptionAmount) }}
            </td>
            <td style="width: 15%"></td>
            <td style="width: 6%; text-align: center; font-weight: 600">
              {{ totalEvidenceFilesCount }}
            </td>
            <td style="width: 13%"></td>
          </tr>
        </table>
      </div>
    </div>

    <!-- 증빙파일 상세 모달: teleport로 body에 위치 -->
    <teleport to="body">
      <div v-if="detailModalVisible" class="modal-overlay" @click="closeDetailModal">
        <div class="modal-content modal-center" @click.stop>
          <div class="modal-header">
            <h2>{{ truncateText(selectedClient?.name || '', 20) }}</h2>
            <button @click="closeDetailModal" class="btn-close-nobg">X</button>
          </div>
          <div class="modal-body">
            <div
              v-if="clientFiles.length === 0"
              style="text-align: center; color: #666; padding: 2rem"
            >
              등록된 파일이 없습니다.
            </div>
            <div v-else>
              <!-- 테이블 헤더 -->
              <div
                style="
                  display: flex;
                  font-weight: bold;
                  padding: 0.75rem 0;
                  border-bottom: 1px solid #bbb;
                  margin-bottom: 0.5rem;
                "
              >
                <div style="flex: 1; text-align: center">파일명</div>
                <div style="width: 80px; text-align: center">삭제</div>
              </div>
              <!-- 테이블 데이터 -->
              <div
                v-for="(file, index) in clientFiles"
                :key="file.id"
                style="display: flex; padding: 0.5rem 0; border-bottom: 1px solid #eee"
              >
                <div style="flex: 1; text-align: left; padding-left: 1rem">
                  <a
                    @click="downloadFile(file)"
                    style="color: #1976d2; cursor: pointer; text-decoration: underline"
                  >
                    {{ file.file_name }}
                  </a>
                </div>
                <div style="width: 80px; text-align: center">
                  <button
                    @click="deleteFile(file, index)"
                    style="
                      color: red;
                      border: none;
                      background: none;
                      cursor: pointer;
                      font-size: 1.2rem;
                      font-weight: 400;
                    "
                    title="파일 삭제"
                    :disabled="!isInputPeriod"
                  >
                    ×
                  </button>
                </div>
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button
              class="btn-download"
              @click="downloadAllFiles"
              :disabled="clientFiles.length === 0"
            >
              전체 다운로드
            </button>
            <button class="btn-close" @click="closeDetailModal">닫기</button>
          </div>
        </div>
      </div>
    </teleport>

    <!-- 업로드 모달: teleport로 body에 위치 -->
    <teleport to="body">
      <div v-if="uploadModalVisible" class="modal-overlay" @click="closeUploadModal">
        <div class="modal-content modal-center" @click.stop>
          <div class="modal-header">
            <h2>{{ selectedClient?.name }}</h2>
            <button @click="closeUploadModal" class="btn-close-nobg">X</button>
          </div>
          <div class="modal-body">
            <div style="margin-bottom: 1rem">
              <label style="display: block; margin-bottom: 0.5rem">파일 선택 (최대 10개)</label>
              <input
                ref="fileInput"
                type="file"
                multiple
                accept=".pdf,.jpg,.jpeg,.png,.doc,.docx,.xls,.xlsx"
                @change="handleFileSelect"
                style="width: 100%"
              />
              <div style="font-size: 0.9rem; color: #666; margin-top: 0.5rem">
                등록 가능 파일: PDF, JPG, PNG, DOC, DOCX, XLS, XLSX
              </div>
            </div>
            <div v-if="selectedFiles.length > 0" style="margin-bottom: 1rem">
              <label style="display: block; margin-bottom: 0.5rem">선택된 파일</label>
              <div
                v-for="(file, index) in selectedFiles"
                :key="index"
                style="
                  display: flex;
                  justify-content: space-between;
                  align-items: center;
                  padding: 0.5rem;
                  border: 1px solid #ddd;
                  margin-bottom: 0.25rem;
                "
              >
                <span>{{ file.name }}</span>
                <button
                  @click="removeFile(index)"
                  style="color: red; border: none; background: none; cursor: pointer"
                >
                  ×
                </button>
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn-cancel" @click="closeUploadModal">취소</button>
            <button
              class="btn-excell-upload"
              @click="uploadFiles"
              :disabled="selectedFiles.length === 0 || uploading"
            >
              {{ uploading ? '업로드 중...' : '업로드' }}
            </button>
          </div>
        </div>
      </div>
    </teleport>

    <!-- 조회 모달: teleport로 body에 위치 -->
    <teleport to="body">
      <div v-if="viewModalVisible" class="modal-overlay" @click="closeViewModal">
        <div class="modal-content modal-center" @click.stop>
          <div class="modal-header">
            <h2>{{ truncateText(viewModalClient?.name || '', 20) }}</h2>
            <button @click="closeViewModal" class="btn-close-nobg">X</button>
          </div>
          <div class="modal-body">
            <div
              v-if="viewModalData.length === 0"
              style="text-align: center; color: #666; padding: 2rem"
            >
              등록된 실적이 없습니다.
            </div>
            <div v-else>
              <!-- 테이블 헤더 -->
              <div
                style="
                  display: flex;
                  font-weight: bold;
                  padding: 0.75rem 0;
                  border-bottom: 1px solid #bbb;
                  margin-bottom: 0.5rem;
                "
              >
                <div style="flex: 1; text-align: center">제품명</div>
                <div style="width: 100px; text-align: center">처방수량</div>
              </div>
              <!-- 테이블 데이터 -->
              <div
                v-for="(record, index) in viewModalData"
                :key="index"
                style="display: flex; padding: 0.5rem 0; border-bottom: 1px solid #eee"
              >
                <div style="flex: 1; text-align: left; padding-left: 1rem">
                  {{ record.product_name }}
                </div>
                <div style="width: 100px; text-align: right; padding-right: 2rem">
                  {{ formatNumber(record.prescription_qty) }}
                </div>
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn-close" @click="closeViewModal">닫기</button>
          </div>
        </div>
      </div>
    </teleport>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, nextTick } from 'vue'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import { supabase } from '@/supabase'
import { useRouter } from 'vue-router'
import * as XLSX from 'xlsx'

const columnWidths = {
  no: '4%',
  client_code: '7%',
  name: '16%',
  business_registration_number: '8%',
  address: '23%',
  performance_count: '6%',
  total_prescription_amount: '6%',
  view_button: '6%',
  input_button: '6%',
  evidence_files_count: '6%',
  view_files_button: '6%',
  upload_button: '6%',
}

const availableMonths = ref([])
const selectedSettlementMonth = ref('')
const clientList = ref([])
const isInputPeriod = ref(false)
const currentCompanyId = ref(null)
const loading = ref(false)
const router = useRouter()
const detailModalVisible = ref(false)
const selectedClient = ref(null)
const clientFiles = ref([])
const uploadModalVisible = ref(false)
const selectedFiles = ref([])
const uploading = ref(false)
const fileInput = ref(null)

// 조회 모달 관련 변수 추가
const viewModalVisible = ref(false)
const viewModalData = ref([])
const viewModalClient = ref(null)

const excelFileInput = ref(null)
const selectedExcelFile = ref(null)
const uploadErrors = ref([])

const formatNumber = (value) => {
  if (!value) return '0'
  return new Intl.NumberFormat('ko-KR').format(value)
}

// 정산월 목록 fetch
const fetchAvailableMonths = async () => {
  const { data, error } = await supabase
    .from('settlement_months')
    .select('settlement_month')
    .eq('status', 'active')
    .order('settlement_month', { ascending: false })
  if (!error && data) {
    availableMonths.value = data.map((m) => m.settlement_month)
    if (availableMonths.value.length > 0) {
      selectedSettlementMonth.value = availableMonths.value[0]
    }
  }
}

// 내 회사ID fetch
const fetchCurrentCompanyId = async () => {
  const {
    data: { session },
  } = await supabase.auth.getSession()
  if (!session?.user) return
  const { data: company } = await supabase
    .from('companies')
    .select('id')
    .eq('user_id', session.user.id)
    .single()
  if (company) currentCompanyId.value = company.id
}

// 내 거래처ID fetch
const fetchMyClientIds = async () => {
  if (!currentCompanyId.value) return []
  const { data, error } = await supabase
    .from('client_company_assignments')
    .select('client_id')
    .eq('company_id', currentCompanyId.value)
  if (!error && data) {
    return data.map((a) => a.client_id)
  }
  return []
}

// 거래처+실적 집계 fetch
const fetchClientList = async () => {
  loading.value = true
  clientList.value = []
  if (!selectedSettlementMonth.value || !currentCompanyId.value) {
    loading.value = false
    return
  }
  const clientIds = await fetchMyClientIds()
  if (clientIds.length === 0) {
    loading.value = false
    return
  }
  // 거래처 정보
  const { data: clients, error: clientError } = await supabase
    .from('clients')
    .select('id, client_code, name, business_registration_number, address')
    .in('id', clientIds)
    .eq('status', 'active')
    .order('name', { ascending: true })
  if (clientError || !clients) {
    loading.value = false
    return
  }
  // 실적 집계
  const { data: perfData } = await supabase
    .from('performance_records')
    .select('client_id, prescription_qty, products(price)')
    .eq('company_id', currentCompanyId.value)
    .eq('settlement_month', selectedSettlementMonth.value)

  // 거래처별 증빙파일 개수 집계 (PerformanceUploadView.vue 참고)
  const evidenceCounts = {}
  for (const client of clients) {
    const { count } = await supabase
      .from('performance_evidence_files')
      .select('*', { count: 'exact', head: true })
      .eq('company_id', currentCompanyId.value)
      .eq('client_id', client.id)
      .eq('settlement_month', selectedSettlementMonth.value)
    evidenceCounts[client.id] = count || 0
  }

  // 집계
  let unsortedList = clients.map((client) => {
    const perfRows = perfData?.filter((p) => p.client_id === client.id) || []
    const performance_count = perfRows.length
    const total_prescription_amount = perfRows.reduce(
      (sum, p) => sum + (p.prescription_qty || 0) * (p.products?.price || 0),
      0,
    )
    const evidence_files_count = evidenceCounts[client.id] || 0
    return {
      ...client,
      performance_count,
      total_prescription_amount,
      evidence_files_count,
    }
  })
  // 정렬: 처방건수 0건 → 1건 이상, 각 그룹 내 가나다순
  const noData = unsortedList
    .filter((c) => !c.performance_count || Number(c.performance_count) === 0)
    .sort((a, b) => a.name.localeCompare(b.name, 'ko'))
  const hasData = unsortedList
    .filter((c) => Number(c.performance_count) > 0)
    .sort((a, b) => a.name.localeCompare(b.name, 'ko'))
  clientList.value = [...noData, ...hasData]
  loading.value = false
}

// 입력 가능 기간 체크
const checkInputPeriod = async () => {
  if (!selectedSettlementMonth.value) return
  const { data, error } = await supabase
    .from('settlement_months')
    .select('start_date, end_date')
    .eq('settlement_month', selectedSettlementMonth.value)
    .single()
  if (!error && data) {
    const now = new Date()
    const koreaNow = new Date(now.getTime() + 9 * 60 * 60 * 1000) // 한국시간 보정
    const startDate = new Date(data.start_date)
    const endDate = new Date(data.end_date)
    isInputPeriod.value = koreaNow >= startDate && koreaNow <= endDate
  } else {
    isInputPeriod.value = false
  }
}

// 합계 계산
const totalPerformanceCount = computed(() =>
  clientList.value.reduce((sum, c) => sum + (c.performance_count || 0), 0),
)
const totalPrescriptionAmount = computed(() =>
  clientList.value.reduce((sum, c) => sum + (c.total_prescription_amount || 0), 0),
)
const totalEvidenceFilesCount = computed(() =>
  clientList.value.reduce((sum, c) => sum + (c.evidence_files_count || 0), 0),
)

const viewDetails = (client) => {
  if (!selectedSettlementMonth.value) {
    alert('정산월을 선택해주세요.')
    return
  }

  openViewModal(client)
}

// 조회 모달 열기
async function openViewModal(client) {
  viewModalClient.value = client
  viewModalData.value = []
  viewModalVisible.value = true
  await fetchViewModalData(client.id)
}

// 조회 모달 닫기
function closeViewModal() {
  viewModalVisible.value = false
  viewModalClient.value = null
  viewModalData.value = []
}

// 조회 모달용 실적 데이터 조회
async function fetchViewModalData(clientId) {
  if (!currentCompanyId.value || !selectedSettlementMonth.value) return

  try {
    const { data, error } = await supabase
      .from('performance_records')
      .select(
        `
        prescription_qty,
        products (
          product_name
        )
      `,
      )
      .eq('company_id', currentCompanyId.value)
      .eq('settlement_month', selectedSettlementMonth.value)
      .eq('client_id', clientId)

    if (!error && data) {
      viewModalData.value = data.map((record) => ({
        product_name: record.products?.product_name || '',
        prescription_qty: record.prescription_qty || 0,
      }))
    }
  } catch (err) {
    console.error('조회 데이터 로드 오류:', err)
  }
}

const registerPerformance = (client) => {
  if (!selectedSettlementMonth.value) {
    alert('정산월을 선택해주세요.')
    return
  }

  router.push({
    name: 'PerformanceRegisterEdit',
    query: {
      clientId: client.id,
      clientName: client.name,
      businessRegistrationNumber: client.business_registration_number,
      address: client.address,
      settlementMonth: selectedSettlementMonth.value,
    },
  })
}
const viewFiles = (client) => {}

function truncateText(text, maxLength) {
  if (!text) return ''
  return text.length > maxLength ? text.substring(0, maxLength) + '...' : text
}
function formatDate(dateString) {
  if (!dateString) return ''
  return new Date(dateString).toLocaleDateString('ko-KR')
}

async function openDetailModal(client) {
  console.log('모달 오픈', client) // 디버깅용
  selectedClient.value = client
  detailModalVisible.value = false // 강제 반응성 트리거
  await nextTick()
  detailModalVisible.value = true
  await fetchClientFiles(client.id)
}
function closeDetailModal() {
  detailModalVisible.value = false
  selectedClient.value = null
  clientFiles.value = []
}
async function fetchClientFiles(clientId) {
  const { data, error } = await supabase
    .from('performance_evidence_files')
    .select('*')
    .eq('company_id', currentCompanyId.value)
    .eq('client_id', clientId)
    .eq('settlement_month', selectedSettlementMonth.value)
    .order('uploaded_at', { ascending: false })
  if (!error && data) {
    clientFiles.value = data
  } else {
    clientFiles.value = []
  }
}
async function downloadFile(file) {
  const { data, error } = await supabase.storage
    .from('performance-evidence')
    .download(file.file_path)
  if (error) {
    alert('파일 다운로드에 실패했습니다.')
    return
  }
  const url = URL.createObjectURL(data)
  const a = document.createElement('a')
  a.href = url
  a.download = file.file_name
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}
async function deleteFile(file, index) {
  if (!confirm('이 파일을 삭제하시겠습니까?')) return
  await supabase.storage.from('performance-evidence').remove([file.file_path])
  await supabase.from('performance_evidence_files').delete().eq('id', file.id)
  clientFiles.value.splice(index, 1)
  await fetchClientFiles(selectedClient.value.id)
  await fetchClientList() // 테이블 새로고침
}
async function downloadAllFiles() {
  if (clientFiles.value.length === 0) {
    alert('다운로드할 파일이 없습니다.')
    return
  }
  const zip = new window.JSZip()
  const today = new Date().toISOString().slice(0, 10)
  const folderNameInZip = `${selectedClient.value.name}_${selectedSettlementMonth.value}`
  const folder = zip.folder(folderNameInZip)
  const filePromises = clientFiles.value.map(async (file) => {
    const { data, error } = await supabase.storage
      .from('performance-evidence')
      .download(file.file_path)
    if (!error) folder.file(file.file_name, data, { binary: true })
  })
  await Promise.all(filePromises)
  zip
    .generateAsync({ type: 'blob', compression: 'DEFLATE', compressionOptions: { level: 9 } })
    .then(function (content) {
      const link = document.createElement('a')
      link.href = URL.createObjectURL(content)
      link.download = `${folderNameInZip}.zip`
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
      URL.revokeObjectURL(link.href)
    })
    .catch((err) => {
      alert('ZIP 파일 생성에 실패했습니다.')
    })
}

function openUploadModal(client) {
  selectedClient.value = client
  selectedFiles.value = []
  uploadModalVisible.value = true
  nextTick(() => {
    if (fileInput.value) fileInput.value.value = ''
  })
}
function closeUploadModal() {
  uploadModalVisible.value = false
  selectedClient.value = null
  selectedFiles.value = []
  if (fileInput.value) fileInput.value.value = ''
}
function handleFileSelect(event) {
  const newFiles = Array.from(event.target.files)
  const totalFiles = selectedFiles.value.length + newFiles.length

  if (totalFiles > 10) {
    alert('최대 10개의 파일만 선택할 수 있습니다.')
    return
  }

  selectedFiles.value = [...selectedFiles.value, ...newFiles]

  // 파일 input 초기화 (같은 파일 다시 선택 가능하도록)
  if (fileInput.value) {
    fileInput.value.value = ''
  }
}
function removeFile(index) {
  selectedFiles.value.splice(index, 1)
}
async function uploadFiles() {
  if (selectedFiles.value.length === 0) return
  if (!selectedClient.value || !currentCompanyId.value) return
  uploading.value = true
  try {
    for (const file of selectedFiles.value) {
      const cleanFileName = file.name.replace(/[^a-zA-Z0-9.-]/g, '_')
      const timestamp = Date.now()
      const randomId = Math.random().toString(36).substring(2, 8)
      const fileName = `${timestamp}_${randomId}_${cleanFileName}`
      const filePath = `private/${fileName}`
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('performance-evidence')
        .upload(filePath, file)
      if (uploadError) {
        alert(`파일 업로드 실패: ${file.name}`)
        continue
      }
      await supabase.from('performance_evidence_files').insert({
        company_id: currentCompanyId.value,
        client_id: selectedClient.value.id,
        settlement_month: selectedSettlementMonth.value,
        file_name: file.name,
        file_path: uploadData.path,
        file_size: file.size,
        uploaded_by: null, // 필요시 사용자 ID로 변경
      })
    }
    alert('파일 업로드가 완료되었습니다.')
    closeUploadModal()
    await fetchClientList() // 목록 새로고침
  } catch (err) {
    alert('파일 업로드 중 오류가 발생했습니다.')
  } finally {
    uploading.value = false
  }
}

// 정산월 변경 시 데이터 새로고침
watch(selectedSettlementMonth, async () => {
  await checkInputPeriod()
  await fetchClientList()
})

onMounted(async () => {
  await fetchAvailableMonths()
  await fetchCurrentCompanyId()
  await checkInputPeriod()
  await fetchClientList()
})

// 엑셀 다운로드 함수
function downloadExcel() {
  if (!clientList.value || clientList.value.length === 0) {
    alert('다운로드할 데이터가 없습니다.')
    return
  }

  // 엑셀 데이터 준비
  const excelData = clientList.value.map((client, index) => ({
    No: index + 1,
    거래처코드: client.client_code || '',
    병의원명: client.name || '',
    사업자등록번호: client.business_registration_number || '',
    주소: client.address || '',
    처방건수: client.performance_count || 0,
    처방액: client.total_prescription_amount || 0,
    증빙파일: client.evidence_files_count || 0,
  }))

  // 합계 행 추가
  const totalCount = totalPerformanceCount.value
  const totalAmount = totalPrescriptionAmount.value
  const totalFiles = totalEvidenceFilesCount.value

  excelData.push({
    No: '',
    거래처코드: '',
    병의원명: '',
    사업자등록번호: '',
    주소: '합계',
    처방건수: totalCount,
    처방액: totalAmount,
    증빙파일: totalFiles,
  })

  // 워크북 생성
  const wb = XLSX.utils.book_new()
  const ws = XLSX.utils.json_to_sheet(excelData)

  // 컬럼 너비 설정
  ws['!cols'] = [
    { wpx: 50 }, // No
    { wpx: 100 }, // 거래처코드
    { wpx: 200 }, // 병의원명
    { wpx: 150 }, // 사업자등록번호
    { wpx: 300 }, // 주소
    { wpx: 100 }, // 처방건수
    { wpx: 120 }, // 처방액
    { wpx: 100 }, // 증빙파일
  ]

  // 숫자 형식 설정
  const range = XLSX.utils.decode_range(ws['!ref'])
  for (let R = range.s.r + 1; R <= range.e.r; R++) {
    // 처방건수 컬럼 (E열, 인덱스 4)
    const countCell = XLSX.utils.encode_cell({ r: R, c: 4 })
    if (ws[countCell] && typeof ws[countCell].v === 'number') {
      ws[countCell].z = '#,##0'
    }
    // 처방액 컬럼 (F열, 인덱스 5)
    const amountCell = XLSX.utils.encode_cell({ r: R, c: 5 })
    if (ws[amountCell] && typeof ws[amountCell].v === 'number') {
      ws[amountCell].z = '#,##0'
    }
    // 증빙파일 컬럼 (G열, 인덱스 6)
    const filesCell = XLSX.utils.encode_cell({ r: R, c: 6 })
    if (ws[filesCell] && typeof ws[filesCell].v === 'number') {
      ws[filesCell].z = '#,##0'
    }
  }

  // 워크시트를 워크북에 추가
  XLSX.utils.book_append_sheet(wb, ws, '실적 등록 현황')

  // 파일명 생성
  const today = new Date()
  const dateStr = today.toISOString().slice(0, 10).replace(/-/g, '')
  let fileName = '실적등록현황'
  if (selectedSettlementMonth.value) {
    fileName += `_${selectedSettlementMonth.value}`
  }
  fileName += `_${dateStr}.xlsx`

  // 파일 다운로드
  XLSX.writeFile(wb, fileName)
}

// 템플릿 다운로드 (6개 항목)
function downloadExcelTemplate() {
  const wb = XLSX.utils.book_new()
  const headers = ['거래처_사업자등록번호', '처방월', '보험코드', '수량', '처방구분', '비고']
  const ws = XLSX.utils.aoa_to_sheet([headers])
  ws['!cols'] = [
    { wpx: 150 }, // 거래처_사업자등록번호
    { wpx: 100 }, // 처방월
    { wpx: 120 }, // 보험코드
    { wpx: 80 }, // 수량
    { wpx: 100 }, // 처방구분
    { wpx: 200 }, // 비고
  ]
  XLSX.utils.book_append_sheet(wb, ws, '실적등록')
  const today = new Date()
  const dateStr = today.toISOString().slice(0, 10).replace(/-/g, '')
  XLSX.writeFile(wb, `실적등록_템플릿_${dateStr}.xlsx`)
}

function triggerExcelUpload() {
  excelFileInput.value.click()
}

async function handleExcelUpload(event) {
  const file = event.target.files[0]
  if (!file) return
  selectedExcelFile.value = file
  uploadErrors.value = []
  try {
    const data = await readExcelFile(file)
    const errors = await validateExcelData(data)
    if (errors.length > 0) {
      uploadErrors.value = errors
      return
    }
    await saveExcelData(data)
    alert('엑셀 데이터가 성공적으로 등록되었습니다.')
    await fetchClientList()
  } catch (err) {
    alert('엑셀 파일 처리 중 오류가 발생했습니다.')
  }
}

function readExcelFile(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = (e) => {
      try {
        const data = new Uint8Array(e.target.result)
        const workbook = XLSX.read(data, { type: 'array' })
        const firstSheet = workbook.Sheets[workbook.SheetNames[0]]
        const jsonData = XLSX.utils.sheet_to_json(firstSheet, { defval: '' })
        resolve(jsonData)
      } catch (err) {
        reject(err)
      }
    }
    reader.onerror = reject
    reader.readAsArrayBuffer(file)
  })
}

// 검증 함수
async function validateExcelData(data) {
  const errors = []
  const myClients = await fetchMyClients()
  const validMonths = await getValidSettlementMonths()
  const validProducts = await fetchValidProducts(validMonths)
  for (let i = 0; i < data.length; i++) {
    const row = data[i]
    const rowNum = i + 2
    // 1. 거래처 체크 (clients.status = 'active'도 포함)
    const businessNumber = row['거래처_사업자등록번호']
    let clientActive = false
    if (businessNumber) {
      const { data: clientData } = await supabase
        .from('clients')
        .select('id, status')
        .eq('business_registration_number', businessNumber)
        .single()
      if (clientData && clientData.status === 'active') {
        clientActive = true
      }
    }
    if (!businessNumber || !myClients.includes(businessNumber) || !clientActive) {
      errors.push(`${rowNum}행: 내 거래처가 아니거나 비활성 거래처입니다.`)
    }
    // 2. 처방월 체크
    if (!row['처방월'] || !validMonths.includes(row['처방월'])) {
      errors.push(`${rowNum}행: 입력 가능한 처방월이 아닙니다.`)
    }
    // 3. 제품 체크
    if (!row['보험코드'] || !validProducts[row['처방월']]?.includes(row['보험코드'])) {
      errors.push(`${rowNum}행: 해당 처방월에 등록/활성화된 제품이 아닙니다.`)
    }
    // 4. 보험코드 형식 체크 (9자리 숫자, TEXT)
    if (row['보험코드'] && !/^[0-9]{9,10}$/.test(row['보험코드'])) {
      errors.push(`${rowNum}행: 보험코드는 9~10자리 숫자여야 합니다.`)
    }
  }
  return errors
}

// 내 거래처 사업자등록번호 목록 (status = 'active'인 거래처만)
async function fetchMyClients() {
  // 1. 내 회사의 client_company_assignments에서 client_id 목록 조회
  const { data: assignments } = await supabase
    .from('client_company_assignments')
    .select('client_id')
    .eq('company_id', currentCompanyId.value)
  const clientIds = assignments?.map((a) => a.client_id) || []
  if (clientIds.length === 0) return []
  // 2. clients 테이블에서 status = 'active'인 거래처만 필터링
  const { data: clients } = await supabase
    .from('clients')
    .select('business_registration_number')
    .in('id', clientIds)
    .eq('status', 'active')
  return clients?.map((c) => c.business_registration_number) || []
}

// 유효한 처방월 목록 (예: 최근 3개월)
function getValidSettlementMonths() {
  const validMonths = []
  const currentMonth = selectedSettlementMonth.value
  for (let i = 1; i <= 3; i++) {
    const date = new Date(currentMonth)
    date.setMonth(date.getMonth() - i)
    validMonths.push(date.toISOString().slice(0, 7))
  }
  return validMonths
}

// 유효한 제품 체크
async function fetchValidProducts(validMonths) {
  const { data } = await supabase
    .from('products')
    .select('base_month, insurance_code')
    .in('base_month', validMonths)
    .eq('status', 'active')
  const products = {}
  data?.forEach((item) => {
    if (!products[item.base_month]) products[item.base_month] = []
    products[item.base_month].push(item.insurance_code)
  })
  return products
}

// 엑셀 데이터 저장
async function saveExcelData(data) {
  const records = []
  for (const row of data) {
    const clientId = await getClientIdByBusinessNumber(row['거래처_사업자등록번호'])
    records.push({
      company_id: currentCompanyId.value,
      client_id: clientId,
      settlement_month: row['처방월'],
      insurance_code: row['보험코드'],
      prescription_qty: parseInt(row['수량']) || 0,
      prescription_type: row['처방구분'],
      note: row['비고'],
    })
  }
  const { error } = await supabase.from('performance_records').insert(records)
  if (error) throw error
}

async function getClientIdByBusinessNumber(businessNumber) {
  const { data } = await supabase
    .from('clients')
    .select('id')
    .eq('business_registration_number', businessNumber)
    .single()
  return data?.id
}
</script>
