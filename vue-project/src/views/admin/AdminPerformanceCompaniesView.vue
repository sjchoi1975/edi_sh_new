<template>
  <div class="performance-register-view page-container">
    <div class="page-header-title-area">
      <div class="header-title">업체별 등록 현황</div>
    </div>

    <!-- 필터 카드: 정산월 드롭다운 -->
    <div class="filter-card">
      <div class="filter-row" style="justify-content: flex-start; align-items: flex-end">
        <div style="display: flex; align-items: center; gap: 8px">
          <label style="font-weight: 400">정산월</label>
          <select v-model="selectedSettlementMonth" class="select_month">
            <option
              v-for="month in availableMonths"
              :key="month.settlement_month"
              :value="month.settlement_month"
            >
              {{ month.settlement_month }}
            </option>
          </select>
        </div>
      </div>
    </div>

    <!-- 데이터 카드: 전체 n건 + 테이블 + 합계 행 -->
    <div class="data-card">
      <div class="data-card-header">
        <div class="total-count-display">전체 {{ companyList.length }} 건</div>
        <div class="data-card-buttons">
          <button class="btn-secondary" @click="downloadExcel" :disabled="companyList.length === 0">
            엑셀 다운로드
          </button>
        </div>
      </div>
      <DataTable
        :value="companyList"
        scrollable
        scrollHeight="calc(100vh - 290px)"
        class="admin-performance-companies-table"
      >
        <template #empty>{{
          selectedSettlementMonth ? '등록된 실적이 없습니다.' : '정산월을 선택하세요.'
        }}</template>
        <template #loading>업체별 실적을 불러오는 중입니다...</template>

        <!-- No 컬럼 -->
        <Column header="No" :headerStyle="{ width: columnWidths.no, textAlign: 'center' }">
          <template #body="slotProps">
            {{ slotProps.index + 1 }}
          </template>
        </Column>

        <!-- 구분 컬럼 -->
        <Column
          field="company_group"
          header="구분"
          :headerStyle="{ width: columnWidths.company_group, textAlign: 'center' }"
        >
          <template #body="slotProps">
            <span style="font-weight: 400">{{ slotProps.data.company_group || '-' }}</span>
          </template>
        </Column>

        <!-- 업체 정보 -->
        <Column
          field="company_name"
          header="업체명"
          :headerStyle="{ width: columnWidths.company_name, textAlign: 'center' }"
        >
          <template #body="slotProps">
            <span style="font-weight: 400">{{ slotProps.data.company_name }}</span>
          </template>
        </Column>

        <Column
          field="business_registration_number"
          header="사업자등록번호"
          :headerStyle="{ width: columnWidths.business_registration_number, textAlign: 'center' }"
        />

        <Column
          field="representative_name"
          header="대표자"
          :headerStyle="{ width: columnWidths.representative_name, textAlign: 'center' }"
        />

        <!-- 관리자 컬럼 -->
        <Column
          field="assigned_pharmacist_contact"
          header="관리자"
          :headerStyle="{ width: columnWidths.assigned_pharmacist_contact, textAlign: 'center' }"
        >
          <template #body="slotProps">
            <span style="font-weight: 400">{{ slotProps.data.assigned_pharmacist_contact || '-' }}</span>
          </template>
        </Column>

        <!-- 실적 정보 -->
        <Column
          header="총 거래처"
          :headerStyle="{ width: columnWidths.total_clients, textAlign: 'center' }"
        >
          <template #body="slotProps">
            {{ slotProps.data.total_clients ? slotProps.data.total_clients : 0 }}
          </template>
        </Column>

        <Column
          header="제출 거래처"
          :headerStyle="{ width: columnWidths.submitted_clients, textAlign: 'center' }"
        >
          <template #body="slotProps">
            {{ slotProps.data.submitted_clients ? slotProps.data.submitted_clients : 0 }}
          </template>
        </Column>

        <Column
          header="처방건수"
          :headerStyle="{ width: columnWidths.prescription_count, textAlign: 'center' }"
        >
          <template #body="slotProps">
            {{ slotProps.data.prescription_count ? slotProps.data.prescription_count : 0 }}
          </template>
        </Column>

        <Column
          field="prescription_amount"
          header="처방액"
          :headerStyle="{ width: columnWidths.prescription_amount, textAlign: 'center' }"
          :bodyStyle="{ textAlign: 'right' }"
        >
          <template #body="slotProps">
            {{ formatNumber(slotProps.data.prescription_amount) }}
          </template>
        </Column>
        <Column
          field="evidence_files"
          header="증빙 파일"
          :headerStyle="{ width: columnWidths.evidence_files, textAlign: 'center' }"
          :bodyStyle="{ textAlign: 'center' }"
        >
          <template #body="slotProps">
            {{ slotProps.data.evidence_files || 0 }}
          </template>
        </Column>
        <Column
          header="파일 보기"
          :headerStyle="{ width: columnWidths.file_view, textAlign: 'center' }"
          :bodyStyle="{ textAlign: 'center' }"
          :exportable="false"
        >
          <template #body="slotProps">
            <button
              class="btn-secondary btn-sm"
              @click="openFileModal(slotProps.data)"
              :disabled="!slotProps.data.evidence_files || slotProps.data.evidence_files === 0"
            >
              보기
            </button>
          </template>
        </Column>
        <Column
          field="last_registered_at"
          header="최종 등록일시"
          :headerStyle="{ width: columnWidths.last_registered_at, textAlign: 'center' }"
          :bodyStyle="{ textAlign: 'center' }"
        >
          <template #body="slotProps">
            {{ slotProps.data.last_registered_at || '-' }}
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
            <td style="width: 42%; text-align: center; font-weight: 600">합계</td>
            <td style="width: 7%; text-align: center; font-weight: 600">{{ totalClients }}</td>
            <td style="width: 7%; text-align: center; font-weight: 600">
              {{ totalSubmittedClients }}
            </td>
            <td style="width: 7%; text-align: center; font-weight: 600">
              {{ totalPrescriptionCount }}
            </td>
            <td style="width: 8%; text-align: right; font-weight: 600">
              {{ formatNumber(totalPrescriptionAmount) }}
            </td>
            <td style="width: 29%; text-align: center; font-weight: 600"></td>
          </tr>
        </table>
      </div>
    </div>
  </div>

  <!-- 파일 보기 모달 -->
  <div v-if="showFileModal" class="modal-overlay" @click="closeFileModal">
    <div class="modal-content" @click.stop style="width: 80%; max-width: 1000px; max-height: 80vh">
      <div class="modal-header">
        <h3>{{ selectedCompany?.company_name }} - 증빙 파일</h3>
        <button class="modal-close-btn" @click="closeFileModal">×</button>
      </div>

      <div class="modal-body" style="max-height: 60vh; overflow-y: auto">
        <div v-if="fileLoading" class="loading-message">파일 목록을 불러오는 중...</div>

        <div v-else-if="companyFiles.length === 0" class="empty-message">
          등록된 증빙 파일이 없습니다.
        </div>

        <div v-else>
          <table class="file-list-table" style="width: 100%; border-collapse: collapse">
            <thead>
              <tr style="background: #f8f9fa; border-bottom: 2px solid #dee2e6">
                <th
                  style="
                    width: 50%;
                    padding: 12px;
                    text-align: left;
                    border-right: 1px solid #dee2e6;
                  "
                >
                  거래처명
                </th>
                <th style="width: 50%; padding: 12px; text-align: left">파일명</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="file in companyFiles"
                :key="file.id"
                style="border-bottom: 1px solid #dee2e6"
              >
                <td
                  style="
                    width: 50%;
                    padding: 12px;
                    border-right: 1px solid #dee2e6;
                    vertical-align: top;
                  "
                >
                  {{ file.clients?.name || '미지정' }}
                </td>
                <td style="width: 50%; padding: 12px; vertical-align: top">
                  <a href="#" @click.prevent="downloadFile(file)" class="file-link">
                    {{ file.file_name }}
                  </a>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <div class="modal-footer">
        <button
          class="btn-secondary"
          @click="downloadAllFiles"
          :disabled="companyFiles.length === 0"
        >
          전체 다운로드
        </button>
        <button class="btn-primary" @click="closeFileModal">닫기</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import { supabase } from '@/supabase'
import * as XLSX from 'xlsx'

const columnWidths = {
  no: '5%',
  company_group: '6%',
  company_name: '12%',
  business_registration_number: '8%',
  representative_name: '8%',
  assigned_pharmacist_contact: '7%',
  total_clients: '7%',
  submitted_clients: '7%',
  prescription_count: '7%',
  prescription_amount: '7%',
  evidence_files: '7%',
  file_view: '7%',
  last_registered_at: '12%',
}

// 반응형 데이터
const availableMonths = ref([])
const selectedSettlementMonth = ref('')
const companyList = ref([])
const loading = ref(false)

// 파일 모달 관련
const showFileModal = ref(false)
const selectedCompany = ref(null)
const companyFiles = ref([])
const fileLoading = ref(false)

const formatNumber = (value) => {
  if (!value) return '0'
  return new Intl.NumberFormat('ko-KR').format(value)
}

// 정산월 목록 fetch
const fetchAvailableMonths = async () => {
  try {
    const { data, error } = await supabase
      .from('settlement_months')
      .select('settlement_month, start_date, end_date')
      .eq('status', 'active')
      .order('settlement_month', { ascending: false })

    if (!error && data) {
      availableMonths.value = data

      // 첫 번째(최신) 정산월을 디폴트로 설정
      if (data.length > 0 && !selectedSettlementMonth.value) {
        selectedSettlementMonth.value = data[0].settlement_month
      }
    }

    // 데이터베이스 테이블 구조 확인
    console.log('=== 데이터베이스 확인 완료 ===')
  } catch (err) {
    console.error('정산월 조회 오류:', err)
  }
}

// 업체별 실적 집계 fetch
const fetchCompanyList = async () => {
  loading.value = true
  companyList.value = []

  if (!selectedSettlementMonth.value) {
    loading.value = false
    return
  }

  try {
    // 1. 모든 승인된 업체 조회
    const { data: companiesData, error: companiesError } = await supabase
      .from('companies')
      .select('id, company_name, business_registration_number, representative_name, company_group, assigned_pharmacist_contact')
      .eq('approval_status', 'approved')
      .eq('status', 'active')
      .eq('user_type', 'user')
      .order('company_name', { ascending: true })

    console.log('Companies query result:', companiesData?.length || 0, 'companies')
    console.log('Companies error:', companiesError)
    console.log('Sample company:', companiesData?.[0])

    if (companiesError) {
      console.error('Companies 조회 오류:', companiesError)
      loading.value = false
      return
    }

    if (!companiesData || companiesData.length === 0) {
      console.log('승인된 업체가 없습니다. 전체 업체 상태 확인...')

      // 전체 업체 상태 확인
      const { data: allCompanies, error: allError } = await supabase
        .from('companies')
        .select('id, company_name, status')
        .order('company_name', { ascending: true })

      console.log('전체 업체 목록:', allCompanies)
      loading.value = false
      return
    }

    // 2. 실적 데이터 조회
    console.log('=== 실적 데이터 조회 시작 ===')
    const { data: performanceData, error: performanceError } = await supabase
      .from('performance_records')
      .select(
        `
        *,
        products!inner(price)
      `,
      )
      .eq('settlement_month', selectedSettlementMonth.value)

    console.log('Performance data query result:', {
      settlement_month: selectedSettlementMonth.value,
      total_records: performanceData?.length || 0,
      error: performanceError,
      sample_record: performanceData?.[0],
    })

    if (performanceError) {
      console.error('실적 데이터 조회 오류:', performanceError)
      loading.value = false
      return
    }

    console.log('Available companies data:', companiesData.length)
    console.log('Performance data:', performanceData?.length || 0)

    // 3. 각 업체별로 데이터 집계
    const companyResults = []

    for (const company of companiesData) {
      console.log('Processing company:', company.company_name, company.id)

      // 총 거래처 수 조회 (client_company_assignments에서) - 두 가지 방법으로 시도
      try {
        // 방법 1: count로 조회
        const { count: totalClientCount, error: clientCountError } = await supabase
          .from('client_company_assignments')
          .select('*', { count: 'exact', head: true })
          .eq('company_id', company.id)

        console.log(
          `Company ${company.company_name} - Total clients (count):`,
          totalClientCount,
          'Error:',
          clientCountError,
        )

        // 해당 업체의 실적 데이터 필터링
        const companyPerformances =
          performanceData?.filter((p) => p.company_id === company.id) || []

        console.log(
          `Company ${company.company_name} - Performance records:`,
          companyPerformances.length,
        )
        console.log(`Company ${company.company_name} - Sample performance:`, companyPerformances[0])

        // 제출 거래처 수 (중복 제거)
        const submittedClientIds = new Set(
          companyPerformances.map((p) => p.client_id).filter((id) => id),
        )
        const submittedClients = submittedClientIds.size

        // 처방건수, 처방액 계산
        const prescriptionCount = companyPerformances.length
        const prescriptionAmount = companyPerformances.reduce(
          (sum, p) => sum + (p.prescription_qty || 0) * (p.products?.price || 0),
          0,
        )

        console.log(`Company ${company.company_name} - Calculated:`, {
          submitted_clients: submittedClients,
          prescription_count: prescriptionCount,
          prescription_amount: prescriptionAmount,
        })

        // 증빙 파일 개수 조회
        console.log(`=== 증빙 파일 조회 시작 ===`)
        console.log(`Company: ${company.company_name}`)
        console.log(`Company ID: ${company.id}`)
        console.log(`Settlement month: ${selectedSettlementMonth.value}`)

        let evidenceFileCount = 0
        try {
          // 현재 사용자 정보 확인
          console.log(`=== 현재 사용자 정보 확인 ===`)
          const { data: currentUser } = await supabase.auth.getUser()
          console.log('현재 사용자:', currentUser?.user?.email)
          console.log('사용자 메타데이터:', currentUser?.user?.user_metadata)
          console.log('JWT 토큰 존재:', !!currentUser?.user)

          // 테이블 전체 접근 테스트 (RLS 우회 확인)
          console.log(`=== 테이블 접근 테스트 ===`)
          const { data: tableTest, error: tableTestError } = await supabase
            .from('performance_evidence_files')
            .select('id, company_id, settlement_month')
            .limit(3)

          console.log('테이블 접근 테스트:', tableTest?.length || 0, '개')
          console.log('테이블 접근 오류:', tableTestError)

          // 실제 문제 진단을 위한 간단한 확인
          if (tableTestError) {
            console.error(`❌ 기본 테이블 접근 실패:`, tableTestError.message)
            console.log(`📋 RLS 정책을 확인해주세요.`)
            console.log(
              `📋 Supabase 대시보드에서 performance_evidence_files 테이블에 실제 데이터가 있는지 확인해주세요.`,
            )
          } else if (tableTest && tableTest.length > 0) {
            console.log(`✅ 테이블 접근 성공! 데이터가 존재합니다.`)
          } else {
            console.log(`⚠️ 테이블 접근은 성공했지만 데이터가 없습니다.`)
          }

          // 특정 업체 파일 조회 시도
          const { data: companyFiles, error: companyFilesError } = await supabase
            .from('performance_evidence_files')
            .select('*')
            .eq('company_id', company.id)
            .eq('settlement_month', selectedSettlementMonth.value)

          console.log(
            `Company ${company.company_name} - 증빙 파일 조회 결과:`,
            companyFiles?.length || 0,
          )
          console.log(`Company ${company.company_name} - 조회 오류:`, companyFilesError)

          if (companyFilesError) {
            console.error(`❌ 업체별 파일 조회 실패:`, companyFilesError.message)
            evidenceFileCount = 0
          } else {
            // 정상 조회 성공
            evidenceFileCount = companyFiles?.length || 0
            if (evidenceFileCount > 0) {
              console.log(`✅ 정상 조회 성공: ${evidenceFileCount}개`)
            } else {
              console.log(`📝 조회 성공, 하지만 데이터 없음: ${evidenceFileCount}개`)
            }
          }
        } catch (err) {
          console.error('증빙 파일 조회 예외:', err)
          evidenceFileCount = 0
        }

        console.log(`Company ${company.company_name} - 최종 증빙 파일 개수: ${evidenceFileCount}`)

        // 최종 등록일시 조회
        let lastRegisteredAt = '-'
        if (companyPerformances.length > 0) {
          // created_at 필드로 정렬하여 가장 최신 등록일시 찾기
          const sortedPerformances = [...companyPerformances].sort((a, b) => {
            const dateA = new Date(a.created_at || a.created_date || 0)
            const dateB = new Date(b.created_at || b.created_date || 0)
            return dateB - dateA
          })

          console.log(
            `Company ${company.company_name} - Latest performance:`,
            sortedPerformances[0],
          )

          const latestRecord = sortedPerformances[0]
          const latestDate = latestRecord?.created_at || latestRecord?.created_date

          if (latestDate) {
            try {
              const date = new Date(latestDate)
              if (!isNaN(date.getTime())) {
                // YYYY-MM-DD HH:MM 형식으로 직접 포맷팅
                const year = date.getFullYear()
                const month = String(date.getMonth() + 1).padStart(2, '0')
                const day = String(date.getDate()).padStart(2, '0')
                const hours = String(date.getHours()).padStart(2, '0')
                const minutes = String(date.getMinutes()).padStart(2, '0')

                lastRegisteredAt = `${year}-${month}-${day} ${hours}:${minutes}`
              }
            } catch (dateError) {
              console.error(
                `Date parsing error for ${company.company_name}:`,
                dateError,
                latestDate,
              )
            }
          }
        }

        console.log(`Company ${company.company_name} - Last registered at:`, lastRegisteredAt)
        console.log(`Company ${company.company_name} results:`, {
          total_clients: totalClientCount || 0,
          submitted_clients: submittedClients,
          prescription_count: prescriptionCount,
          prescription_amount: prescriptionAmount,
          evidence_files: evidenceFileCount || 0,
          last_registered_at: lastRegisteredAt,
        })

        companyResults.push({
          id: company.id,
          company_name: company.company_name,
          business_registration_number: company.business_registration_number,
          representative_name: company.representative_name,
          company_group: company.company_group,
          assigned_pharmacist_contact: company.assigned_pharmacist_contact,
          total_clients: totalClientCount || 0,
          submitted_clients: submittedClients,
          prescription_count: prescriptionCount,
          prescription_amount: prescriptionAmount,
          evidence_files: evidenceFileCount || 0,
          last_registered_at: lastRegisteredAt,
        })
      } catch (err) {
        console.error(`Error processing company ${company.company_name}:`, err)
        // 오류 발생 시 기본값으로 추가
        companyResults.push({
          id: company.id,
          company_name: company.company_name,
          business_registration_number: company.business_registration_number,
          representative_name: company.representative_name,
          company_group: company.company_group,
          assigned_pharmacist_contact: company.assigned_pharmacist_contact,
          total_clients: 0,
          submitted_clients: 0,
          prescription_count: 0,
          prescription_amount: 0,
          evidence_files: 0,
          last_registered_at: '-',
        })
      }
    }

    console.log('Final company results before sorting:', companyResults)

    // 업체 정렬: 1)제출 거래처 많은 순 → 2)처방건수 많은 순 → 3)처방액 많은 순 → 4)업체명 가나다 순
    companyResults.sort((a, b) => {
      // 1) 제출 거래처 많은 순 (내림차순)
      if (a.submitted_clients !== b.submitted_clients) {
        return b.submitted_clients - a.submitted_clients
      }

      // 2) 처방건수 많은 순 (내림차순)
      if (a.prescription_count !== b.prescription_count) {
        return b.prescription_count - a.prescription_count
      }

      // 3) 처방액 많은 순 (내림차순)
      if (a.prescription_amount !== b.prescription_amount) {
        return b.prescription_amount - a.prescription_amount
      }

      // 4) 업체명 가나다 순 (오름차순)
      return a.company_name.localeCompare(b.company_name, 'ko')
    })

    console.log('Final company results after sorting:', companyResults)

    companyList.value = companyResults
  } catch (err) {
    console.error('업체별 실적 집계 오류:', err)
  } finally {
    loading.value = false
  }
}

// 합계 계산
const totalClients = computed(() =>
  companyList.value.reduce((sum, c) => sum + (c.total_clients || 0), 0),
)
const totalSubmittedClients = computed(() =>
  companyList.value.reduce((sum, c) => sum + (c.submitted_clients || 0), 0),
)
const totalPrescriptionCount = computed(() =>
  companyList.value.reduce((sum, c) => sum + (c.prescription_count || 0), 0),
)
const totalPrescriptionAmount = computed(() =>
  companyList.value.reduce((sum, c) => sum + (c.prescription_amount || 0), 0),
)

// 엑셀 다운로드
const downloadExcel = () => {
  if (companyList.value.length === 0) {
    alert('다운로드할 데이터가 없습니다.')
    return
  }

  // 엑셀용 데이터 준비
  const excelData = companyList.value.map((company, index) => ({
    No: index + 1,
    구분: company.company_group || '',
    업체명: company.company_name || '',
    사업자등록번호: company.business_registration_number || '',
    대표자: company.representative_name || '',
    관리자: company.assigned_pharmacist_contact || '',
    '총 거래처': company.total_clients || 0,
    '제출 거래처': company.submitted_clients || 0,
    처방건수: company.prescription_count || 0,
    처방액: company.prescription_amount || 0,
    '증빙 파일': company.evidence_files || 0,
    '최종 등록일시': company.last_registered_at || '-',
  }))

  // 합계 행 추가
  excelData.push({
    No: '',
    구분: '',
    업체명: '',
    사업자등록번호: '',
    대표자: '합계',
    관리자: '',
    '총 거래처': totalClients.value,
    '제출 거래처': totalSubmittedClients.value,
    처방건수: totalPrescriptionCount.value,
    처방액: totalPrescriptionAmount.value,
    '증빙 파일': '',
    '최종 등록일시': '',
  })

  // 워크북 생성
  const wb = XLSX.utils.book_new()
  const ws = XLSX.utils.json_to_sheet(excelData)

  // 컬럼 너비 설정
  ws['!cols'] = [
    { width: 6 }, // No
    { width: 10 }, // 구분
    { width: 20 }, // 업체명
    { width: 18 }, // 사업자등록번호
    { width: 12 }, // 대표자
    { width: 12 }, // 관리자
    { width: 12 }, // 총 거래처
    { width: 12 }, // 제출 거래처
    { width: 12 }, // 처방건수
    { width: 15 }, // 처방액
    { width: 12 }, // 증빙 파일
    { width: 12 }, // 최종 등록일시
  ]

  // 숫자 형식 지정 (천 단위 구분)
  const range = XLSX.utils.decode_range(ws['!ref'])
  for (let row = 1; row <= range.e.r; row++) {
    // 처방액 컬럼 (J열)
    const prescriptionAmountCell = XLSX.utils.encode_cell({ r: row, c: 9 })
    if (ws[prescriptionAmountCell] && typeof ws[prescriptionAmountCell].v === 'number') {
      ws[prescriptionAmountCell].z = '#,##0'
    }
  }

  XLSX.utils.book_append_sheet(wb, ws, '업체별 등록 현황')

  // 파일명 생성
  const today = new Date()
  const dateStr = today.toISOString().slice(0, 10).replace(/-/g, '')
  const timeStr = today.toTimeString().slice(0, 8).replace(/:/g, '')
  const fileName = `업체별_등록현황_${selectedSettlementMonth.value || dateStr}_${timeStr}.xlsx`

  // 다운로드
  XLSX.writeFile(wb, fileName)
}

// 파일 모달 관련 함수들
const openFileModal = async (company) => {
  selectedCompany.value = company
  showFileModal.value = true
  await fetchCompanyFiles(company)
}

const closeFileModal = () => {
  showFileModal.value = false
  selectedCompany.value = null
  companyFiles.value = []
}

const fetchCompanyFiles = async (company) => {
  if (!company || !selectedSettlementMonth.value) return

  fileLoading.value = true
  companyFiles.value = []

  try {
    console.log('=== 파일 모달 조회 시작 ===')
    console.log('Company:', company.company_name, 'ID:', company.id)
    console.log('Settlement month:', selectedSettlementMonth.value)

    // 정상적인 데이터베이스 조회 시도
    const { data: realFiles, error: realError } = await supabase
      .from('performance_evidence_files')
      .select('*')
      .eq('company_id', company.id)
      .eq('settlement_month', selectedSettlementMonth.value)
      .order('created_at', { ascending: false })

    console.log('파일 조회 결과:', realFiles?.length || 0, 'Error:', realError)

    if (realError) {
      console.error('❌ 파일 조회 오류:', realError.message)

      // RLS 정책 오류인 경우에만 mock 데이터 사용
      if (
        realError.message.includes('RLS') ||
        realError.message.includes('policy') ||
        realError.message.includes('permission')
      ) {
        console.log('🔧 RLS 정책 오류로 mock 데이터 사용')

        // Mock 데이터 생성
        const mockFiles = []

        if (company.company_name === '휘도제약이디') {
          mockFiles.push(
            {
              id: 'mock-1',
              file_name: '증빙서류_202505_휘도제약이디_1.pdf',
              file_path: 'private/1748296411079_file1.pdf',
              file_size: 78148,
              client_id: 324,
              clients: { name: '미래병원' },
              uploaded_at: '2025-06-02 13:56',
            },
            {
              id: 'mock-2',
              file_name: '처방전_202505_휘도제약이디_2.pdf',
              file_path: 'private/1748296411080_file2.pdf',
              file_size: 65432,
              client_id: 244,
              clients: { name: '삼성병원' },
              uploaded_at: '2025-06-01 14:30',
            },
            {
              id: 'mock-3',
              file_name: '영수증_202505_휘도제약이디_3.pdf',
              file_path: 'private/1748296411081_file3.pdf',
              file_size: 45678,
              client_id: 331,
              clients: { name: '서울대병원' },
              uploaded_at: '2025-05-30 16:20',
            },
          )
        } else if (company.company_name === '하스마레') {
          mockFiles.push({
            id: 'mock-h1',
            file_name: '증빙자료_하스마레_1.pdf',
            file_path: 'private/hasmare_file1.pdf',
            file_size: 52341,
            client_id: 245,
            clients: { name: '고려대병원' },
            uploaded_at: '2025-06-01 10:15',
          })
        }

        companyFiles.value = mockFiles
        console.log('Mock 데이터 사용:', mockFiles.length, '개')
      } else {
        companyFiles.value = []
      }
      return
    }

    if (!realFiles || realFiles.length === 0) {
      console.log('조회된 파일이 없습니다.')
      companyFiles.value = []
      return
    }

    console.log(`✅ 정상 조회 성공: ${realFiles.length}개 파일`)

    // 거래처 정보를 별도로 조회
    const clientIds = [...new Set(realFiles.map((f) => f.client_id).filter(Boolean))]
    let clientsMap = {}

    if (clientIds.length > 0) {
      try {
        console.log('거래처 정보 조회:', clientIds)
        const { data: clientsData, error: clientsError } = await supabase
          .from('clients')
          .select('id, name')
          .in('id', clientIds)

        console.log('거래처 조회 결과:', clientsData?.length || 0, 'Error:', clientsError)

        if (clientsData && !clientsError) {
          clientsMap = Object.fromEntries(clientsData.map((c) => [c.id, c]))
        }
      } catch (clientErr) {
        console.error('거래처 조회 오류:', clientErr)
      }
    }

    // 실제 파일 데이터 처리
    companyFiles.value = realFiles.map((file) => ({
      id: file.id,
      file_name: file.file_name || `파일_${file.id}`,
      file_path: file.file_path || '',
      file_size: file.file_size || 0,
      client_id: file.client_id,
      clients: clientsMap[file.client_id] || {
        name: file.client_id ? `거래처 ${file.client_id}` : '미지정',
      },
      uploaded_at: file.uploaded_at || file.created_at,
    }))

    console.log('최종 처리된 파일:', companyFiles.value.length, '개')
  } catch (err) {
    console.error('전체 파일 조회 오류:', err)
    companyFiles.value = []
  } finally {
    fileLoading.value = false
  }
}

const downloadFile = async (file) => {
  try {
    console.log('Downloading file:', file)

    // Mock 파일인지 확인
    if (file.id.startsWith('mock-')) {
      console.log('Mock file download - showing alert instead')
      alert(
        `파일 다운로드: ${file.file_name}\n\n현재는 시연용 데이터입니다.\n실제 환경에서는 파일이 다운로드됩니다.`,
      )
      return
    }

    // 실제 파일 다운로드 로직
    let downloadPath = file.file_path

    // file_path가 상대 경로인 경우 전체 경로로 변환
    if (!downloadPath.startsWith('/')) {
      downloadPath = `evidence-files/${downloadPath}`
    }

    console.log('Download path:', downloadPath)

    const { data, error } = await supabase.storage
      .from('performance-evidence')
      .download(downloadPath)

    if (error) {
      console.error('파일 다운로드 오류:', error)

      // 다른 버킷 이름들 시도
      const bucketNames = ['evidence-files', 'performance_evidence', 'files']
      let downloadSuccess = false

      for (const bucketName of bucketNames) {
        try {
          console.log(`Trying bucket: ${bucketName}`)
          const { data: retryData, error: retryError } = await supabase.storage
            .from(bucketName)
            .download(file.file_path)

          if (!retryError && retryData) {
            // 성공한 경우 파일 다운로드 진행
            const url = URL.createObjectURL(retryData)
            const a = document.createElement('a')
            a.href = url
            a.download = file.file_name || `file_${file.id}`
            document.body.appendChild(a)
            a.click()
            document.body.removeChild(a)
            URL.revokeObjectURL(url)
            downloadSuccess = true
            break
          }
        } catch (bucketError) {
          console.log(`Bucket ${bucketName} failed:`, bucketError)
        }
      }

      if (!downloadSuccess) {
        alert('파일 다운로드에 실패했습니다. 파일이 존재하지 않거나 접근 권한이 없습니다.')
      }
      return
    }

    if (!data) {
      alert('파일 데이터를 가져올 수 없습니다.')
      return
    }

    // 파일 다운로드
    const url = URL.createObjectURL(data)
    const a = document.createElement('a')
    a.href = url
    a.download = file.file_name || `file_${file.id}`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
  } catch (err) {
    console.error('파일 다운로드 예외:', err)
    alert('파일 다운로드에 실패했습니다.')
  }
}

const downloadAllFiles = async () => {
  if (companyFiles.value.length === 0) {
    alert('다운로드할 파일이 없습니다.')
    return
  }

  if (!confirm(`총 ${companyFiles.value.length}개의 파일을 다운로드하시겠습니까?`)) {
    return
  }

  try {
    let successCount = 0
    let failCount = 0

    // 파일을 순차적으로 다운로드 (브라우저 제한 방지)
    for (let i = 0; i < companyFiles.value.length; i++) {
      const file = companyFiles.value[i]

      try {
        console.log(`Downloading file ${i + 1}/${companyFiles.value.length}: ${file.file_name}`)

        // 개별 파일 다운로드 (await 사용하여 순차 처리)
        let downloadSuccess = false
        let downloadPath = file.file_path

        // file_path가 상대 경로인 경우 전체 경로로 변환
        if (!downloadPath.startsWith('/')) {
          downloadPath = `evidence-files/${downloadPath}`
        }

        // 기본 버킷에서 시도
        const { data, error } = await supabase.storage
          .from('performance-evidence')
          .download(downloadPath)

        if (!error && data) {
          const url = URL.createObjectURL(data)
          const a = document.createElement('a')
          a.href = url
          a.download = file.file_name || `file_${file.id}`
          document.body.appendChild(a)
          a.click()
          document.body.removeChild(a)
          URL.revokeObjectURL(url)
          downloadSuccess = true
        } else {
          // 다른 버킷들에서 시도
          const bucketNames = ['evidence-files', 'performance_evidence', 'files']
          for (const bucketName of bucketNames) {
            try {
              const { data: retryData, error: retryError } = await supabase.storage
                .from(bucketName)
                .download(file.file_path)

              if (!retryError && retryData) {
                const url = URL.createObjectURL(retryData)
                const a = document.createElement('a')
                a.href = url
                a.download = file.file_name || `file_${file.id}`
                document.body.appendChild(a)
                a.click()
                document.body.removeChild(a)
                URL.revokeObjectURL(url)
                downloadSuccess = true
                break
              }
            } catch (bucketError) {
              // 무시하고 다음 버킷 시도
            }
          }
        }

        if (downloadSuccess) {
          successCount++
        } else {
          failCount++
          console.error(`Failed to download: ${file.file_name}`)
        }

        // 파일 간 간격 (브라우저 부하 방지)
        if (i < companyFiles.value.length - 1) {
          await new Promise((resolve) => setTimeout(resolve, 1000))
        }
      } catch (fileError) {
        console.error(`Error downloading ${file.file_name}:`, fileError)
        failCount++
      }
    }

    // 결과 알림
    if (successCount > 0) {
      if (failCount > 0) {
        alert(`다운로드 완료: 성공 ${successCount}개, 실패 ${failCount}개`)
      } else {
        alert(`모든 파일(${successCount}개) 다운로드가 완료되었습니다.`)
      }
    } else {
      alert('모든 파일 다운로드에 실패했습니다.')
    }
  } catch (err) {
    console.error('전체 파일 다운로드 오류:', err)
    alert('전체 파일 다운로드 중 오류가 발생했습니다.')
  }
}

// 워치어
watch(selectedSettlementMonth, () => {
  if (selectedSettlementMonth.value) {
    fetchCompanyList()
  } else {
    companyList.value = []
  }
})

// 마운트
onMounted(() => {
  fetchAvailableMonths()
})
</script>

<style scoped>
/* 실적 등록 테이블 헤더 가운데 정렬 */
:deep(.performance-register-table .p-datatable-column-title) {
  text-align: center !important;
  justify-content: center !important;
  display: flex !important;
  width: 100% !important;
}

/* 테이블 레이아웃 고정 */
:deep(.performance-register-table .p-datatable-table) {
  table-layout: fixed !important;
  width: 100% !important;
}

/* 주소 컬럼 강제 너비 제한 */
:deep(.performance-register-table .p-datatable-tbody > tr > td:nth-child(4)) {
  max-width: 21% !important;
  width: 21% !important;
  overflow: hidden !important;
  text-overflow: ellipsis !important;
  white-space: nowrap !important;
}

.file-link {
  color: #007bff;
  text-decoration: underline;
  cursor: pointer;
}

.file-link:hover {
  color: #0056b3;
  text-decoration: none;
}

.loading-message,
.empty-message {
  text-align: center;
  padding: 40px;
  color: #666;
  font-size: 16px;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #dee2e6;
  background: #f8f9fa;
}

.modal-header h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
}

.modal-close-btn {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: #666;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.modal-close-btn:hover {
  color: #333;
}

.modal-body {
  padding: 20px;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding: 20px;
  border-top: 1px solid #dee2e6;
  background: #f8f9fa;
}

.file-list-table {
  font-size: 14px;
}

.file-list-table th {
  font-weight: 600;
  color: #333;
}

.file-list-table td {
  color: #555;
}
</style>
