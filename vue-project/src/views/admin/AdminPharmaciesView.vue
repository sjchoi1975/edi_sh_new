<template>
  <div class="admin-clients-view">
    <div class="header-title">문전약국 목록</div>
    <div class="table-container">
      <div class="table-header">
        <div style="display: flex; align-items: center; gap: 16px;">
          <span class="p-input-icon-left">
            <InputText
              v-model="filters['global'].value"
              placeholder="약국코드, 약국명, 사업자등록번호 검색"
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
        :value="pharmacies"
        paginator
        :rows="20"
        :rowsPerPageOptions="[20, 50, 100]"
        scrollable
        scrollHeight="680px"
        v-model:filters="filters"
        :globalFilterFields="['pharmacy_code', 'name', 'business_registration_number']"
        class="custom-table"
      >
        <template #empty>등록된 약국이 없습니다.</template>
        <template #loading>약국 목록을 불러오는 중입니다...</template>
        <Column field="pharmacy_code" header="약국코드" :headerStyle="{ width: '8%' }" :sortable="true">
          <template #body="slotProps">
            <input 
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.pharmacy_code"
              style="width: 100%; border: 1px solid #ddd; padding: 4px;"
            />
            <span v-else>{{ slotProps.data.pharmacy_code }}</span>
          </template>
        </Column>
        <Column field="name" header="약국명" :headerStyle="{ width: '18%' }" :sortable="true">
          <template #body="slotProps">
            <input 
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.name"
              style="width: 100%; border: 1px solid #ddd; padding: 4px;"
            />
            <a
              v-else
              href="#"
              style="color:#1976d2;text-decoration:underline;cursor:pointer;"
              @click.prevent="goToDetail(slotProps.data.id)"
            >
              {{ slotProps.data.name }}
            </a>
          </template>
        </Column>
        <Column field="business_registration_number" header="사업자등록번호" :headerStyle="{ width: '10%' }" :sortable="true">
          <template #body="slotProps">
            <input 
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.business_registration_number"
              style="width: 100%; border: 1px solid #ddd; padding: 4px;"
            />
            <span v-else>{{ slotProps.data.business_registration_number }}</span>
          </template>
        </Column>
        <Column field="address" header="주소" :headerStyle="{ width: '32%' }" :sortable="true">
          <template #body="slotProps">
            <input 
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.address"
              style="width: 100%; border: 1px solid #ddd; padding: 4px;"
            />
            <span v-else>{{ slotProps.data.address }}</span>
          </template>
        </Column>
        <Column field="remarks" header="비고" :headerStyle="{ width: '12%' }" :sortable="true">
          <template #body="slotProps">
            <input 
              v-if="slotProps.data.isEditing"
              v-model="slotProps.data.remarks"
              style="width: 100%; border: 1px solid #ddd; padding: 4px;"
            />
            <span v-else>{{ slotProps.data.remarks }}</span>
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
        <Column header="작업" :headerStyle="{ width: '14%' }">
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
                  @click="deletePharmacy(slotProps.data)"
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
import { ref, onMounted } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import InputText from 'primevue/inputtext';
import { useRouter } from 'vue-router';
import { supabase } from '@/supabase';
import * as XLSX from 'xlsx';

const pharmacies = ref([]);
const filters = ref({ 'global': { value: null, matchMode: 'contains' } });
const router = useRouter();
const fileInput = ref(null);

function goCreate() {
  router.push('/admin/pharmacies/create');
}
function goToDetail(id) {
  router.push(`/admin/pharmacies/${id}`);
}

const fetchPharmacies = async () => {
  const { data, error } = await supabase
    .from('pharmacies')
    .select('*')
    .order('pharmacy_code', { ascending: true });
  if (!error && data) {
    // 각 행에 편집 상태와 원본 데이터 백업 추가
    pharmacies.value = data.map(item => ({
      ...item,
      isEditing: false,
      originalData: { ...item }
    }));
  }
};

// 수정 시작
const startEdit = (row) => {
  // 다른 행이 편집 중이면 취소
  pharmacies.value.forEach(item => {
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
    if (!row.name || !row.business_registration_number) {
      alert('필수 항목을 모두 입력하세요. (약국명, 사업자등록번호)');
      return;
    }
    
    // 상태 값 검증
    if (!['active', 'inactive'].includes(row.status)) {
      alert('상태는 active 또는 inactive여야 합니다.');
      return;
    }
    
    const updateData = {
      pharmacy_code: row.pharmacy_code || '',
      name: row.name,
      business_registration_number: row.business_registration_number,
      address: row.address || '',
      remarks: row.remarks || '',
      status: row.status
    };
    
    const { error } = await supabase
      .from('pharmacies')
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
const deletePharmacy = async (row) => {
  if (!confirm('정말 삭제하시겠습니까?')) {
    return;
  }
  
  try {
    const { error } = await supabase
      .from('pharmacies')
      .delete()
      .eq('id', row.id);
    
    if (error) {
      alert('삭제 실패: ' + error.message);
      return;
    }
    
    // 목록에서 제거
    const index = pharmacies.value.findIndex(item => item.id === row.id);
    if (index > -1) {
      pharmacies.value.splice(index, 1);
    }
    
    alert('삭제되었습니다.');
    
  } catch (error) {
    console.error('삭제 오류:', error);
    alert('삭제 중 오류가 발생했습니다.');
  }
};

// 엑셀 템플릿 다운로드
const downloadTemplate = () => {
  const templateData = [
    {
      '약국코드': 'PH001',
      '약국명': '예시약국',
      '사업자등록번호': '123-45-67890',
      '주소': '서울시 강남구 테헤란로 123',
      '비고': '예시 비고',
      '상태': 'active'
    }
  ];
  
  const ws = XLSX.utils.json_to_sheet(templateData);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '문전약국템플릿');
  
  // 컬럼 너비 설정
  ws['!cols'] = [
    { width: 12 }, // 약국코드
    { width: 20 }, // 약국명
    { width: 15 }, // 사업자등록번호
    { width: 30 }, // 주소
    { width: 20 }, // 비고
    { width: 10 }  // 상태
  ];
  
  XLSX.writeFile(wb, '문전약국_업로드_템플릿.xlsx');
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
      if (!row['약국명']) {
        errors.push(`${rowNum}행: 약국명이 필요합니다.`);
        return;
      }
      if (!row['사업자등록번호']) {
        errors.push(`${rowNum}행: 사업자등록번호가 필요합니다.`);
        return;
      }
      
      // 상태 값 검증
      const status = row['상태'] || 'active';
      if (!['active', 'inactive'].includes(status)) {
        errors.push(`${rowNum}행: 상태는 'active' 또는 'inactive'여야 합니다.`);
        return;
      }
      
      uploadData.push({
        pharmacy_code: row['약국코드'] || '',
        name: row['약국명'],
        business_registration_number: row['사업자등록번호'],
        address: row['주소'] || '',
        remarks: row['비고'] || '',
        status: status
      });
    });
    
    if (errors.length > 0) {
      alert('데이터 오류:\n' + errors.join('\n'));
      return;
    }
    
    // 데이터베이스에 일괄 삽입
    const { error } = await supabase
      .from('pharmacies')
      .insert(uploadData);
    
    if (error) {
      alert('업로드 실패: ' + error.message);
    } else {
      alert(`${uploadData.length}건의 문전약국 데이터가 업로드되었습니다.`);
      await fetchPharmacies(); // 목록 새로고침
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
  if (pharmacies.value.length === 0) {
    alert('다운로드할 데이터가 없습니다.');
    return;
  }
  
  // 데이터 변환
  const excelData = pharmacies.value.map(pharmacy => ({
    '약국코드': pharmacy.pharmacy_code || '',
    '약국명': pharmacy.name || '',
    '사업자등록번호': pharmacy.business_registration_number || '',
    '주소': pharmacy.address || '',
    '비고': pharmacy.remarks || '',
    '상태': pharmacy.status === 'active' ? '활성' : '비활성',
    '등록일': pharmacy.created_at ? new Date(pharmacy.created_at).toISOString().split('T')[0] : '',
    '수정일': pharmacy.updated_at ? new Date(pharmacy.updated_at).toISOString().split('T')[0] : ''
  }));
  
  const ws = XLSX.utils.json_to_sheet(excelData);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '문전약국목록');
  
  // 컬럼 너비 설정
  ws['!cols'] = [
    { width: 12 }, // 약국코드
    { width: 20 }, // 약국명
    { width: 15 }, // 사업자등록번호
    { width: 30 }, // 주소
    { width: 20 }, // 비고
    { width: 10 }, // 상태
    { width: 12 }, // 등록일
    { width: 12 }  // 수정일
  ];
  
  // 파일명에 현재 날짜 포함
  const today = new Date().toISOString().split('T')[0];
  const fileName = `문전약국목록_${today}.xlsx`;
  
  XLSX.writeFile(wb, fileName);
};

onMounted(() => {
  fetchPharmacies();
});
</script> 