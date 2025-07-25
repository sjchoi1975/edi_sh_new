<template>
  <div class="admin-revenue-view page-container">
    <div class="page-header-title-area">
      <div class="header-title">직거래매출 목록</div>
    </div>
    <div class="filter-card">
      <div class="filter-row">
        <div style="display: flex; align-items: center; gap: 8px; margin-right: 24px">
          <label style="font-weight: 400">기간</label>
          <select v-model="fromMonth" class="select_month">
            <option v-for="month in availableMonths" :key="month" :value="month">
              {{ month }}
            </option>
          </select>
          <span>~</span>
          <select v-model="toMonth" class="select_month">
            <option v-for="month in availableMonths" :key="month" :value="month">
              {{ month }}
            </option>
          </select>
        </div>
        <div style="display:flex; align-items:center;">
          <span class="filter-item p-input-icon-left" style="position:relative; width:320px;">
            <InputText
              v-model="searchInput"
              placeholder="약국명, 사업자등록번호, 표준코드, 제품명 검색"
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
        <div class="total-count-display">전체 {{ filteredRevenues.length }} 건</div>
        <div class="action-buttons-group">
          <button class="btn-excell-template" @click="downloadTemplate" style="margin-right: 1rem;">엑셀 템플릿</button>
          <button class="btn-excell-upload" @click="triggerFileUpload" style="margin-right: 1rem;">엑셀 등록</button>
          <button class="btn-excell-download" @click="downloadExcel" style="margin-right: 1rem;">엑셀 다운로드</button>
          <button class="btn-delete" @click="deleteAllRevenues" style="margin-right: 1rem;">모두 삭제</button>
          <button class="btn-save" @click="goCreate">개별 등록</button>
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
        :value="filteredRevenues"
        :loading="loading"
        paginator
        :rows="pageSize"
        :rowsPerPageOptions="[20, 50, 100]"
        v-model:first="currentPageFirstIndex"
        scrollable
        scrollHeight="calc(100vh - 250px)"
        class="admin-direct-revenue-table"
      >
        <template #empty>
          <div v-if="!loading">등록된 매출이 없습니다.</div>
        </template>
        <template #loading>매출 목록을 불러오는 중입니다...</template>
        <Column header="No" :headerStyle="{ width: columnWidths.no }">
          <template #body="slotProps">
            {{ slotProps.index + currentPageFirstIndex + 1 }}
          </template>
        </Column>
        <Column
          field="pharmacy_code"
          header="약국코드"
          :headerStyle="{ width: columnWidths.pharmacy_code }"
          :sortable="true"
        >
          <template #body="slotProps">
            <input v-if="slotProps.data.isEditing" v-model="slotProps.data.pharmacy_code" />
            <span v-else>{{ slotProps.data.pharmacy_code }}</span>
          </template>
        </Column>
        <Column
          field="pharmacy_name"
          header="약국명"
          :headerStyle="{ width: columnWidths.pharmacy_name }"
          :sortable="true"
        >
          <template #body="slotProps">
            <input v-if="slotProps.data.isEditing" v-model="slotProps.data.pharmacy_name" :id="`pharmacy_name_${slotProps.data.id}`" />
            <span v-else class="ellipsis-cell" :title="slotProps.data.pharmacy_name" @mouseenter="checkOverflow" @mouseleave="removeOverflowClass">{{ slotProps.data.pharmacy_name }}</span>
          </template>
        </Column>
        <Column
          field="business_registration_number"
          header="사업자번호"
          :headerStyle="{ width: columnWidths.business_registration_number }"
          :sortable="true"
        >
          <template #body="slotProps">
            <input
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.business_registration_number"
              :id="`business_registration_number_${slotProps.data.id}`"
              @input="formatBusinessNumber"
              @keypress="allowOnlyNumbers"
              @keydown="handleBackspace"
            />
            <span v-else>{{ slotProps.data.business_registration_number }}</span>
          </template>
        </Column>
        <Column
          field="address"
          header="주소"
          :headerStyle="{ width: columnWidths.address }"
          :sortable="true"
        >
          <template #body="slotProps">
            <input v-if="slotProps.data.isEditing" v-model="slotProps.data.address" :id="`address_${slotProps.data.id}`" />
            <span v-else class="ellipsis-cell" :title="slotProps.data.address" @mouseenter="checkOverflow" @mouseleave="removeOverflowClass">{{ slotProps.data.address }}</span>
          </template>
        </Column>
        <Column
          field="standard_code"
          header="표준코드"
          :headerStyle="{ width: columnWidths.standard_code }"
          :sortable="true"
        >
          <template #body="slotProps">
            <input
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.standard_code"
              style="width: 100%; border: 1px solid #ddd; padding: 4px"
              :id="`standard_code_${slotProps.data.id}`"
            />
            <span v-else>{{ slotProps.data.standard_code }}</span>
          </template>
        </Column>
        <Column
          field="product_name"
          header="제품명"
          :headerStyle="{ width: columnWidths.product_name }"
          :sortable="true"
        >
          <template #body="slotProps">
            <input
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.product_name"
              style="width: 100%; border: 1px solid #ddd; padding: 4px"
              :id="`product_name_${slotProps.data.id}`"
            />
            <span v-else class="ellipsis-cell" :title="slotProps.data.product_name" @mouseenter="checkOverflow" @mouseleave="removeOverflowClass">{{ slotProps.data.product_name }}</span>
          </template>
        </Column>
        <Column
          field="sales_amount"
          header="매출액"
          :headerStyle="{ width: columnWidths.sales_amount }"
          :sortable="true"
        >
          <template #body="slotProps">
            <input
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.sales_amount"
              type="number"
              style="width: 100%; border: 1px solid #ddd; padding: 4px; text-align: right"
              :id="`sales_amount_${slotProps.data.id}`"
            />
            <span v-else>{{ slotProps.data.sales_amount?.toLocaleString() }}</span>
          </template>
        </Column>
        <Column
          field="sales_date"
          header="매출일자"
          :headerStyle="{ width: columnWidths.sales_date }"
          :sortable="true"
        >
          <template #body="slotProps">
            <input
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.sales_date"
              type="date"
              style="width: 100%; border: 1px solid #ddd; padding: 4px"
              :id="`sales_date_${slotProps.data.id}`"
            />
            <span v-else>{{ slotProps.data.sales_date }}</span>
          </template>
        </Column>
        <Column header="작업" :headerStyle="{ width: columnWidths.actions }">
          <template #body="slotProps">
            <div style="display: flex; gap: 4px; justify-content: center">
              <template v-if="slotProps.data.isEditing">
                <button @click="saveEdit(slotProps.data)" class="btn-save-sm" title="저장">
                  저장
                </button>
                <button @click="cancelEdit(slotProps.data)" class="btn-cancel-sm" title="취소">
                  취소
                </button>
              </template>
              <template v-else>
                <button class="btn-edit-sm" @click="startEdit(slotProps.data)" title="수정">
                  수정
                </button>
                <button class="btn-delete-sm" @click="deleteRevenue(slotProps.data)" title="삭제">
                  삭제
                </button>
              </template>
            </div>
          </template>
        </Column>
        <ColumnGroup type="footer">
          <Row>
            <Column footer="합계" :colspan="7" footerClass="footer-cell" footerStyle="text-align:center !important;" />
            <Column :footer="totalSalesAmount.toLocaleString()" footerClass="footer-cell" footerStyle="text-align:right !important;" />
            <Column footer="" footerClass="footer-cell" />
            <Column footer="" footerClass="footer-cell" />            
          </Row>
        </ColumnGroup>
      </DataTable>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick, computed } from 'vue'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import ColumnGroup from 'primevue/columngroup'
import Row from 'primevue/row'
import InputText from 'primevue/inputtext'
import { useRouter } from 'vue-router'
import { supabase } from '@/supabase'
import * as XLSX from 'xlsx'
import { generateExcelFileName } from '@/utils/excelUtils'

// 컬럼 너비 한 곳에서 관리
const columnWidths = {
  no: '4%',
  pharmacy_code: '7%',
  pharmacy_name: '16%',
  business_registration_number: '8%',
  address: '20%',
  standard_code: '8%',
  product_name: '16%',
  sales_amount: '7%',
  sales_date: '6%',
  actions: '8%',
}

const revenues = ref([])
const filteredRevenues = ref([])
const loading = ref(false)
const searchInput = ref('');
const searchKeyword = ref('');
const router = useRouter()
const fileInput = ref(null)
const fromMonth = ref('')
const toMonth = ref('')
const availableMonths = ref([])
const currentPageFirstIndex = ref(0)
const pageSize = ref(50)

// 매출액 합계 계산
const totalSalesAmount = computed(() => {
  return filteredRevenues.value.reduce((sum, revenue) => {
    return sum + (revenue.sales_amount || 0)
  }, 0)
})

function goCreate() {
  router.push('/admin/direct-revenue/create')
}

// 클라이언트 페이징이므로 onPageChange 불필요
const fetchRevenues = async () => {
  loading.value = true;
  try {
    const { data, error } = await supabase
      .from('direct_sales')
      .select('*')
      .order('sales_date', { ascending: false })
    if (!error && data) {
      revenues.value = data.map((item) => ({
        ...item,
        isEditing: false,
        originalData: { ...item },
      }))
      filteredRevenues.value = revenues.value;
    }
  } finally {
    loading.value = false;
  }
}

const fetchAvailableMonths = async () => {
  const { data, error } = await supabase
    .from('direct_sales')
    .select('sales_date')
    .order('sales_date', { ascending: false })
  if (!error && data) {
    const monthSet = new Set()
    data.forEach((item) => {
      if (item.sales_date) {
        monthSet.add(item.sales_date.substring(0, 7))
      }
    })
    availableMonths.value = Array.from(monthSet).sort((a, b) => b.localeCompare(a))
    if (availableMonths.value.length > 0) {
      toMonth.value = availableMonths.value[0]
      fromMonth.value = availableMonths.value[Math.min(2, availableMonths.value.length - 1)]
    }
  }
}

function doSearch() {
  if (searchInput.value.length >= 2) {
    searchKeyword.value = searchInput.value;
    const keyword = searchKeyword.value.toLowerCase();
    filteredRevenues.value = revenues.value.filter(r =>
      (r.pharmacy_name && r.pharmacy_name.toLowerCase().includes(keyword)) ||
      (r.business_registration_number && r.business_registration_number.toLowerCase().includes(keyword)) ||
      (r.standard_code && r.standard_code.toLowerCase().includes(keyword)) ||
      (r.product_name && r.product_name.toLowerCase().includes(keyword))
    );
  }
}
function clearSearch() {
  searchInput.value = '';
  searchKeyword.value = '';
  filteredRevenues.value = revenues.value;
}

// 수정 시작
const startEdit = (row) => {
  // 다른 행이 편집 중이면 취소
  revenues.value.forEach((item) => {
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
    if (!row.business_registration_number || row.business_registration_number.trim() === '') {
      alert('사업자등록번호는 필수 입력 항목입니다.');
      await nextTick();
      setTimeout(() => {
        const businessNumberInput = document.getElementById(`business_registration_number_${row.id}`);
        if (businessNumberInput) {
          businessNumberInput.focus();
          businessNumberInput.select();
        }
      }, 100);
      return;
    }

    if (!row.standard_code || row.standard_code.toString().trim() === '') {
      alert('표준코드는 필수 입력 항목입니다.');
      await nextTick();
      setTimeout(() => {
        const standardCodeInput = document.getElementById(`standard_code_${row.id}`);
        if (standardCodeInput) {
          standardCodeInput.focus();
          standardCodeInput.select();
        }
      }, 100);
      return;
    }

    if (!row.sales_amount || row.sales_amount.toString().trim() === '') {
      alert('매출액은 필수 입력 항목입니다.');
      await nextTick();
      setTimeout(() => {
        const salesAmountInput = document.getElementById(`sales_amount_${row.id}`);
        if (salesAmountInput) {
          salesAmountInput.focus();
          salesAmountInput.select();
        }
      }, 100);
      return;
    }

    if (!row.sales_date || row.sales_date.toString().trim() === '') {
      alert('매출일자는 필수 입력 항목입니다.');
      await nextTick();
      setTimeout(() => {
        const salesDateInput = document.getElementById(`sales_date_${row.id}`);
        if (salesDateInput) {
          salesDateInput.focus();
          salesDateInput.select();
        }
      }, 100);
      return;
    }

    // 사업자등록번호 형식 검증 (10자리 숫자)
    const businessNumberDigits = row.business_registration_number.replace(/[^0-9]/g, '');
    if (businessNumberDigits.length !== 10) {
      alert('사업자등록번호는 10자리여야 합니다.');
      await nextTick();
      setTimeout(() => {
        const businessNumberInput = document.getElementById(`business_registration_number_${row.id}`);
        if (businessNumberInput) {
          businessNumberInput.focus();
          businessNumberInput.select();
        }
      }, 100);
      return;
    }

    // 표준코드 형식 검증 (13자리 숫자)
    if (row.standard_code.toString().length !== 13 || !/^\d{13}$/.test(row.standard_code.toString())) {
      alert('표준코드는 13자리 숫자여야 합니다.');
      await nextTick();
      setTimeout(() => {
        const standardCodeInput = document.getElementById(`standard_code_${row.id}`);
        if (standardCodeInput) {
          standardCodeInput.focus();
          standardCodeInput.select();
        }
      }, 100);
      return;
    }

    // 매출액 형식 검증 (숫자, 마이너스 허용)
    if (isNaN(Number(row.sales_amount))) {
      alert('매출액은 숫자여야 합니다.');
      await nextTick();
      setTimeout(() => {
        const salesAmountInput = document.getElementById(`sales_amount_${row.id}`);
        if (salesAmountInput) {
          salesAmountInput.focus();
          salesAmountInput.select();
        }
      }, 100);
      return;
    }

    // 매출일자 형식 검증 (YYYY-MM-DD)
    const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (!dateRegex.test(row.sales_date)) {
      alert('매출일자는 YYYY-MM-DD 형식이어야 합니다.');
      await nextTick();
      setTimeout(() => {
        const salesDateInput = document.getElementById(`sales_date_${row.id}`);
        if (salesDateInput) {
          salesDateInput.focus();
          salesDateInput.select();
        }
      }, 100);
      return;
    }

    const userId = await getCurrentUserId();
    const updateData = {
      pharmacy_code: row.pharmacy_code || '',
      pharmacy_name: row.pharmacy_name || '',
      business_registration_number: row.business_registration_number,
      address: row.address || '',
      standard_code: row.standard_code,
      product_name: row.product_name || '',
      sales_amount: row.sales_amount ? Number(row.sales_amount) : null, // NULL 가능하도록 수정
      sales_date: row.sales_date || null, // 빈 문자열이면 null로 처리
      updated_by: userId,
    }

    const { error } = await supabase.from('direct_sales').update(updateData).eq('id', row.id)

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
const deleteRevenue = async (row) => {
  if (!confirm('정말 삭제하시겠습니까?')) {
    return
  }

  try {
    const { error } = await supabase.from('direct_sales').delete().eq('id', row.id)

    if (error) {
      alert('삭제 실패: ' + error.message)
      return
    }

    // 목록에서 제거
    const index = revenues.value.findIndex((item) => item.id === row.id)
    if (index > -1) {
      revenues.value.splice(index, 1)
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
      약국코드: 'PH001',
      약국명: '예시약국',
      사업자등록번호: '123-45-67890',
      주소: '서울시 강남구 테헤란로 123',
      표준코드: 'STD001',
      제품명: '예시제품',
      매출액: 100000,
      매출일자: '2025-01-15',
    },
  ]

  const ws = XLSX.utils.json_to_sheet(templateData)
  const wb = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(wb, ws, '직거래매출템플릿')

  // 컬럼 너비 설정
  ws['!cols'] = [
    { width: 12 }, // 약국코드
    { width: 20 }, // 약국명
    { width: 15 }, // 사업자등록번호
    { width: 30 }, // 주소
    { width: 12 }, // 표준코드
    { width: 20 }, // 제품명
    { width: 12 }, // 매출액
    { width: 12 }, // 매출일자
  ]

  XLSX.writeFile(wb, '직거래매출자료_엑셀등록_템플릿.xlsx')
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
    const userId = await getCurrentUserId();

    jsonData.forEach((row, index) => {
      const rowNum = index + 2 // 엑셀 행 번호 (헤더 제외)

      // 필수 필드 검증
      if (!row['사업자등록번호']) {
        errors.push(`${rowNum}행: 사업자등록번호가 필요합니다.`)
        return
      }
      if (!row['표준코드']) {
        errors.push(`${rowNum}행: 표준코드가 필요합니다.`)
        return
      }
      if (!row['매출액']) {
        errors.push(`${rowNum}행: 매출액이 필요합니다.`)
        return
      }
      if (!row['매출일자']) {
        errors.push(`${rowNum}행: 매출일자가 필요합니다.`)
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

      // 표준코드 형식 검증 (13자리 숫자)
      if (row['표준코드'].toString().length !== 13 || !/^\d{13}$/.test(row['표준코드'].toString())) {
        errors.push(`${rowNum}행: 표준코드는 13자리 숫자여야 합니다.`)
        return
      }

      // 매출액 형식 검증 (숫자, 마이너스 허용)
      const salesAmountValue = Number(row['매출액']);
      if (isNaN(salesAmountValue)) {
        errors.push(`${rowNum}행: 매출액은 숫자여야 합니다.`)
        return
      }

      // 매출일자 형식 검증 (YYYY-MM-DD)
      let salesDate = null
      if (row['매출일자']) {
        if (typeof row['매출일자'] === 'number') {
          const excelDate = new Date((row['매출일자'] - 25569) * 86400 * 1000)
          salesDate = excelDate.toISOString().split('T')[0]
        } else if (row['매출일자'] instanceof Date) {
          salesDate = row['매출일자'].toISOString().split('T')[0]
        } else if (typeof row['매출일자'] === 'string') {
          const dateRegex = /^\d{4}-\d{2}-\d{2}$/
          if (dateRegex.test(row['매출일자'])) {
            salesDate = row['매출일자']
          } else {
            errors.push(`${rowNum}행: 매출일자는 YYYY-MM-DD 형식이어야 합니다.`)
            return
          }
        }
      } else {
        errors.push(`${rowNum}행: 매출일자가 필요합니다.`)
        return
      }

      uploadData.push({
        pharmacy_code: row['약국코드'] || '',
        pharmacy_name: row['약국명'] || '',
        business_registration_number: formattedBusinessNumber,
        address: row['주소'] || '',
        standard_code: row['표준코드'],
        product_name: row['제품명'] || '',
        sales_amount: salesAmountValue,
        sales_date: salesDate,
        created_by: userId,
        updated_by: userId,
      })
    })

    if (errors.length > 0) {
      alert('데이터 오류:\n' + errors.join('\n'))
      return
    }

    // 데이터베이스에 일괄 삽입
    const { error } = await supabase.from('direct_sales').insert(uploadData)

    if (error) {
      alert('업로드 실패: ' + error.message)
    } else {
      alert(`${uploadData.length}건의 직거래매출 데이터가 업로드되었습니다.`)
      await fetchRevenues() // 목록 새로고침
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
  if (revenues.value.length === 0) {
    alert('다운로드할 데이터가 없습니다.')
    return
  }

  // 데이터 변환
  const excelData = revenues.value.map((revenue) => ({
    약국코드: revenue.pharmacy_code || '',
    약국명: revenue.pharmacy_name || '',
    사업자등록번호: revenue.business_registration_number || '',
    주소: revenue.address || '',
    표준코드: revenue.standard_code || '',
    제품명: revenue.product_name || '',
    매출액: revenue.sales_amount || 0,
    매출일자: revenue.sales_date || '',
    등록일: revenue.created_at ? new Date(revenue.created_at).toISOString().split('T')[0] : '',
    수정일: revenue.updated_at ? new Date(revenue.updated_at).toISOString().split('T')[0] : '',
  }))

  const ws = XLSX.utils.json_to_sheet(excelData)
  const wb = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(wb, ws, '직거래매출목록')

  // 컬럼 너비 설정
  ws['!cols'] = [
    { width: 12 }, // 약국코드
    { width: 20 }, // 약국명
    { width: 15 }, // 사업자등록번호
    { width: 30 }, // 주소
    { width: 12 }, // 표준코드
    { width: 20 }, // 제품명
    { width: 12 }, // 매출액
    { width: 12 }, // 매출일자
    { width: 12 }, // 등록일
    { width: 12 }, // 수정일
  ]

  // 매출액 컬럼에 숫자 형식 적용 (천단위 콤마)
  const range = XLSX.utils.decode_range(ws['!ref'])
  for (let row = 1; row <= range.e.r; row++) {
    // 헤더 제외하고 시작
    const cellAddress = XLSX.utils.encode_cell({ r: row, c: 6 }) // 매출액은 7번째 컬럼 (인덱스 6)
    if (ws[cellAddress]) {
      ws[cellAddress].z = '#,##0' // 천단위 콤마 형식
    }
  }

  const fileName = generateExcelFileName('직거래매출목록')

  XLSX.writeFile(wb, fileName)
}

async function deleteAllRevenues() {
  if (!confirm('정말 모든 직거래매출 데이터를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'))
    return
  const { error } = await supabase.from('direct_sales').delete().neq('id', 0)
  if (error) {
    alert('삭제 중 오류가 발생했습니다: ' + error.message)
    return
  }
  revenues.value = []
  alert('모든 직거래매출 데이터가 삭제되었습니다.')
}

async function getCurrentUserId() {
  const { data: { user } } = await supabase.auth.getUser();
  return user?.id;
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
  
  console.log('직거래매출 오버플로우 체크:', {
    text: element.textContent,
    textWidth,
    availableWidth,
    isOverflowed
  });
  
  if (isOverflowed) {
    element.classList.add('overflowed');
    console.log('직거래매출 오버플로우 클래스 추가됨');
  } else {
    element.classList.remove('overflowed'); // Ensure class is removed if not overflowed
    console.log('직거래매출 오버플로우 아님 - 클래스 제거됨');
  }
}

const removeOverflowClass = (event) => {
  const element = event.target;
  element.classList.remove('overflowed');
  console.log('직거래매출 오버플로우 클래스 제거됨');
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
  fetchRevenues()
  fetchAvailableMonths()
})
</script>

<style scoped>
.footer-cell {
  background-color: #f8f9fa !important;
  font-weight: bold !important;
  border-top: 1px solid #dee2e6 !important;
}
</style>
