<template>
  <div class="performance-register-view absorption-analysis">
    <div class="header-title">흡수율 분석</div>
    <div class="table-container" style="position:relative;">
      <div class="performance-header-row">
        <!-- 정산월 선택 드롭다운 -->
        <div class="info-box info-box-settlement">
          <span class="info-box-label">정산월</span>
          <select v-model="selectedSettlementMonth" class="prescription-select">
            <option value="">- 선택 -</option>
            <option v-for="month in availableMonths" :key="month.settlement_month" :value="month.settlement_month">
              {{ month.settlement_month }}
            </option>
          </select>
        </div>
        
        <!-- 처방월 표시 -->
        <div class="info-box info-box-prescription">
          <span class="info-box-label">처방월</span>
          <select v-model="prescriptionOffset" class="prescription-select" @change="onPrescriptionOffsetChange">
            <option v-for="opt in prescriptionOptions" :key="opt.value" :value="opt.value">
              {{ opt.month }}
            </option>
          </select>
        </div>
        
        <!-- 업체 선택 -->
        <div class="info-box">
          <span class="info-box-label">업체 선택</span>
          <select 
            v-model="selectedCompanyId" 
            class="prescription-select"
            style="width: 200px;"
            @change="onCompanyChange"
            @click="setActiveDropdown('company-filter')"
          >
            <option value="">- 전체 -</option>
            <option v-for="company in companies" :key="company.id" :value="company.id">
              {{ company.company_name }}
            </option>
          </select>
        </div>
        
        <!-- 거래처 선택 -->
        <div class="info-box">
          <span class="info-box-label">거래처 선택</span>
          <select 
            v-model="selectedHospitalId" 
            class="prescription-select"
            style="width: 200px;"
            @change="onHospitalChange"
            @click="setActiveDropdown('hospital-filter')"
          >
            <option value="">- 전체 -</option>
            <option v-for="hospital in hospitals" :key="hospital.id" :value="hospital.id">
              {{ hospital.name }}
            </option>
          </select>
        </div>
      </div>
      
      <div class="performance-action-row">
        <!-- 검색 영역 (왼쪽) -->
        <div class="search-section">
          <div class="search-field">
            <label>업체명</label>
            <input 
              v-model="searchFilters.companyName"
              type="text"
              placeholder="업체명 검색"
              @input="applySearchFilters"
              class="search-input"
            />
          </div>
          <div class="search-field">
            <label>거래처</label>
            <input 
              v-model="searchFilters.clientName"
              type="text"
              placeholder="거래처 검색"
              @input="applySearchFilters"
              class="search-input"
            />
          </div>
          <div class="search-field">
            <label>제품명</label>
            <input 
              v-model="searchFilters.productName"
              type="text"
              placeholder="제품명 검색"
              @input="applySearchFilters"
              class="search-input"
            />
          </div>
          <div class="search-field">
            <label>보험코드</label>
            <input 
              v-model="searchFilters.insuranceCode"
              type="text"
              placeholder="보험코드 검색"
              @input="applySearchFilters"
              class="search-input"
            />
          </div>
          <div class="search-field">
            <button 
              class="btn-search"
              @click="clearSearchFilters"
              title="검색 조건 초기화"
            >초기화</button>
          </div>
        </div>
        
        <!-- 버튼 영역 (오른쪽) -->
        <div class="action-buttons">
          <button 
            class="btn-secondary" 
            @click="loadPerformanceData" 
            :disabled="!selectedSettlementMonth"
          >실적 정보 다시 불러오기</button>
          <button 
            class="btn-secondary" 
            @click="runAbsorptionAnalysis" 
            :disabled="displayRows.length === 0"
          >흡수율 분석</button>
          <button 
            class="btn-secondary" 
            @click="downloadExcel" 
            :disabled="displayRows.length === 0"
          >엑셀 다운로드</button>
          <button 
            class="btn-primary" 
            @click="saveAnalysisData" 
            :disabled="displayRows.length === 0"
          >저장</button>
        </div>
      </div>
      
      <div class="table-scroll-wrapper">
        <table class="input-table" v-if="selectedSettlementMonth">
          <thead>
            <tr>
              <th style="width:60px;">No</th>
              <th style="width:10%;">업체명</th>
              <th style="width:14%;">거래처</th>
              <th style="width:5%;">처방월</th>
              <th style="width:12%;">제품명</th>
              <th style="width:7%;">보험코드</th>
              <th style="width:5%;">약가</th>
              <th style="width:5%;">처방수량</th>
              <th style="width:5%;">처방액</th>
              <th style="width:5%;">처방구분</th>
              <th style="width:6%;">도매매출</th>
              <th style="width:6%;">직거래매출</th>
              <th style="width:6%;">합산액</th>
              <th style="width:5%;">흡수율</th>
              <th style="width:6%;">수수료율</th>
              <th style="width:6%;">지급액</th>
              <th style="width:8%;">비고</th>
              <th style="width:100px;">삭제</th>
              <th style="width:100px;">추가</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="displayRows.length === 0">
              <td colspan="19" style="text-align:center;padding:2rem;color:#666;">
                <div v-if="!selectedSettlementMonth" style="margin-bottom:1rem;">
                  정산월을 선택하세요.
                </div>
                <div v-else style="margin-bottom:1rem;">
                  흡수율 분석 데이터가 없습니다.<br>
                  실적 정보를 불러와서 분석을 시작하세요.
                </div>
                <button 
                  v-if="selectedSettlementMonth" 
                  class="btn-primary" 
                  @click="loadPerformanceData"
                >실적 정보 다시 불러오기</button>
              </td>
            </tr>
            <tr v-for="(row, rowIdx) in displayRows" :key="row.id || rowIdx" v-else>
              <td style="text-align:center;">{{ rowIdx + 1 }}</td>
              
              <!-- 업체명 (수정 가능) -->
              <td style="text-align:left;">
                <div class="product-input-container">
                  <select 
                    v-model="row.company_name"
                    style="text-align:left; width: 100%;"
                    @change="onCompanyInput(rowIdx)"
                    @click="setActiveDropdown('company-row', rowIdx)"
                  >
                    <option value="">- 선택 -</option>
                    <option v-for="company in allCompanies" :key="company.id" :value="company.company_name">
                      {{ company.company_name }}
                    </option>
                  </select>
                </div>
              </td>
              
              <!-- 거래처 (수정 가능) -->
              <td style="text-align:left;">
                <div class="product-input-container">
                  <input 
                    v-model="row.client_name"
                    @input="handleClientNameInput(rowIdx, $event)"
                    @keydown.enter.prevent="applySelectedClientFromSearch(rowIdx)"
                    @keydown.down.prevent="navigateClientSearchList('down')"
                    @keydown.up.prevent="navigateClientSearchList('up')"
                    @focus="handleClientNameFocus(rowIdx)"
                    @blur="setTimeout(() => hideClientSearchList(rowIdx), 200)"
                    autocomplete="off"
                    style="text-align:left;"
                  />
                  <button 
                    type="button"
                    @click="toggleClientDropdown(rowIdx)"
                    @mousedown.prevent
                    class="dropdown-arrow-btn"
                    tabindex="-1"
                  >
                    <span class="dropdown-arrow">▼</span>
                  </button>
                  <div v-if="clientSearchForRow.show && clientSearchForRow.activeRowIndex === rowIdx && clientSearchForRow.results.length > 0" class="search-dropdown hospital-search-dropdown">
                    <ul>
                      <li
                        v-for="(client, index) in clientSearchForRow.results"
                        :key="client.id"
                        @click="clickClientFromSearchList(client, rowIdx)"
                        :class="{ 'selected': clientSearchForRow.selectedIndex === index }"
                      >
                        <div class="hospital-info-row">
                          <span class="hospital-name">{{ client.name }}</span>
                          <span class="hospital-reg-number">{{ client.business_registration_number }}</span>
                        </div>
                        <div class="hospital-address">{{ truncateText(client.address, 20) }}</div>
                      </li>
                    </ul>
                  </div>
                </div>
              </td>
              
              <!-- 처방월 (읽기 전용) -->
              <td style="text-align:center;">
                <input 
                  :value="row.prescription_month"
                  readonly 
                  tabindex="-1" 
                  style="text-align:center; background: transparent; border: none;"
                />
              </td>
              
              <!-- 제품명 (수정 가능) -->
              <td style="position:relative;text-align:left;">
                <div class="product-input-container">
                  <input
                    v-model="row.product_name_display"
                    @input="handleProductNameInput(rowIdx, $event)"
                    @keydown.enter.prevent="applySelectedProductFromSearch(rowIdx)"
                    @keydown.down.prevent="navigateProductSearchList('down')"
                    @keydown.up.prevent="navigateProductSearchList('up')"
                    @focus="handleProductNameFocus(rowIdx)"
                    @blur="setTimeout(() => hideProductSearchList(rowIdx), 200)" 
                    autocomplete="off"
                    style="text-align:left;"
                  />
                  <button 
                    type="button"
                    @click="toggleProductDropdown(rowIdx)"
                    @mousedown.prevent
                    class="dropdown-arrow-btn"
                    tabindex="-1"
                  >
                    <span class="dropdown-arrow">▼</span>
                  </button>
                  <div v-if="productSearchForRow.show && productSearchForRow.activeRowIndex === rowIdx && productSearchForRow.results.length > 0" class="search-dropdown product-search-dropdown">
                    <ul>
                      <li
                        v-for="(product, index) in productSearchForRow.results"
                        :key="product.id"
                        @click="clickProductFromSearchList(product, rowIdx)"
                        :class="{ 'selected': productSearchForRow.selectedIndex === index }"
                      >
                        <span class="product-name">{{ truncateText(product.product_name, 25) }}</span>
                        <span class="insurance-code">{{ product.insurance_code }}</span>
                      </li>
                    </ul>
                  </div>
                </div>
              </td>
              
              <!-- 보험코드 (읽기 전용) -->
              <td style="text-align:center;">
                <input 
                  :value="row.insurance_code"
                  readonly 
                  tabindex="-1" 
                  style="text-align:center; background: transparent; border: none;"
                />
              </td>
              
              <!-- 약가 (읽기 전용) -->
              <td style="text-align:right;">
                <input 
                  :value="row.price"
                  readonly 
                  tabindex="-1" 
                  style="text-align:right; background: transparent; border: none;"
                />
              </td>
              
              <!-- 처방수량 (수정 가능) -->
              <td style="text-align:right;">
                <input
                  v-model="row.prescription_qty"
                  type="number"
                  @input="onQtyInput(rowIdx)"
                  style="text-align:right;"
                />
              </td>
              
              <!-- 처방액 (자동 계산) -->
              <td style="text-align:right;">
                <input 
                  :value="row.prescription_amount"
                  readonly 
                  tabindex="-1" 
                  style="text-align:right; background: transparent; border: none;"
                />
              </td>
              
              <!-- 처방구분 (수정 가능) -->
              <td style="text-align:center;">
                <select
                  v-model="row.prescription_type"
                  @change="onPrescriptionTypeInput(rowIdx)"
                  @click="setActiveDropdown('prescription-type', rowIdx)"
                  style="text-align:center;"
                >
                  <option v-for="type in prescriptionTypeOptions" :key="type" :value="type">{{ type }}</option>
                </select>
              </td>
              
              <!-- 도매매출 (수정 가능) -->
              <td style="text-align:right;">
                <input 
                  v-model="row.wholesale_sales"
                  type="number"
                  @input="onSalesInput(rowIdx)"
                  style="text-align:right;"
                />
              </td>
              
              <!-- 직거래매출 (수정 가능) -->
              <td style="text-align:right;">
                <input 
                  v-model="row.direct_sales"
                  type="number"
                  @input="onSalesInput(rowIdx)"
                  style="text-align:right;"
                />
              </td>
              
              <!-- 합산액 (자동 계산) -->
              <td style="text-align:right;">
                <input 
                  :value="row.total_sales ? Number(row.total_sales).toLocaleString() : ''"
                  readonly 
                  tabindex="-1" 
                  style="text-align:right; background: transparent; border: none;"
                />
              </td>
              
              <!-- 흡수율 (자동 계산) -->
              <td style="text-align:right;">
                <input 
                  :value="row.absorption_rate ? (row.absorption_rate + '%') : ''"
                  readonly 
                  tabindex="-1" 
                  style="text-align:right; background: transparent; border: none;"
                />
              </td>
              
              <!-- 수수료율 (수정 가능) -->
              <td style="text-align:right;">
                <input 
                  v-model="row.commission_rate"
                  type="number"
                  step="0.1"
                  @input="onCommissionInput(rowIdx)"
                  style="text-align:right;"
                />
              </td>
              
              <!-- 지급액 (자동 계산) -->
              <td style="text-align:right;">
                <input 
                  :value="row.payment_amount ? Number(row.payment_amount).toLocaleString() : ''"
                  readonly 
                  tabindex="-1" 
                  style="text-align:right; background: transparent; border: none;"
                />
              </td>
              
              <!-- 비고 (수정 가능) -->
              <td style="text-align:left;">
                <input 
                  v-model="row.remarks"
                  style="text-align:left;"
                />
              </td>
              
              <!-- 삭제 -->
              <td class="action-cell">
                <button 
                  class="btn-delete-m"
                  @click="confirmDeleteRow(rowIdx)" 
                  :disabled="displayRows.length === 1" 
                  title="행 삭제"
                >－</button>
              </td>
              
              <!-- 추가 -->
              <td class="action-cell">
                <button 
                  class="btn-add-m"
                  @click="confirmAddRowBelow(rowIdx)" 
                  title="아래에 행 추가"
                >＋</button>
              </td>
            </tr>
          </tbody>
          
          <!-- 합계 행을 같은 테이블 내 tfoot으로 이동 -->
          <tfoot v-if="displayRows.length > 0">
            <tr style="position: sticky; bottom: 0; background: #f8f9fa; border-top: 2px solid #007bff;">
              <td style="width:60px;"></td>
              <td style="width:10%;"></td>
              <td style="width:14%;"></td>
              <td style="width:5%;"></td>
              <td style="width:12%;"></td>
              <td style="width:7%;"></td>
              <td style="width:5%;"></td>
              <td style="width:5%; text-align:center; font-weight: bold;">합계</td>
              <td style="width:5%; text-align:right; font-weight: bold;">{{ totalPrescriptionAmount }}</td>
              <td style="width:5%;"></td>
              <td style="width:6%; text-align:right; font-weight: bold;">{{ totalWholesaleSales }}</td>
              <td style="width:6%; text-align:right; font-weight: bold;">{{ totalDirectSales }}</td>
              <td style="width:6%; text-align:right; font-weight: bold;">{{ totalSales }}</td>
              <td style="width:5%;"></td>
              <td style="width:6%;"></td>
              <td style="width:6%; text-align:right; font-weight: bold;">{{ totalPaymentAmount }}</td>
              <td style="width:8%;"></td>
              <td style="width:100px;"></td>
              <td style="width:100px;"></td>
            </tr>
          </tfoot>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, onUnmounted } from 'vue';
import { supabase } from '@/supabase';
import * as XLSX from 'xlsx';

// 반응형 데이터
const availableMonths = ref([]);
const selectedSettlementMonth = ref('');
const prescriptionMonth = ref('');
const prescriptionOffset = ref(0);
const prescriptionOptions = ref([]);

// 업체/거래처 관련
const selectedCompanyId = ref('');
const selectedHospitalId = ref('');
const companies = ref([]);
const hospitals = ref([]);
const allHospitals = ref([]); // 전체 거래처 목록

// 분석 데이터
const displayRows = ref([]);
const allDisplayRows = ref([]); // 원본 데이터 (검색 필터링 전)

// 전체 업체/거래처/제품 목록
const allCompanies = ref([]);
const allClients = ref([]);
const allProducts = ref([]);

// 처방구분 옵션
const prescriptionTypeOptions = ref(['EDI', '직거래']);

// 드롭다운 관리 상태
const activeDropdown = ref(''); // 현재 활성화된 드롭다운 타입
const activeDropdownRowIndex = ref(-1); // 행별 드롭다운의 경우 해당 행 인덱스

// 검색 드롭다운 관련
const clientSearchForRow = ref({
  show: false,
  activeRowIndex: -1,
  results: [],
  selectedIndex: -1
});

const productSearchForRow = ref({
  show: false,
  activeRowIndex: -1,
  results: [],
  selectedIndex: -1
});

// 검색 필터
const searchFilters = ref({
  companyName: '',
  clientName: '',
  productName: '',
  insuranceCode: ''
});

// 처방월 옵션 업데이트
function updatePrescriptionOptions() {
  if (!selectedSettlementMonth.value) {
    prescriptionOptions.value = [];
    return;
  }
  
  prescriptionOptions.value = [
    { value: 0, month: '- 전체 -' },
    ...([1, 2, 3].map(offset => ({
      value: offset,
      month: getPrescriptionMonth(selectedSettlementMonth.value, offset)
    })))
  ];
}

function getPrescriptionMonth(settlementMonth, offset) {
  if (!settlementMonth) return '';
  const [y, m] = settlementMonth.split('-');
  let mm = parseInt(m, 10) - offset;
  let yy = parseInt(y, 10);
  while (mm <= 0) { mm += 12; yy -= 1; }
  return `${yy}-${String(mm).padStart(2, '0')}`;
}

// 워치어
watch(selectedSettlementMonth, () => {
  updatePrescriptionOptions();
  prescriptionOffset.value = 0;
  prescriptionMonth.value = '';
  selectedCompanyId.value = '';
  selectedHospitalId.value = '';
  companies.value = [];
  hospitals.value = [];
  
  // 정산월 선택 시 흡수율 분석 데이터 자동 조회
  if (selectedSettlementMonth.value) {
    loadAbsorptionAnalysisData();
  } else {
    displayRows.value = [];
  }
});

watch(prescriptionOffset, (val) => {
  if (val === 0) {
    prescriptionMonth.value = '';
  } else {
    prescriptionMonth.value = getPrescriptionMonth(selectedSettlementMonth.value, val);
  }
  filterData();
});

watch(selectedCompanyId, () => {
  filterData();
});

watch(selectedHospitalId, () => {
  filterData();
});

// 정산월 선택 시 흡수율 분석 데이터 조회
async function loadAbsorptionAnalysisData() {
  if (!selectedSettlementMonth.value) {
    displayRows.value = [];
    return;
  }

  try {
    // absorption_analysis 테이블에서 데이터 조회
    const { data, error } = await supabase
      .from('absorption_analysis')
      .select('*')
      .eq('settlement_month', selectedSettlementMonth.value)
      .order('created_at', { ascending: true });

    if (error) {
      console.error('흡수율 분석 데이터 조회 오류:', error);
      displayRows.value = [];
      return;
    }

    if (!data || data.length === 0) {
      console.log('흡수율 분석 데이터 없음');
      displayRows.value = [];
      return;
    }

    // 화면 표시용 데이터 변환
    const transformedData = data.map(record => ({
      id: record.id,
      original_id: record.id,
      company_name: record.company_name,
      client_name: record.client_name,
      prescription_month: record.prescription_month,
      product_name: record.product_name,
      product_name_display: record.product_name,
      insurance_code: record.insurance_code,
      price: record.price ? Number(record.price).toLocaleString() : '',
      prescription_qty: record.prescription_qty,
      prescription_amount: record.prescription_amount ? Number(record.prescription_amount).toLocaleString() : '',
      prescription_type: record.prescription_type,
      wholesale_sales: record.wholesale_sales,
      direct_sales: record.direct_sales,
      total_sales: record.total_sales,
      absorption_rate: record.absorption_rate,
      commission_rate: record.commission_rate,
      payment_amount: record.payment_amount,
      remarks: record.remarks || ''
    }));

    displayRows.value = transformedData;
    
    // 업체와 거래처 목록 생성
    generateFilterOptions();
    
    console.log(`${transformedData.length}건의 흡수율 분석 데이터를 불러왔습니다.`);

  } catch (err) {
    console.error('흡수율 분석 데이터 조회 예외:', err);
    displayRows.value = [];
  }
}

// 실적 정보 불러오기 (performance_records에서)
async function loadPerformanceData() {
  if (!selectedSettlementMonth.value) {
    alert('정산월을 선택하세요.');
    return;
  }

  try {
    // performance_records에서 데이터 조회
    let query = supabase
      .from('performance_records')
      .select(`
        *,
        products!inner(product_name, insurance_code, price),
        clients!inner(name),
        companies!inner(company_name)
      `)
      .eq('settlement_month', selectedSettlementMonth.value);

    const { data, error } = await query.order('created_at', { ascending: true });

    if (error) {
      console.error('실적 데이터 조회 오류:', error);
      alert('실적 데이터 조회 중 오류가 발생했습니다.');
      return;
    }

    if (!data || data.length === 0) {
      alert('해당 정산월의 실적 데이터가 없습니다.');
      return;
    }

    // 분석용 데이터로 변환 및 수수료율/지급액 자동 계산
    const analysisData = [];
    
    for (const record of data) {
      const row = {
        id: `temp_${Date.now()}_${Math.random()}`,
        original_id: record.id,
        company_name: record.companies.company_name,
        client_name: record.clients.name,
        prescription_month: record.prescription_month,
        product_name: record.products.product_name,
        product_name_display: record.products.product_name,
        insurance_code: record.products.insurance_code,
        price: record.products.price ? Number(record.products.price).toLocaleString() : '',
        prescription_qty: record.prescription_qty,
        prescription_amount: (record.prescription_qty * record.products.price).toLocaleString(),
        prescription_type: record.prescription_type,
        wholesale_sales: 0,
        direct_sales: 0,
        total_sales: 0,
        absorption_rate: 0,
        commission_rate: 0,
        payment_amount: 0,
        remarks: record.remarks || ''
      };

      // 수수료율 자동 계산
      try {
        // 업체 정보 조회
        const { data: company } = await supabase
          .from('companies')
          .select('commission_grade')
          .eq('company_name', record.companies.company_name.trim())
          .single();

        // 제품 정보 조회
        const { data: product } = await supabase
          .from('products')
          .select('commission_rate_A, commission_rate_B, commission_rate_C')
          .eq('product_name', record.products.product_name.trim())
          .single();

        if (company && product) {
          const commissionField = `commission_rate_${company.commission_grade}`;
          const commissionRate = product[commissionField];
          
          if (commissionRate !== null && commissionRate !== undefined) {
            // 소수점을 퍼센트로 변환 (0.4 -> 40)
            const percentageRate = Number(commissionRate) * 100;
            row.commission_rate = percentageRate;
            
            // 지급액 계산 (처방액 × 수수료율)
            const prescriptionAmount = record.prescription_qty * record.products.price;
            row.payment_amount = Math.round(prescriptionAmount * commissionRate);
            
            console.log(`수수료율 자동 계산: ${record.products.product_name} - ${percentageRate}% - 지급액: ${row.payment_amount}`);
          }
        }
      } catch (err) {
        console.error(`수수료율 계산 오류 (${record.products.product_name}):`, err);
      }

      analysisData.push(row);
    }

    displayRows.value = analysisData;
    
    // 업체와 거래처 목록 생성
    generateFilterOptions();
    
    alert(`${analysisData.length}건의 실적 데이터를 불러왔습니다. (수수료율 자동 계산 완료)`);

  } catch (err) {
    console.error('실적 데이터 불러오기 예외:', err);
    alert('실적 데이터 불러오기 중 오류가 발생했습니다.');
  }
}

// 필터 옵션 생성
function generateFilterOptions() {
  const uniqueCompanies = [...new Set(displayRows.value.map(row => row.company_name))];
  const uniqueClients = [...new Set(displayRows.value.map(row => row.client_name))];
  
  companies.value = uniqueCompanies.map(name => ({ id: name, company_name: name }));
  hospitals.value = uniqueClients.map(name => ({ id: name, name: name }));
}

// 데이터 필터링
function filterData() {
  // 실제 구현시 필요
}

// 이벤트 핸들러
function onPrescriptionOffsetChange() {
  // watch에서 처리
}

async function onCompanyChange() {
  // 드롭다운 닫기
  closeAllDropdowns();
  
  // 업체별 거래처 필터링 및 거래처 초기화
  await handleCompanyChangeAndResetClient(selectedCompanyId.value);
  
  // 데이터 필터링
  filterData();
}

function onHospitalChange() {
  // 드롭다운 닫기
  closeAllDropdowns();
  
  // 데이터 필터링
  filterData();
}

// 실시간 계산 함수들
async function onCompanyInput(rowIndex) {
  // 드롭다운 닫기
  closeAllDropdowns();
  
  // 업체 선택시 수수료율 자동 조회
  updateCommissionRate(rowIndex);
  
  // 행별 거래처 초기화 (해당 업체에 할당된 거래처가 아니라면)
  const row = displayRows.value[rowIndex];
  const selectedCompany = allCompanies.value.find(c => c.company_name === row.company_name);
  
  if (selectedCompany && row.client_name) {
    // 현재 거래처가 새 업체에도 할당되어 있는지 확인
    try {
      const { data: assignments, error } = await supabase
        .from('client_company_assignments')
        .select('client_id')
        .eq('company_id', selectedCompany.id);
        
      if (!error && assignments) {
        const assignedClientIds = assignments.map(a => a.client_id);
        const currentClient = allHospitals.value.find(h => h.name === row.client_name);
        
        // 현재 거래처가 새 업체에 할당되지 않았으면 초기화
        if (!currentClient || !assignedClientIds.includes(currentClient.id)) {
          row.client_name = '';
        }
      }
    } catch (err) {
      console.error('거래처 할당 확인 오류:', err);
    }
  }
}

function onQtyInput(rowIndex) {
  recalculateRow(rowIndex);
}

function onPrescriptionTypeInput(rowIndex) {
  // 드롭다운 닫기
  closeAllDropdowns();
  
  // 처방구분 변경시 처리
}

function onSalesInput(rowIndex) {
  recalculateRow(rowIndex);
}

function onCommissionInput(rowIndex) {
  recalculateRow(rowIndex);
}

// 수수료율 자동 조회 함수
async function updateCommissionRate(rowIndex) {
  const row = displayRows.value[rowIndex];
  
  console.log('updateCommissionRate 시작:', { rowIndex, company_name: row.company_name, product_name: row.product_name });
  
  if (!row.company_name || !row.product_name) {
    console.log('업체명 또는 제품명이 없음');
    return;
  }
  
  try {
    // 업체 정보 조회 (정확한 매칭을 위해 trim 적용)
    console.log('업체 정보 조회 중:', row.company_name);
    const { data: company, error: companyError } = await supabase
      .from('companies')
      .select('commission_grade, company_name')
      .eq('company_name', row.company_name.trim())
      .single();
      
    if (companyError || !company) {
      console.error('업체 정보 조회 오류:', companyError);
      console.log('조회한 업체명:', row.company_name);
      
      // 전체 업체 목록 조회해서 비교
      const { data: allCompanies } = await supabase
        .from('companies')
        .select('company_name, commission_grade');
      console.log('전체 업체 목록:', allCompanies);
      return;
    }
    
    console.log('업체 정보 조회 성공:', company);
    
    // 제품 정보 조회 (정확한 매칭을 위해 trim 적용)
    console.log('제품 정보 조회 중:', row.product_name);
    const { data: product, error: productError } = await supabase
      .from('products')
      .select('*')
      .eq('product_name', row.product_name.trim())
      .single();
      
    if (productError || !product) {
      console.error('제품 정보 조회 오류:', productError);
      console.log('조회한 제품명:', row.product_name);
      
      // 전체 제품 목록 조회해서 비교
      const { data: allProducts } = await supabase
        .from('products')
        .select('product_name, commission_rate_A, commission_rate_B, commission_rate_C')
        .ilike('product_name', `%${row.product_name.trim()}%`);
      console.log('유사한 제품 목록:', allProducts);
      return;
    }
    
    console.log('제품 정보 조회 성공:', product);
    
    // 수수료율 조회 (commission_grade에 따른 제품별 수수료율)
    const commissionField = `commission_rate_${company.commission_grade}`;
    const commissionRate = product[commissionField];
    
    console.log('수수료율 조회:', { 
      commission_grade: company.commission_grade, 
      commissionField, 
      commissionRate,
      allCommissionFields: {
        commission_rate_A: product.commission_rate_A,
        commission_rate_B: product.commission_rate_B,
        commission_rate_C: product.commission_rate_C
      }
    });
    
    if (commissionRate !== null && commissionRate !== undefined) {
      // 소수점을 퍼센트로 변환 (0.4 -> 40)
      const percentageRate = Number(commissionRate) * 100;
      row.commission_rate = percentageRate;
      console.log('수수료율 설정 완료:', { 
        원본값: commissionRate, 
        퍼센트값: percentageRate,
        최종설정값: row.commission_rate 
      });
      recalculateRow(rowIndex);
    } else {
      console.log('수수료율이 null/undefined');
      console.log('해당 제품의 모든 수수료율 필드:', {
        commission_rate_A: product.commission_rate_A,
        commission_rate_B: product.commission_rate_B,
        commission_rate_C: product.commission_rate_C
      });
    }
    
  } catch (err) {
    console.error('수수료율 조회 예외:', err);
  }
}

function recalculateRow(rowIndex) {
  const row = displayRows.value[rowIndex];
  
  // 처방액 재계산
  const priceNum = Number(row.price.toString().replace(/,/g, '')) || 0;
  const qty = Number(row.prescription_qty) || 0;
  const prescriptionAmount = qty * priceNum;
  row.prescription_amount = prescriptionAmount.toLocaleString();
  
  // 합산액 계산
  const wholesale = Number(row.wholesale_sales) || 0;
  const direct = Number(row.direct_sales) || 0;
  row.total_sales = wholesale + direct;
  
  // 흡수율 계산
  if (prescriptionAmount > 0) {
    row.absorption_rate = Math.round((row.total_sales / prescriptionAmount) * 100 * 100) / 100;
  } else {
    row.absorption_rate = 0;
  }
  
  // 지급액 계산 (처방액 x 수수료율)
  const commissionRate = Number(row.commission_rate) || 0;
  row.payment_amount = Math.round(prescriptionAmount * commissionRate / 100);
}

// 거래처 검색 관련 함수들
function handleClientNameInput(rowIndex, event) {
  // 드롭다운 관리 확인
  if (!setActiveDropdown('client', rowIndex)) return;
  
  const query = event.target.value;
  
  clientSearchForRow.value.activeRowIndex = rowIndex;
  clientSearchForRow.value.selectedIndex = -1;
  
  if (query.trim() === '') {
    clientSearchForRow.value.show = false;
    clientSearchForRow.value.results = [];
    return;
  }
  
  searchClients(query);
}

function handleClientNameFocus(rowIndex) {
  // 드롭다운 관리 확인
  if (!setActiveDropdown('client', rowIndex)) return;
  
  clientSearchForRow.value.activeRowIndex = rowIndex;
  const currentValue = displayRows.value[rowIndex].client_name;
  
  if (currentValue && currentValue.trim() !== '') {
    searchClients(currentValue);
  } else {
    showAllClients();
  }
}

async function searchClients(query) {
  try {
    // hospitals 배열에서 검색 (업체별로 이미 필터링된 상태)
    let results = hospitals.value;
    
    if (query && query.trim() !== '') {
      results = hospitals.value.filter(client =>
        (client.name && client.name.toLowerCase().includes(query.trim().toLowerCase())) ||
        (client.business_registration_number && client.business_registration_number.includes(query.trim()))
      );
    }

    clientSearchForRow.value.results = results || [];
    clientSearchForRow.value.show = true;
  } catch (err) {
    console.error('거래처 검색 예외:', err);
  }
}

async function showAllClients() {
  try {
    // hospitals 배열 사용 (업체별로 이미 필터링된 상태)
    clientSearchForRow.value.results = hospitals.value || [];
    clientSearchForRow.value.show = true;
  } catch (err) {
    console.error('거래처 목록 조회 예외:', err);
  }
}

function toggleClientDropdown(rowIndex) {
  if (setActiveDropdown('client', rowIndex)) {
    clientSearchForRow.value.activeRowIndex = rowIndex;
    showAllClients();
  }
}

function clickClientFromSearchList(client, rowIndex) {
  displayRows.value[rowIndex].client_name = client.name;
  closeAllDropdowns();
}

function hideClientSearchList(rowIndex) {
  if (clientSearchForRow.value.activeRowIndex === rowIndex) {
    clientSearchForRow.value.show = false;
    clientSearchForRow.value.results = [];
  }
}

function navigateClientSearchList(direction) {
  if (!clientSearchForRow.value.show || clientSearchForRow.value.results.length === 0) return;
  
  if (direction === 'down') {
    clientSearchForRow.value.selectedIndex = 
      clientSearchForRow.value.selectedIndex < clientSearchForRow.value.results.length - 1 
        ? clientSearchForRow.value.selectedIndex + 1 
        : 0;
  } else if (direction === 'up') {
    clientSearchForRow.value.selectedIndex = 
      clientSearchForRow.value.selectedIndex > 0 
        ? clientSearchForRow.value.selectedIndex - 1 
        : clientSearchForRow.value.results.length - 1;
  }
}

function applySelectedClientFromSearch(rowIndex) {
  if (clientSearchForRow.value.selectedIndex >= 0 && clientSearchForRow.value.results.length > 0) {
    const selectedClient = clientSearchForRow.value.results[clientSearchForRow.value.selectedIndex];
    clickClientFromSearchList(selectedClient, rowIndex);
  }
}

// 제품 검색 관련 함수들
function handleProductNameInput(rowIndex, event) {
  // 드롭다운 관리 확인
  if (!setActiveDropdown('product', rowIndex)) return;
  
  const query = event.target.value;
  
  productSearchForRow.value.activeRowIndex = rowIndex;
  productSearchForRow.value.selectedIndex = -1;
  
  if (query.trim() === '') {
    productSearchForRow.value.show = false;
    productSearchForRow.value.results = [];
    return;
  }
  
  searchProducts(query);
}

function handleProductNameFocus(rowIndex) {
  // 드롭다운 관리 확인
  if (!setActiveDropdown('product', rowIndex)) return;
  
  productSearchForRow.value.activeRowIndex = rowIndex;
  const currentValue = displayRows.value[rowIndex].product_name_display;
  
  if (currentValue && currentValue.trim() !== '') {
    searchProducts(currentValue);
  } else {
    showAllProducts();
  }
}

async function searchProducts(query) {
  try {
    let searchQuery = supabase
      .from('products')
      .select('*')
      .order('product_name');

    if (query && query.trim() !== '') {
      searchQuery = searchQuery.or(`product_name.ilike.%${query.trim()}%,insurance_code.ilike.%${query.trim()}%`);
    }

    const { data, error } = await searchQuery.limit(20);

    if (error) {
      console.error('제품 검색 오류:', error);
      return;
    }

    productSearchForRow.value.results = data || [];
    productSearchForRow.value.show = true;
  } catch (err) {
    console.error('제품 검색 예외:', err);
  }
}

async function showAllProducts() {
  try {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .order('product_name')
      .limit(50);

    if (error) {
      console.error('제품 목록 조회 오류:', error);
      return;
    }

    productSearchForRow.value.results = data || [];
    productSearchForRow.value.show = true;
  } catch (err) {
    console.error('제품 목록 조회 예외:', err);
  }
}

function toggleProductDropdown(rowIndex) {
  if (setActiveDropdown('product', rowIndex)) {
    productSearchForRow.value.activeRowIndex = rowIndex;
    showAllProducts();
  }
}

function clickProductFromSearchList(product, rowIndex) {
  const row = displayRows.value[rowIndex];
  row.product_name = product.product_name;
  row.product_name_display = product.product_name;
  row.insurance_code = product.insurance_code;
  row.price = Number(product.price).toLocaleString();
  
  closeAllDropdowns();
  
  // 제품이 변경되면 처방액 재계산
  recalculateRow(rowIndex);
  
  // 업체와 제품이 모두 선택되었으면 수수료율 조회
  if (row.company_name) {
    updateCommissionRate(rowIndex);
  }
}

function hideProductSearchList(rowIndex) {
  if (productSearchForRow.value.activeRowIndex === rowIndex) {
    productSearchForRow.value.show = false;
    productSearchForRow.value.activeRowIndex = -1;
  }
}

function navigateProductSearchList(direction) {
  if (!productSearchForRow.value.show || productSearchForRow.value.results.length === 0) return;
  
  if (direction === 'down') {
    productSearchForRow.value.selectedIndex = 
      productSearchForRow.value.selectedIndex < productSearchForRow.value.results.length - 1 
        ? productSearchForRow.value.selectedIndex + 1 
        : 0;
  } else if (direction === 'up') {
    productSearchForRow.value.selectedIndex = 
      productSearchForRow.value.selectedIndex > 0 
        ? productSearchForRow.value.selectedIndex - 1 
        : productSearchForRow.value.results.length - 1;
  }
}

function applySelectedProductFromSearch(rowIndex) {
  if (productSearchForRow.value.selectedIndex >= 0 && productSearchForRow.value.results.length > 0) {
    const selectedProduct = productSearchForRow.value.results[productSearchForRow.value.selectedIndex];
    clickProductFromSearchList(selectedProduct, rowIndex);
  }
}

// 유틸리티 함수
function truncateText(text, maxLength) {
  if (!text) return '';
  return text.length > maxLength ? text.substring(0, maxLength) + '...' : text;
}

// 행 삭제/추가 함수들
function confirmDeleteRow(rowIndex) {
  if (displayRows.value.length === 1) {
    alert('최소 1개 행은 유지되어야 합니다.');
    return;
  }
  
  if (confirm('이 행을 삭제하시겠습니까?')) {
    displayRows.value.splice(rowIndex, 1);
  }
}

function confirmAddRowBelow(rowIndex) {
  const newRow = {
    id: `new_${Date.now()}_${Math.random()}`,
    original_id: null,
    company_name: '',
    client_name: '',
    prescription_month: selectedSettlementMonth.value,
    product_name: '',
    product_name_display: '',
    insurance_code: '',
    price: '',
    prescription_qty: 0,
    prescription_amount: '',
    prescription_type: 'EDI',
    wholesale_sales: 0,
    direct_sales: 0,
    total_sales: 0,
    absorption_rate: 0,
    commission_rate: 0,
    payment_amount: 0,
    remarks: ''
  };
  
  displayRows.value.splice(rowIndex + 1, 0, newRow);
}

// 합계 계산
const totalPrescriptionAmount = computed(() => {
  const total = displayRows.value.reduce((sum, row) => sum + (Number(row.prescription_amount.toString().replace(/,/g, '')) || 0), 0);
  return total.toLocaleString();
});

const totalWholesaleSales = computed(() => {
  const total = displayRows.value.reduce((sum, row) => sum + (Number(row.wholesale_sales) || 0), 0);
  return total.toLocaleString();
});

const totalDirectSales = computed(() => {
  const total = displayRows.value.reduce((sum, row) => sum + (Number(row.direct_sales) || 0), 0);
  return total.toLocaleString();
});

const totalSales = computed(() => {
  const total = displayRows.value.reduce((sum, row) => sum + (Number(row.total_sales) || 0), 0);
  return total.toLocaleString();
});

const totalPaymentAmount = computed(() => {
  const total = displayRows.value.reduce((sum, row) => sum + (Number(row.payment_amount) || 0), 0);
  return total.toLocaleString();
});

// 엑셀 다운로드
function downloadExcel() {
  if (displayRows.value.length === 0) {
    alert('다운로드할 데이터가 없습니다.');
    return;
  }

  const excelData = displayRows.value.map((row, index) => ({
    'No': index + 1,
    '업체명': row.company_name || '',
    '거래처': row.client_name || '',
    '처방월': row.prescription_month || '',
    '제품명': row.product_name || '',
    '보험코드': row.insurance_code || '',
    '약가': Number(row.price?.toString().replace(/,/g, '')) || 0,
    '처방수량': Number(row.prescription_qty) || 0,
    '처방액': Number(row.prescription_amount?.toString().replace(/,/g, '')) || 0,
    '처방구분': row.prescription_type || '',
    '도매매출': Number(row.wholesale_sales) || 0,
    '직거래매출': Number(row.direct_sales) || 0,
    '합산액': Number(row.total_sales) || 0,
    '흡수율': row.absorption_rate || 0,
    '지급수수료율': row.commission_rate || 0,
    '지급액': Number(row.payment_amount) || 0,
    '비고': row.remarks || ''
  }));

  const ws = XLSX.utils.json_to_sheet(excelData);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '흡수율분석');

  const fileName = `흡수율분석_${selectedSettlementMonth.value}_${new Date().toISOString().split('T')[0]}.xlsx`;
  XLSX.writeFile(wb, fileName);
}

// 저장 기능
async function saveAnalysisData() {
  console.log('저장 함수 시작');
  
  if (displayRows.value.length === 0) {
    alert('저장할 데이터가 없습니다.');
    return;
  }
  
  // 유효한 데이터만 필터링 (업체명, 거래처, 제품명이 모두 있는 행)
  const validRows = displayRows.value.filter(row => 
    row.company_name && row.client_name && row.product_name
  );
  
  console.log('유효한 행 개수:', validRows.length);
  console.log('유효한 행 데이터:', validRows);
  
  if (validRows.length === 0) {
    alert('저장할 유효한 데이터가 없습니다. 업체명, 거래처, 제품명을 모두 입력해주세요.');
    return;
  }
  
  try {
    console.log('기존 데이터 삭제 시작 - settlement_month:', selectedSettlementMonth.value);
    
    // 기존 데이터 삭제 (현재 정산월)
    const { error: deleteError } = await supabase
      .from('absorption_analysis')
      .delete()
      .eq('settlement_month', selectedSettlementMonth.value);
      
    if (deleteError) {
      console.error('기존 데이터 삭제 오류:', deleteError);
      throw new Error('기존 데이터 삭제 실패: ' + deleteError.message);
    }
    
    console.log('기존 데이터 삭제 완료');
    
    // 새 데이터 저장
    const saveData = validRows.map(row => {
      const data = {
        settlement_month: selectedSettlementMonth.value,
        prescription_month: row.prescription_month,
        company_name: row.company_name,
        client_name: row.client_name,
        product_name: row.product_name,
        insurance_code: row.insurance_code,
        price: Number(row.price.toString().replace(/,/g, '')) || 0,
        prescription_qty: Number(row.prescription_qty) || 0,
        prescription_amount: Number(row.prescription_amount.toString().replace(/,/g, '')) || 0,
        prescription_type: row.prescription_type,
        wholesale_sales: Number(row.wholesale_sales) || 0,
        direct_sales: Number(row.direct_sales) || 0,
        total_sales: Number(row.total_sales) || 0,
        absorption_rate: Number(row.absorption_rate) || 0,
        commission_rate: Number(row.commission_rate) || 0,
        payment_amount: Number(row.payment_amount) || 0,
        remarks: row.remarks || ''
      };
      
      console.log('저장할 행 데이터:', data);
      return data;
    });
    
    console.log('전체 저장 데이터:', saveData);
    console.log('저장 시작...');
    
    const { data: insertResult, error: insertError } = await supabase
      .from('absorption_analysis')
      .insert(saveData);
      
    if (insertError) {
      console.error('데이터 저장 오류:', insertError);
      console.error('오류 코드:', insertError.code);
      console.error('오류 메시지:', insertError.message);
      console.error('오류 세부사항:', insertError.details);
      throw new Error('데이터 저장 실패: ' + insertError.message);
    }
    
    console.log('저장 완료. 결과:', insertResult);
    alert(`${validRows.length}건의 흡수율 분석 데이터가 저장되었습니다.`);
    
  } catch (err) {
    console.error('저장 예외:', err);
    alert('저장 중 오류가 발생했습니다: ' + err.message);
  }
}

// 라이프사이클
onMounted(async () => {
  await fetchAvailableMonths();
  await loadAllCompanies();
  await loadAllHospitals();
  
  // 전역 클릭 이벤트 리스너 추가
  document.addEventListener('click', handleGlobalClick);
  
  // 정산월은 사용자가 직접 선택하도록 빈 값으로 시작
  selectedSettlementMonth.value = '';
});

// 컴포넌트 언마운트 시 이벤트 리스너 제거
onUnmounted(() => {
  document.removeEventListener('click', handleGlobalClick);
});

// 전역 클릭 이벤트 핸들러
function handleGlobalClick(event) {
  // 드롭다운 관련 요소들
  const isDropdownElement = event.target.closest('.product-input-container') ||
                           event.target.closest('.search-dropdown') ||
                           event.target.closest('select') ||
                           event.target.closest('.dropdown-arrow-btn');
  
  if (!isDropdownElement) {
    closeAllDropdowns();
  }
}

async function fetchAvailableMonths() {
  try {
    const { data, error } = await supabase
      .from('settlement_months')
      .select('*')
      .eq('status', 'active')
      .order('settlement_month', { ascending: false });
      
    if (error) {
      console.error('정산월 조회 오류:', error);
      return;
    }
    
    availableMonths.value = data || [];
  } catch (err) {
    console.error('정산월 조회 예외:', err);
  }
}

async function loadAllCompanies() {
  try {
    const { data, error } = await supabase
      .from('companies')
      .select('*')
      .order('company_name');
      
    if (error) {
      console.error('업체 목록 조회 오류:', error);
      return;
    }
    
    allCompanies.value = data || [];
  } catch (err) {
    console.error('업체 목록 조회 예외:', err);
  }
}

async function loadAllHospitals() {
  try {
    const { data, error } = await supabase
      .from('clients')
      .select('*')
      .eq('status', 'active')
      .order('name');
      
    if (error) {
      console.error('전체 거래처 목록 조회 오류:', error);
      return;
    }
    
    allHospitals.value = data || [];
    hospitals.value = [...allHospitals.value]; // 초기에는 모든 거래처 표시
  } catch (err) {
    console.error('전체 거래처 목록 조회 예외:', err);
  }
}

// 편집 중 실시간 재계산
function recalculateEditRow(row) {
  // 처방액 재계산
  const priceNum = Number(row.price.toString().replace(/,/g, '')) || 0;
  const qty = Number(row.edit_prescription_qty) || 0;
  const prescriptionAmount = qty * priceNum;
  row.prescription_amount = prescriptionAmount.toLocaleString();
  
  // 합산액 계산
  const wholesale = Number(row.edit_wholesale_sales) || 0;
  const direct = Number(row.edit_direct_sales) || 0;
  row.total_sales = wholesale + direct;
  
  // 흡수율 계산
  if (prescriptionAmount > 0) {
    row.absorption_rate = Math.round((row.total_sales / prescriptionAmount) * 100 * 100) / 100;
  } else {
    row.absorption_rate = 0;
  }
  
  // 지급액 계산 (처방액 x 수수료율)
  const commissionRate = Number(row.edit_commission_rate) || 0;
  row.payment_amount = Math.round(prescriptionAmount * commissionRate / 100);
}

// 드롭다운 관리 함수들
function closeAllDropdowns() {
  activeDropdown.value = '';
  activeDropdownRowIndex.value = -1;
  clientSearchForRow.value.show = false;
  clientSearchForRow.value.activeRowIndex = -1;
  productSearchForRow.value.show = false;
  productSearchForRow.value.activeRowIndex = -1;
}

function setActiveDropdown(type, rowIndex = -1) {
  if (activeDropdown.value === type && activeDropdownRowIndex.value === rowIndex) {
    closeAllDropdowns();
    return false;
  }
  
  closeAllDropdowns();
  activeDropdown.value = type;
  activeDropdownRowIndex.value = rowIndex;
  return true;
}

// 업체별 거래처 필터링
async function filterHospitalsByCompany(companyId = '') {
  try {
    if (!companyId) {
      // 업체가 선택되지 않으면 모든 거래처 표시
      hospitals.value = [...allHospitals.value];
      return;
    }
    
    // 해당 업체에 할당된 거래처만 조회
    const { data: assignments, error } = await supabase
      .from('client_company_assignments')
      .select('client_id')
      .eq('company_id', companyId);
      
    if (error) {
      console.error('업체별 거래처 조회 오류:', error);
      hospitals.value = [];
      return;
    }
    
    if (!assignments || assignments.length === 0) {
      hospitals.value = [];
      return;
    }
    
    const clientIds = assignments.map(a => a.client_id);
    hospitals.value = allHospitals.value.filter(hospital => clientIds.includes(hospital.id));
    
  } catch (err) {
    console.error('업체별 거래처 필터링 예외:', err);
    hospitals.value = [];
  }
}

// 업체 변경 시 거래처 초기화 로직
async function handleCompanyChangeAndResetClient(newCompanyId) {
  const currentClientId = selectedHospitalId.value;
  const currentClientName = hospitals.value.find(h => h.id === currentClientId)?.name || '';
  
  // 새 업체의 거래처 목록 로드
  await filterHospitalsByCompany(newCompanyId);
  
  // 현재 선택된 거래처가 새 업체에도 할당되어 있는지 확인
  const isClientStillAvailable = hospitals.value.some(h => h.id === currentClientId);
  
  if (!isClientStillAvailable) {
    // 거래처가 새 업체에 할당되지 않았으면 초기화
    selectedHospitalId.value = '';
  }
}

// 흡수율 분석 실행 (추후 로직 구현 예정)
function runAbsorptionAnalysis() {
  if (displayRows.value.length === 0) {
    alert('분석할 데이터가 없습니다. 먼저 실적 정보를 불러오세요.');
    return;
  }
  
  // TODO: 흡수율 분석 로직 구현 예정
  alert('흡수율 분석 로직은 추후 구현 예정입니다.');
}

// 검색 필터링 함수
function applySearchFilters() {
  if (!allDisplayRows.value || allDisplayRows.value.length === 0) {
    displayRows.value = [];
    return;
  }

  let filtered = [...allDisplayRows.value];

  // 업체명 필터
  if (searchFilters.value.companyName.trim()) {
    filtered = filtered.filter(row => 
      row.company_name && row.company_name.toLowerCase().includes(searchFilters.value.companyName.trim().toLowerCase())
    );
  }

  // 거래처 필터
  if (searchFilters.value.clientName.trim()) {
    filtered = filtered.filter(row => 
      row.client_name && row.client_name.toLowerCase().includes(searchFilters.value.clientName.trim().toLowerCase())
    );
  }

  // 제품명 필터
  if (searchFilters.value.productName.trim()) {
    filtered = filtered.filter(row => 
      row.product_name && row.product_name.toLowerCase().includes(searchFilters.value.productName.trim().toLowerCase())
    );
  }

  // 보험코드 필터
  if (searchFilters.value.insuranceCode.trim()) {
    filtered = filtered.filter(row => 
      row.insurance_code && row.insurance_code.toLowerCase().includes(searchFilters.value.insuranceCode.trim().toLowerCase())
    );
  }

  displayRows.value = filtered;
}

function clearSearchFilters() {
  searchFilters.value = {
    companyName: '',
    clientName: '',
    productName: '',
    insuranceCode: ''
  };
  displayRows.value = [...allDisplayRows.value];
}
</script> 