<template>
  <div class="admin-products-view">
    <div class="header-title">제품 목록</div>
    <div class="table-container">
      <div class="table-header">
        <div style="display: flex; align-items: center; gap: 16px;">
          <span style="display:flex;align-items:center;gap:8px;">
            <label>기준월</label>
            <Calendar
              v-model="selectedMonth"
              view="month"
              dateFormat="yy-mm"
              showIcon
              placeholder="YYYY-MM"
              inputClass="p-datepicker"
              :locale="koLocale"
            />
          </span>
          <span class="p-input-icon-left">
            <InputText
                  v-model="filters['global'].value"
                  placeholder="제품명, 보험코드 검색"
                  class="search-input"
                />
          </span>
        </div>
        <div class="action-buttons">
          <button class="btn-secondary" @click="downloadTemplate">엑셀 템플릿 다운로드</button>
          <button class="btn-secondary" @click="triggerFileUpload">엑셀 업로드</button>
          <button class="btn-secondary" @click="downloadExcel">엑셀 다운로드</button>
          <input 
            ref="fileInput" 
            type="file" 
            accept=".xlsx,.xls" 
            @change="handleFileUpload" 
            style="display: none;"
          />
          <button class="btn-primary" @click="goCreate">등록</button>
        </div>
      </div>
      <DataTable
        :value="filteredProducts"
        paginator
        :rows="20"
        :rowsPerPageOptions="[20, 50, 100]"
        scrollable
        scrollHeight="680px"
        v-model:filters="filters"
        :globalFilterFields="['base_month', 'product_name', 'insurance_code']"
        class="custom-table"
        v-model:first="currentPageFirstIndex"
      >
        <template #empty>
          등록된 제품이 없습니다.
        </template>
        <template #loading>
          제품 목록을 불러오는 중입니다...
        </template>
        <Column header="No" :headerStyle="{ width: '4%' }">
          <template #body="slotProps">
            {{ slotProps.index + currentPageFirstIndex + 1 }}
          </template>
        </Column>
        <Column field="product_name" header="제품명" :headerStyle="{ width: '12%' }" :sortable="true">
          <template #body="slotProps">
            <input 
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.product_name"
              style="width: 100%; border: 1px solid #ddd; padding: 4px;"
            />
            <a
              v-else
              href="#"
              style="color:#1976d2;text-decoration:underline;cursor:pointer;"
              @click.prevent="goToDetail(slotProps.data.id)"
            >
              {{ slotProps.data.product_name }}
            </a>
          </template>
        </Column>
        <Column field="insurance_code" header="보험코드" :headerStyle="{ width: '8%' }" :sortable="true">
          <template #body="slotProps">
            <input 
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.insurance_code"
              style="width: 100%; border: 1px solid #ddd; padding: 4px;"
            />
            <span v-else>{{ slotProps.data.insurance_code }}</span>
          </template>
        </Column>
        <Column field="price" header="약가" :headerStyle="{ width: '6%' }" :sortable="true">
          <template #body="slotProps">
            <input 
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.price"
              type="number"
              style="width: 100%; border: 1px solid #ddd; padding: 4px; text-align: right;"
            />
            <span v-else>{{ slotProps.data.price }}</span>
          </template>
        </Column>
        <Column header="수수료A(%)" :headerStyle="{ width: '7%' }" :sortable="true">
          <template #body="slotProps">
            <input 
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.commission_rate_a"
              type="number"
              step="0.01"
              style="width: 100%; border: 1px solid #ddd; padding: 4px; text-align: right;"
            />
            <span v-else>{{ slotProps.data.commission_rate_a ? (slotProps.data.commission_rate_a * 100).toFixed(1) : '-' }}</span>
          </template>
        </Column>
        <Column header="수수료B(%)" :headerStyle="{ width: '7%' }" :sortable="true">
          <template #body="slotProps">
            <input 
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.commission_rate_b"
              type="number"
              step="0.01"
              style="width: 100%; border: 1px solid #ddd; padding: 4px; text-align: right;"
            />
            <span v-else>{{ slotProps.data.commission_rate_b ? (slotProps.data.commission_rate_b * 100).toFixed(1) : '-' }}</span>
          </template>
        </Column>
        <Column field="standard_code" header="표준코드" :headerStyle="{ width: '10%' }" :sortable="true">
          <template #body="slotProps">
            <input 
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.standard_code"
              style="width: 100%; border: 1px solid #ddd; padding: 4px;"
            />
            <span v-else>{{ slotProps.data.standard_code }}</span>
          </template>
        </Column>
        <Column field="unit_packaging_desc" header="단위/포장형태" :headerStyle="{ width: '7%' }" :sortable="true">
          <template #body="slotProps">
            <input 
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.unit_packaging_desc"
              style="width: 100%; border: 1px solid #ddd; padding: 4px;"
            />
            <span v-else>{{ slotProps.data.unit_packaging_desc }}</span>
          </template>
        </Column>
        <Column field="unit_quantity" header="단위수량" :headerStyle="{ width: '7%' }" :sortable="true">
          <template #body="slotProps">
            <input 
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.unit_quantity"
              type="number"
              style="width: 100%; border: 1px solid #ddd; padding: 4px; text-align: right;"
            />
            <span v-else>{{ slotProps.data.unit_quantity }}</span>
          </template>
        </Column>
        <Column field="remarks" header="비고" :headerStyle="{ width: '10%' }" :sortable="true">
          <template #body="slotProps">
            <input 
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.remarks"
              style="width: 100%; border: 1px solid #ddd; padding: 4px;"
            />
            <span v-else>{{ slotProps.data.remarks }}</span>
          </template>
        </Column>
        <Column field="created_at" header="등록일자" :headerStyle="{ width: '8%' }" :sortable="true">
          <template #body="slotProps">
            <span>{{ slotProps.data.created_at ? new Date(slotProps.data.created_at).toISOString().split('T')[0] : '' }}</span>
          </template>
        </Column>
        <Column field="status" header="상태" :headerStyle="{ width: '6%' }" :sortable="true">
          <template #body="slotProps">
            <select 
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.status"
              style="width: 100%; border: 1px solid #ddd; padding: 4px;"
            >
              <option value="active">활성</option>
              <option value="inactive">비활성</option>
            </select>
            <span v-else :class="slotProps.data.status === 'active' ? 'active-badge' : 'inactive-badge'">
              {{ slotProps.data.status === 'active' ? '활성' : '비활성' }}
            </span>
          </template>
        </Column>
        <Column header="작업" :headerStyle="{ width: '12%' }">
          <template #body="slotProps">
            <div style="display: flex; gap: 4px; justify-content: center;">
              <template v-if="slotProps.data.isEditing">
                <button 
                  @click="saveEdit(slotProps.data)"
                  class="btn-save-m"
                  title="저장"
                >
                  저장
                </button>
                <button 
                  @click="cancelEdit(slotProps.data)"
                  class="btn-cancel-m"
                  title="취소"
                >
                  취소
                </button>
              </template>
              <template v-else>
                <button 
                  @click="startEdit(slotProps.data)"
                  class="btn-edit-m"
                  title="수정"
                >
                  수정
                </button>
                <button 
                  @click="deleteProduct(slotProps.data)"
                  class="btn-delete-m"
                  title="삭제"
                >
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
import { ref, computed, onMounted } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import InputText from 'primevue/inputtext';
import Calendar from 'primevue/calendar';
import { useRouter } from 'vue-router';
import { supabase } from '@/supabase';
import * as XLSX from 'xlsx';

const products = ref([]);
const filters = ref({ 'global': { value: null, matchMode: 'contains' } });
const selectedMonth = ref(new Date()); // Date 객체로 관리
const router = useRouter();
const fileInput = ref(null);
const currentPageFirstIndex = ref(0); // 추가

const koLocale = {
  firstDayOfWeek: 0,
  dayNames: ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'],
  dayNamesShort: ['일', '월', '화', '수', '목', '금', '토'],
  dayNamesMin: ['일', '월', '화', '수', '목', '금', '토'],
  monthNames: ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'],
  monthNamesShort: ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'],
  today: '오늘',
  clear: '초기화'
}

const filteredProducts = computed(() => {
  if (!selectedMonth.value) return products.value;
  const year = selectedMonth.value.getFullYear();
  const month = String(selectedMonth.value.getMonth() + 1).padStart(2, '0');
  const ym = `${year}-${month}`;
  return products.value.filter(p => p.base_month === ym);
});

function goCreate() {
  router.push('/admin/products/create');
}
function goToDetail(id) {
  router.push(`/admin/products/${id}`);
}

const fetchProducts = async () => {
  const { data, error } = await supabase
    .from('products')
    .select('*')
    .order('base_month', { ascending: false })
    .order('product_name', { ascending: true });
  if (!error && data) {
    // 각 행에 편집 상태와 원본 데이터 백업 추가
    products.value = data.map(item => ({
      ...item,
      isEditing: false,
      originalData: { ...item }
    }));
  }
};

onMounted(() => {
  fetchProducts();
});

// 엑셀 템플릿 다운로드
const downloadTemplate = () => {
  const templateData = [
    {
      '기준월': '2025-01',
      '제품명': '예시제품',
      '보험코드': 'INS001',
      '약가': 1000,
      '수수료A': 0.1,
      '수수료B': 0.15,
      '표준코드': 'STD001',
      '단위포장형태': '정 10개',
      '단위수량': 10,
      '비고': '예시 비고',
      '상태': '활성'
    }
  ];
  
  const ws = XLSX.utils.json_to_sheet(templateData);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '제품템플릿');
  
  // 컬럼 너비 설정
  ws['!cols'] = [
    { width: 10 }, // 기준월
    { width: 20 }, // 제품명
    { width: 12 }, // 보험코드
    { width: 10 }, // 약가
    { width: 10 }, // 수수료A
    { width: 10 }, // 수수료B
    { width: 12 }, // 표준코드
    { width: 15 }, // 단위포장형태
    { width: 10 }, // 단위수량
    { width: 20 }, // 비고
    { width: 10 }  // 상태
  ];
  
  XLSX.writeFile(wb, '제품_업로드_템플릿.xlsx');
};

// 파일 업로드 트리거
const triggerFileUpload = () => {
  fileInput.value.click();
};

// 엑셀 파일 업로드 처리
const handleFileUpload = async (event) => {
  const file = event.target.files[0];
  if (!file) return;
  
  try {
    const data = await file.arrayBuffer();
    const workbook = XLSX.read(data);
    const worksheet = workbook.Sheets[workbook.SheetNames[0]];
    const jsonData = XLSX.utils.sheet_to_json(worksheet);
    
    if (jsonData.length === 0) {
      alert('엑셀 파일에 데이터가 없습니다.');
      return;
    }
    
    // 데이터 변환 및 검증
    const uploadData = [];
    const errors = [];
    
    jsonData.forEach((row, index) => {
      const rowNum = index + 2; // 엑셀 행 번호 (헤더 제외)
      
      // 필수 필드 검증
      if (!row['기준월']) {
        errors.push(`${rowNum}행: 기준월이 필요합니다.`);
        return;
      }
      if (!row['제품명']) {
        errors.push(`${rowNum}행: 제품명이 필요합니다.`);
        return;
      }
      if (!row['보험코드']) {
        errors.push(`${rowNum}행: 보험코드가 필요합니다.`);
        return;
      }
      
      // 기준월 형식 검증 (YYYY-MM)
      const monthRegex = /^\d{4}-\d{2}$/;
      if (!monthRegex.test(row['기준월'])) {
        errors.push(`${rowNum}행: 기준월은 YYYY-MM 형식이어야 합니다.`);
        return;
      }
      
      // 상태 값 검증 및 변환
      let statusValue = 'active'; // 기본값
      if (row['상태']) {
        if (row['상태'] === '활성') {
          statusValue = 'active';
        } else if (row['상태'] === '비활성') {
          statusValue = 'inactive';
        } else {
          errors.push(`${rowNum}행: 상태는 '활성' 또는 '비활성'이어야 합니다.`);
          return;
        }
      } else {
        // 상태 값이 비어있으면 기본값 '활성'('active') 사용
        statusValue = 'active';
      }
      
      uploadData.push({
        base_month: row['기준월'],
        product_name: row['제품명'],
        insurance_code: row['보험코드'],
        price: Number(row['약가']) || 0,
        commission_rate_a: Number(row['수수료A']) || 0,
        commission_rate_b: Number(row['수수료B']) || 0,
        standard_code: row['표준코드'] || '',
        unit_packaging_desc: row['단위포장형태'] || '',
        unit_quantity: Number(row['단위수량']) || 0,
        remarks: row['비고'] || '',
        status: statusValue // 변환된 값 사용
      });
    });
    
    if (errors.length > 0) {
      alert('데이터 오류:\n' + errors.join('\n'));
      return;
    }
    
    // 데이터베이스에 일괄 삽입
    const { error } = await supabase
      .from('products')
      .insert(uploadData);
    
    if (error) {
      alert('업로드 실패: ' + error.message);
    } else {
      alert(`${uploadData.length}건의 제품 데이터가 업로드되었습니다.`);
      await fetchProducts(); // 목록 새로고침
    }
    
  } catch (error) {
    console.error('파일 처리 오류:', error);
    alert('파일 처리 중 오류가 발생했습니다.');
  } finally {
    // 파일 입력 초기화
    event.target.value = '';
  }
};

// 엑셀 다운로드 (현재 목록)
const downloadExcel = () => {
  if (filteredProducts.value.length === 0) {
    alert('다운로드할 데이터가 없습니다.');
    return;
  }
  
  // 데이터 변환
  const excelData = filteredProducts.value.map(product => ({
    '기준월': product.base_month || '',
    '제품명': product.product_name || '',
    '보험코드': product.insurance_code || '',
    '약가': product.price || 0,
    '수수료A': product.commission_rate_a || 0,
    '수수료B': product.commission_rate_b || 0,
    '표준코드': product.standard_code || '',
    '단위포장형태': product.unit_packaging_desc || '',
    '단위수량': product.unit_quantity || 0,
    '비고': product.remarks || '',
    '상태': product.status === 'active' ? '활성' : '비활성',
    '등록일': product.created_at ? new Date(product.created_at).toISOString().split('T')[0] : '',
    '수정일': product.updated_at ? new Date(product.updated_at).toISOString().split('T')[0] : ''
  }));
  
  const ws = XLSX.utils.json_to_sheet(excelData);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '제품목록');
  
  // 컬럼 너비 설정
  ws['!cols'] = [
    { width: 10 }, // 기준월
    { width: 20 }, // 제품명
    { width: 12 }, // 보험코드
    { width: 10 }, // 약가
    { width: 10 }, // 수수료A
    { width: 10 }, // 수수료B
    { width: 12 }, // 표준코드
    { width: 15 }, // 단위포장형태
    { width: 10 }, // 단위수량
    { width: 20 }, // 비고
    { width: 10 }, // 상태
    { width: 12 }, // 등록일
    { width: 12 }  // 수정일
  ];
  
  // 약가 컬럼에 숫자 형식 적용 (천단위 콤마)
  const range = XLSX.utils.decode_range(ws['!ref']);
  for (let row = 1; row <= range.e.r; row++) { // 헤더 제외하고 시작
    const cellAddress = XLSX.utils.encode_cell({ r: row, c: 3 }); // 약가는 4번째 컬럼 (인덱스 3)
    if (ws[cellAddress]) {
      ws[cellAddress].z = '#,##0'; // 천단위 콤마 형식
    }
  }
  
  // 파일명에 현재 날짜 포함
  const today = new Date().toISOString().split('T')[0];
  const fileName = `제품목록_${today}.xlsx`;
  
  XLSX.writeFile(wb, fileName);
};

// 수정 시작
const startEdit = (row) => {
  // 다른 행이 편집 중이면 취소
  products.value.forEach(item => {
    if (item.isEditing && item.id !== row.id) {
      cancelEdit(item);
    }
  });
  
  // 원본 데이터 백업
  row.originalData = { ...row };
  row.isEditing = true;
};

// 수정 취소
const cancelEdit = (row) => {
  // 원본 데이터로 복원
  Object.keys(row.originalData).forEach(key => {
    if (key !== 'isEditing' && key !== 'originalData') {
      row[key] = row.originalData[key];
    }
  });
  row.isEditing = false;
};

// 수정 저장
const saveEdit = async (row) => {
  try {
    // 필수 필드 검증
    if (!row.base_month || !row.product_name || !row.insurance_code) {
      alert('필수 항목을 모두 입력하세요.');
      return;
    }
    
    // 기준월 형식 검증 (YYYY-MM)
    const monthRegex = /^\d{4}-\d{2}$/;
    if (!monthRegex.test(row.base_month)) {
      alert('기준월은 YYYY-MM 형식이어야 합니다.');
      return;
    }
    
    // 상태 값 검증
    if (!['active', 'inactive'].includes(row.status)) {
      alert('상태는 active 또는 inactive여야 합니다.');
      return;
    }
    
    const updateData = {
      base_month: row.base_month,
      product_name: row.product_name,
      insurance_code: row.insurance_code,
      price: Number(row.price) || 0,
      commission_rate_a: Number(row.commission_rate_a) || 0,
      commission_rate_b: Number(row.commission_rate_b) || 0,
      standard_code: row.standard_code || '',
      unit_packaging_desc: row.unit_packaging_desc || '',
      unit_quantity: Number(row.unit_quantity) || 0,
      remarks: row.remarks || '',
      status: row.status
    };
    
    const { error } = await supabase
      .from('products')
      .update(updateData)
      .eq('id', row.id);
    
    if (error) {
      alert('수정 실패: ' + error.message);
      return;
    }
    
    // 편집 모드 종료
    row.isEditing = false;
    row.originalData = { ...row };
    
    alert('수정되었습니다.');
    
  } catch (error) {
    console.error('수정 오류:', error);
    alert('수정 중 오류가 발생했습니다.');
  }
};

// 삭제
const deleteProduct = async (row) => {
  if (!confirm('정말 삭제하시겠습니까?')) {
    return;
  }
  
  try {
    const { error } = await supabase
      .from('products')
      .delete()
      .eq('id', row.id);
    
    if (error) {
      alert('삭제 실패: ' + error.message);
      return;
    }
    
    // 목록에서 제거
    const index = products.value.findIndex(item => item.id === row.id);
    if (index > -1) {
      products.value.splice(index, 1);
    }
    
    alert('삭제되었습니다.');
    
  } catch (error) {
    console.error('삭제 오류:', error);
    alert('삭제 중 오류가 발생했습니다.');
  }
};
</script> 