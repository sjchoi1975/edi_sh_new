<template>
  <div class="performance-register-view page-container">
    <div class="page-header-title-area">
      <div class="header-title">엑셀 등록</div>
      <div class="breadcrumb">실적 관리 &gt; 엑셀 등록</div>
    </div>

    <!-- 필터 카드: 정산월만 -->
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

    <!-- 데이터 카드: 엑셀 업로드 -->
    <div class="data-card">
      <div class="data-card-header">
        <div class="total-count-display">엑셀 파일을 업로드하세요.</div>
        <div class="data-card-buttons">
          <input
            ref="excelFileInput"
            type="file"
            accept=".xlsx,.xls"
            @change="handleExcelUpload"
            style="display: none;"
          />
          <button class="btn-excell-template" @click="downloadExcelTemplate" :disabled="!selectedSettlementMonth">
            엑셀 템플릿 다운로드
          </button>
          <button class="btn-excell-upload" @click="triggerExcelUpload" :disabled="!selectedSettlementMonth">
            엑셀 일괄 등록
          </button>
          <button class="btn-save" @click="saveExcelData" :disabled="!canSave" style="margin-left:8px;">
            저장
          </button>
        </div>
      </div>
      <!-- PrimeVue DataTable 미리보기 -->
      <DataTable :value="previewRows" scrollable scrollHeight="calc(100vh - 350px)" class="custom-table performance-list-table" style="margin-top:2rem;">
        <Column header="No" :headerStyle="{ width: '4%' }">
          <template #body="slotProps">{{ slotProps.index + 1 }}</template>
        </Column>
        <Column field="거래처" header="거래처" :headerStyle="{ width: '12%' }">
          <template #body="slotProps">
            <Dropdown v-model="slotProps.data['거래처']"
              :options="myClientsList"
              optionLabel="name"
              optionValue="name"
              placeholder="선택"
              style="width:100%"
              @change="onPreviewClientChange(slotProps.data, slotProps.index)"
            />
          </template>
        </Column>
        <Column field="사업자등록번호" header="사업자등록번호" :headerStyle="{ width: '12%' }" />
        <Column field="주소" header="주소" :headerStyle="{ width: '18%' }" />
        <Column field="처방월" header="처방월" :headerStyle="{ width: '8%' }">
          <template #body="slotProps">
            <Dropdown v-model="slotProps.data['처방월']" :options="validMonths" placeholder="선택" style="width:100%" @change="onPreviewPrescriptionMonthChange(slotProps.data, slotProps.index)" />
          </template>
        </Column>
        <Column field="제품명" header="제품명" :headerStyle="{ width: '14%' }">
          <template #body="slotProps">
            <Dropdown v-model="slotProps.data['제품명']" :options="getProductsForMonth(slotProps.data['처방월'])" optionLabel="product_name" optionValue="product_name" placeholder="선택" style="width:100%" @change="onPreviewProductChange(slotProps.data, slotProps.index)" />
          </template>
        </Column>
        <Column field="보험코드" header="보험코드" :headerStyle="{ width: '8%' }" />
        <Column field="약가" header="약가" :headerStyle="{ width: '8%' }">
          <template #body="slotProps">
            <span>{{ slotProps.data['약가'] }}</span>
          </template>
        </Column>
        <Column field="수량" header="수량" :headerStyle="{ width: '7%' }">
          <template #body="slotProps">
            <InputText v-model="slotProps.data['수량']" @input="onPreviewQtyChange(slotProps.data, slotProps.index)" style="width:100%" />
          </template>
        </Column>
        <Column field="처방액" header="처방액" :headerStyle="{ width: '8%' }">
          <template #body="slotProps">
            <span>{{ slotProps.data['처방액'] }}</span>
          </template>
        </Column>
        <Column field="처방구분" header="처방구분" :headerStyle="{ width: '8%' }">
          <template #body="slotProps">
            <Dropdown v-model="slotProps.data['처방구분']" :options="prescriptionTypeOptions" placeholder="선택" style="width:100%" />
          </template>
        </Column>
        <Column field="비고" header="비고" :headerStyle="{ width: '10%' }">
          <template #body="slotProps">
            <InputText v-model="slotProps.data['비고']" style="width:100%" />
          </template>
        </Column>
        <Column header="작업" :headerStyle="{ width: '10%' }">
          <template #body="slotProps">
            <Button label="삭제" severity="danger" size="small" @click="removePreviewRow(slotProps.index)" style="margin-right:4px;" />
            <Button label="추가" severity="info" size="small" @click="addPreviewRowBelow(slotProps.index)" />
          </template>
        </Column>
      </DataTable>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';
import { supabase } from '@/supabase';
import * as XLSX from 'xlsx';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import InputText from 'primevue/inputtext';
import Dropdown from 'primevue/dropdown';
import Button from 'primevue/button';

const availableMonths = ref([]);
const selectedSettlementMonth = ref('');
const excelFileInput = ref(null);
const previewRows = ref([]);
const previewColumns = ref([]);
const canSave = ref(false);
const myClientsList = ref([]);
const validMonths = ref([]);
const prescriptionTypeOptions = [ 'EDI', '대한조제', '의료매출', '직거래매입', '차감', '원내매출', '원외매출' ];
const allProducts = ref([]);

async function fetchAvailableMonths() {
  const { data, error } = await supabase
    .from('settlement_months')
    .select('settlement_month')
    .eq('status', 'active')
    .order('settlement_month', { ascending: false });
  if (!error && data) {
    availableMonths.value = data.map((m) => m.settlement_month);
    if (availableMonths.value.length > 0) {
      selectedSettlementMonth.value = availableMonths.value[0];
    }
  }
}

function triggerExcelUpload() {
  excelFileInput.value.click();
}

function getColumnOrder() {
  return [
    '거래처',
    '사업자등록번호',
    '주소',
    '처방월',
    '제품명',
    '보험코드',
    '약가',
    '수량',
    '처방액',
    '처방구분',
    '비고'
  ];
}

async function matchProductByInsuranceCode(insuranceCode) {
  let normalizedCode = insuranceCode.toString().trim();
  // 1차: 입력값 그대로
  let { data, error } = await supabase
    .from('products')
    .select('*')
    .eq('insurance_code', normalizedCode);
  if (!error && data && data.length > 0) return data[0];
  // 2차: 9자리면 앞에 0 붙여서
  if (normalizedCode.length === 9) {
    let padded = '0' + normalizedCode;
    let { data: retryData, error: retryError } = await supabase
      .from('products')
      .select('*')
      .eq('insurance_code', padded);
    if (!retryError && retryData && retryData.length > 0) return retryData[0];
  }
  // 3차: 10자리면서 0으로 시작하면 0 제거
  if (normalizedCode.length === 10 && normalizedCode.startsWith('0')) {
    let trimmed = normalizedCode.substring(1);
    let { data: retryData, error: retryError } = await supabase
      .from('products')
      .select('*')
      .eq('insurance_code', trimmed);
    if (!retryError && retryData && retryData.length > 0) return retryData[0];
  }
  return null;
}

async function checkProductActiveInMonth(insuranceCode, prescriptionMonth) {
  const { data, error } = await supabase
    .from('products')
    .select('id, status, product_name, price')
    .eq('insurance_code', insuranceCode)
    .eq('base_month', prescriptionMonth);
  if (!error && Array.isArray(data) && data.some(item => item.status === 'active')) {
    // active인 첫 번째 제품 반환
    return data.find(item => item.status === 'active');
  }
  return null;
}

// 거래처, 처방월, 제품 데이터 fetch (엑셀 업로드 후에도 항상 최신)
async function fetchDropdownData() {
  // 거래처
  const { data: { session } } = await supabase.auth.getSession();
  if (!session?.user) return;
  const { data: company } = await supabase
    .from('companies')
    .select('id')
    .eq('user_id', session.user.id)
    .single();
  if (!company) return;
  const { data: assignments } = await supabase
    .from('client_company_assignments')
    .select('client_id')
    .eq('company_id', company.id);
  const clientIds = assignments?.map(a => a.client_id) || [];
  if (clientIds.length === 0) return;
  const { data: clients } = await supabase
    .from('clients')
    .select('name, business_registration_number, address')
    .in('id', clientIds)
    .eq('status', 'active');
  myClientsList.value = clients || [];
  // 처방월
  validMonths.value = getValidSettlementMonths();
  // 제품
  const { data: products } = await supabase.from('products').select('*').eq('status', 'active');
  allProducts.value = products || [];
}

// 엑셀 업로드 후 미리보기 데이터에 드롭다운 값 자동 세팅
function setDropdownDefaultsForPreviewRows() {
  previewRows.value.forEach(row => {
    // 거래처
    if (!row['거래처'] && row['사업자등록번호']) {
      const client = myClientsList.value.find(c => c.business_registration_number === row['사업자등록번호']);
      if (client) row['거래처'] = client.name;
    }
    // 처방월
    if (!row['처방월'] && validMonths.value.length > 0) {
      row['처방월'] = validMonths.value[0];
    }
    // 제품명
    if (!row['제품명']) {
      const products = getProductsForMonth(row['처방월']);
      if (products.length > 0) {
        row['제품명'] = products[0].product_name;
        row['보험코드'] = products[0].insurance_code;
        row['약가'] = products[0].price;
      }
    }
    // 처방구분
    if (!row['처방구분']) {
      row['처방구분'] = 'EDI';
    }
  });
}

function getProductsForMonth(month) {
  return allProducts.value.filter(p => p.base_month === month && p.status === 'active');
}

function onPreviewPrescriptionMonthChange(row, idx) {
  const products = getProductsForMonth(row['처방월']);
  if (!products.find(p => p.product_name === row['제품명'])) {
    row['제품명'] = products.length > 0 ? products[0].product_name : '';
    row['보험코드'] = products.length > 0 ? products[0].insurance_code : '';
    row['약가'] = products.length > 0 ? products[0].price : '';
    row['수량'] = '';
    row['처방액'] = '';
  }
}

function onPreviewProductChange(row, idx) {
  const product = getProductsForMonth(row['처방월']).find(p => p.product_name === row['제품명']);
  if (product) {
    row['보험코드'] = product.insurance_code;
    row['약가'] = product.price;
    if (row['수량']) {
      row['처방액'] = Number(product.price) * Number(row['수량']);
    } else {
      row['처방액'] = '';
    }
  } else {
    row['보험코드'] = '';
    row['약가'] = '';
    row['처방액'] = '';
  }
}

function onPreviewQtyChange(row, idx) {
  let price = row['약가'] ? Number(row['약가'].toString().replace(/,/g, '')) : 0;
  let qty = row['수량'] ? Number(row['수량'].toString().replace(/,/g, '')) : 0;
  row['수량'] = qty ? qty.toLocaleString() : '';
  if (price && qty) {
    row['처방액'] = (price * qty).toLocaleString();
  } else {
    row['처방액'] = '';
  }
}

function onPreviewClientChange(row, idx) {
  const client = myClientsList.value.find(c => c.name === row['거래처']);
  if (client) {
    row['사업자등록번호'] = client.business_registration_number;
    row['주소'] = client.address;
  } else {
    row['사업자등록번호'] = '';
    row['주소'] = '';
  }
}

// 엑셀 업로드 후 드롭다운 데이터 fetch 및 previewRows 값 자동 세팅
watch(previewRows, async (rows) => {
  if (rows.length > 0) {
    await fetchDropdownData();
    setDropdownDefaultsForPreviewRows();
  }
}, { immediate: true });

// 처방월 유효 목록 함수 추가
function getValidSettlementMonths() {
  const validMonths = [];
  const currentMonth = selectedSettlementMonth.value;
  for (let i = 1; i <= 3; i++) {
    const date = new Date(currentMonth);
    date.setMonth(date.getMonth() - i);
    validMonths.push(date.toISOString().slice(0, 7));
  }
  return validMonths;
}

async function handleExcelUpload(event) {
  console.log('엑셀 업로드 시작');
  const file = event.target.files[0];
  if (!file) {
    console.log('파일 없음');
    return;
  }
  try {
    const arrayBuffer = await file.arrayBuffer();
    console.log('파일 arrayBuffer 읽기 성공');
    const workbook = XLSX.read(arrayBuffer, { type: 'array' });
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];
    const jsonData = XLSX.utils.sheet_to_json(worksheet, { header: 1 });
    console.log('엑셀 파싱 데이터:', jsonData);
    if (jsonData.length < 2) {
      alert('엑셀 파일에 데이터가 없습니다.');
      return;
    }
    // 헤더 확인
    const headers = jsonData[0];
    const dataRows = jsonData.slice(1).filter(row => row && row.length > 0 && row[0]);
    console.log('엑셀 헤더:', headers);
    console.log('엑셀 데이터 행 수:', dataRows.length);
    // 미리보기 데이터로 변환 (간단 예시)
    previewRows.value = dataRows.map(row => {
      const obj = {};
      headers.forEach((h, idx) => {
        // 엑셀 헤더가 '거래처_사업자등록번호'면 '사업자등록번호'로 변환
        if (h === '거래처_사업자등록번호') {
          obj['사업자등록번호'] = row[idx] || '';
        } else {
          obj[h] = row[idx] || '';
        }
      });
      // [추가] 사업자등록번호로 거래처명/주소 자동 세팅
      if (obj['사업자등록번호']) {
        const client = myClientsList.value.find(c => c.business_registration_number === obj['사업자등록번호']);
        if (client) {
          obj['거래처'] = client.name;
          obj['주소'] = client.address;
        }
      }
      // [추가] 거래처명만 있고 사업자등록번호가 없을 때도 보완
      if (!obj['사업자등록번호'] && obj['거래처']) {
        const client = myClientsList.value.find(c => c.name === obj['거래처']);
        if (client) {
          obj['사업자등록번호'] = client.business_registration_number;
          obj['주소'] = client.address;
        }
      }
      // [수정] 약가, 수량, 처방액 모두 천단위 콤마 및 처방액 자동 계산 (NaN 방지)
      let price = obj['약가'] ? Number(obj['약가'].toString().replace(/,/g, '')) : 0;
      let qty = obj['수량'] ? Number(obj['수량'].toString().replace(/,/g, '')) : 0;
      obj['약가'] = price ? price.toLocaleString() : '';
      obj['수량'] = qty ? qty.toLocaleString() : '';
      if (price && qty) {
        obj['처방액'] = (price * qty).toLocaleString();
      } else {
        obj['처방액'] = '';
      }
      return obj;
    });
    console.log('previewRows 반영:', previewRows.value);
  } catch (err) {
    console.error('엑셀 업로드 오류:', err);
    alert('엑셀 업로드 중 오류가 발생했습니다.');
  } finally {
    event.target.value = '';
  }
}

onMounted(async () => {
  await fetchAvailableMonths();
  await fetchDropdownData();
});
</script>
