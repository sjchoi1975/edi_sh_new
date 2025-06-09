<template>
  <div class="manual-container">
    <div class="manual-content">
      <h1>{{ isAdminManual ? '신일제약 CSO 실적 관리 시스템 - 관리자 메뉴얼' : '신일제약 CSO 실적 관리 시스템 - 이용자 메뉴얼' }}</h1>
      
      <!-- 탭 메뉴 -->
      <div class="manual-tabs">
        <div 
          v-for="(tab, index) in tabs" 
          :key="index"
          class="manual-tab"
          :class="{ active: activeTab === index }"
          @click="activeTab = index"
        >
          {{ tab.label }}
        </div>
      </div>
      
      <!-- 탭 내용 -->
      <div v-html="tabs[activeTab]?.content" class="manual-html-content"></div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';

const route = useRoute();
const activeTab = ref(0);

const isAdminManual = computed(() => route.path === '/admin-manual');

// 관리자 탭 내용
const adminTabs = [
  {
    label: '1. 공지사항 관리',
    content: `
      <div class="section">
        <h2>1. 공지사항 관리</h2>
        <h3>1.1 공지사항 목록 <span class="path">/admin/notices</span></h3>
        <p><strong>설명:</strong> 공지사항을 조회하고 관리할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
        
        <h4>주요 기능:</h4>
        <ul class="feature-list">
          <li>공지사항 목록 조회 (제목, 작성일시, 조회수, 고정여부)</li>
          <li>공지사항 등록</li>
          <li>공지사항 수정</li>
          <li>공지사항 삭제</li>
          <li>첨부파일 관리</li>
        </ul>
      </div>
    `
  },
  {
    label: '2. 업체 관리',
    content: `
      <div class="section">
        <h2>2. 업체 관리</h2>
        <h3>2.1 승인 업체 목록 <span class="path">/admin/companies/approved</span></h3>
        <p><strong>설명:</strong> CSO 업체의 기본 정보를 조회하고 관리할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
        
        <h4>주요 기능:</h4>
        <ul class="feature-list">
          <li>업체 목록 조회 (업체명, 사업자번호, 대표자명, 담당자, 연락처, 수수료 등급, 상태)</li>
          <li>업체 상세 정보 조회</li>
          <li>업체 정보 수정</li>
          <li>업체 상태 변경 (활성/비활성)</li>
          <li>업체 삭제</li>
        </ul>
        
        <h3>2.2 미승인 업체 목록 <span class="path">/admin/companies/pending</span></h3>
        <p><strong>설명:</strong> 신규 등록된 CSO 업체의 승인/반려 처리를 할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
        
        <h4>주요 기능:</h4>
        <ul class="feature-list">
          <li>미승인 업체 목록 조회</li>
          <li>업체 정보 검토</li>
          <li>승인/반려 처리</li>
          <li>승인 시 수수료 등급 설정</li>
          <li>처리 결과 이메일 발송</li>
        </ul>
      </div>
    `
  },
  {
    label: '3. 제품 관리',
    content: `
      <div class="section">
        <h2>3. 제품 관리</h2>
        <h3>3.1 제품 목록 <span class="path">/admin/products</span></h3>
        <p><strong>설명:</strong> 제품 정보를 조회하고 관리할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
        
        <h4>📤 엑셀 등록 (5단계 확인 프로세스):</h4>
        <ul class="feature-list">
          <li><strong>1단계:</strong> 기존 데이터 존재 확인 → "기존 데이터가 있습니다. 계속 등록하시겠습니까?"</li>
          <li><strong>2단계:</strong> 추가/대체 선택 → "기존 데이터에 추가하시겠습니까? 대체하시겠습니까?"</li>
          <li><strong>3단계:</strong> 중복 체크 (표준코드 + 기준월 기준)</li>
          <li><strong>4단계:</strong> 중복 발견 시 진행 여부 → "계속 등록 작업을 진행하시겠습니까?"</li>
          <li><strong>5단계:</strong> 중복 해결 방법 → "이미 동일한 표준코드 제품을 어떻게 처리하시겠습니까?"</li>
        </ul>
      </div>
    `
  },
  {
    label: '4. 거래처 관리',
    content: `
      <div class="section">
        <h2>4. 거래처 관리</h2>
        <h3>4.1 거래처 목록 <span class="path">/admin/clients</span></h3>
        <p><strong>설명:</strong> 거래처(병원) 정보를 조회하고 관리할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
        
        <h4>📤 엑셀 등록 (5단계 확인 프로세스):</h4>
        <ul class="feature-list">
          <li><strong>1단계:</strong> 기존 데이터 존재 확인</li>
          <li><strong>2단계:</strong> 추가/대체 선택</li>
          <li><strong>3단계:</strong> 중복 체크 (사업자등록번호 기준)</li>
          <li><strong>4단계:</strong> 중복 발견 시 진행 여부</li>
          <li><strong>5단계:</strong> 중복 해결 방법</li>
        </ul>
      </div>
    `
  },
  {
    label: '5. 문전약국 관리',
    content: `
      <div class="section">
        <h2>5. 문전약국 관리</h2>
        <h3>5.1 문전약국 목록 <span class="path">/admin/pharmacies</span></h3>
        <p><strong>설명:</strong> 문전약국 정보를 조회하고 관리할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
        
        <h4>📤 엑셀 등록 (5단계 확인 프로세스):</h4>
        <ul class="feature-list">
          <li><strong>1단계:</strong> 기존 데이터 존재 확인</li>
          <li><strong>2단계:</strong> 추가/대체 선택</li>
          <li><strong>3단계:</strong> 중복 체크 (사업자등록번호 기준)</li>
          <li><strong>4단계:</strong> 중복 발견 시 진행 여부</li>
          <li><strong>5단계:</strong> 중복 해결 방법</li>
        </ul>
      </div>
    `
  },
  {
    label: '6. 매출 관리',
    content: `
      <div class="section">
        <h2>6. 매출 관리</h2>
        <h3>6.1 도매매출 관리 <span class="path">/admin/wholesale-revenue</span></h3>
        <p><strong>설명:</strong> 도매매출 데이터를 등록하고 관리할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
        
        <h3>6.2 직거래매출 관리 <span class="path">/admin/direct-revenue</span></h3>
        <p><strong>설명:</strong> 직거래매출 데이터를 등록하고 관리할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
      </div>
    `
  },
  {
    label: '7. 실적 관리',
    content: `
      <div class="section">
        <h2>7. 실적 관리</h2>
        <h3>7.1 정산월 관리 <span class="path">/admin/settlement-months</span></h3>
        <p><strong>설명:</strong> 정산월을 설정하고 관리할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
        
        <h3>7.2 업체별 등록 현황 <span class="path">/admin/performance/companies</span></h3>
        <p><strong>설명:</strong> CSO 업체별 실적 등록 현황을 조회하고 관리할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
      </div>
    `
  },
  {
    label: '8. 정산 관리',
    content: `
      <div class="section">
        <h2>8. 정산 관리</h2>
        <h3>8.1 흡수율 분석 <span class="path">/admin/absorption-analysis</span></h3>
        <p><strong>설명:</strong> 매출 대비 실적 흡수율을 분석하고 리포트를 생성할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
        
        <h3>8.2 정산내역서 공유 <span class="path">/admin/settlement-share</span></h3>
        <p><strong>설명:</strong> CSO 업체별 정산내역서를 생성하고 공유할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
      </div>
    `
  }
];

// 이용자 탭 내용
const userTabs = [
  {
    label: '1. 공지사항 조회',
    content: `
      <div class="section">
        <h2>1. 공지사항 조회</h2>
        <h3>1.1 공지사항 조회 <span class="path">/notices</span></h3>
        <p><strong>설명:</strong> 관리자(제약사)의 주요 공지사항을 확인할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
        
        <h4>주요 기능:</h4>
        <ul class="feature-list">
          <li>공지사항 목록 조회 (제목, 작성일시, 조회수)</li>
          <li>공지사항 상세 조회</li>
          <li>고정 공지사항 확인</li>
          <li>첨부파일 다운로드</li>
          <li>검색 기능</li>
        </ul>
      </div>
    `
  },
  {
    label: '2. 제품 조회',
    content: `
      <div class="section">
        <h2>2. 제품 조회</h2>
        <h3>2.1 제품 조회 <span class="path">/products</span></h3>
        <p><strong>설명:</strong> 제품 정보를 조회하고 상세 내용을 확인할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
        
        <h4>주요 기능:</h4>
        <ul class="feature-list">
          <li>제품 목록 조회 (제품명, 보험코드, 가격, 표준코드)</li>
          <li>제품 상세 정보 조회</li>
          <li>제품 검색</li>
          <li>정렬 기능</li>
          <li>필터링 기능</li>
        </ul>
      </div>
    `
  },
  {
    label: '3. 거래처 조회',
    content: `
      <div class="section">
        <h2>3. 거래처 조회</h2>
        <h3>3.1 거래처 조회 <span class="path">/clients</span></h3>
        <p><strong>설명:</strong> 담당 거래처 정보를 조회하고 상세 내용을 확인할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
        
        <h4>주요 기능:</h4>
        <ul class="feature-list">
          <li>거래처 목록 조회 (거래처명, 사업자번호, 담당자, 연락처)</li>
          <li>거래처 상세 정보 조회</li>
          <li>거래처 검색</li>
          <li>정렬 기능</li>
          <li>필터링 기능</li>
        </ul>
      </div>
    `
  },
  {
    label: '4. 실적 관리',
    content: `
      <div class="section">
        <h2>4. 실적 관리</h2>
        <h3>4.1 실적 등록 <span class="path">/performance/register</span></h3>
        <p><strong>설명:</strong> 담당 거래처에 대한 실적 데이터를 등록할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
        
        <h4>주요 기능:</h4>
        <ul class="feature-list">
          <li>기본 정보 입력 (거래처, 제품, 수량, 금액)</li>
          <li>증빙 파일 업로드</li>
          <li>입력값 유효성 검사</li>
          <li>저장 시 확인 메시지</li>
          <li>실적 데이터 수정</li>
        </ul>

        <h3>4.2 엑셀 업로드 <span class="path">/performance/excell</span></h3>
        <p><strong>설명:</strong> 엑셀 파일을 통해 실적 데이터를 대량으로 등록할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
        
        <h4>주요 기능:</h4>
        <ul class="feature-list">
          <li>엑셀 파일 업로드</li>
          <li>데이터 검증</li>
          <li>업로드 결과 확인</li>
          <li>템플릿 다운로드</li>
          <li>오류 데이터 확인</li>
        </ul>
      </div>
    `
  },
  {
    label: '5. 정산내역서 조회',
    content: `
      <div class="section">
        <h2>5. 정산내역서 조회</h2>
        <h3>5.1 정산내역서 조회 <span class="path">/settlements</span></h3>
        <p><strong>설명:</strong> 공유된 정산내역서를 조회하고 다운로드할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
        
        <h4>주요 기능:</h4>
        <ul class="feature-list">
          <li>정산내역서 목록 조회 (년월, 정산액, 상태)</li>
          <li>정산내역서 상세 조회</li>
          <li>정산내역서 다운로드</li>
          <li>정렬 기능</li>
          <li>필터링 기능</li>
        </ul>
      </div>
    `
  },
  {
    label: '6. 내 정보 관리',
    content: `
      <div class="section">
        <h2>6. 내 정보 관리</h2>
        <h3>6.1 내 정보 조회/수정 <span class="path">/my-info</span></h3>
        <p><strong>설명:</strong> 계정 정보를 조회하고 수정할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
        
        <h4>주요 기능:</h4>
        <ul class="feature-list">
          <li>기본 정보 조회</li>
          <li>담당자 정보 수정</li>
          <li>연락처 수정</li>
          <li>이메일 수정</li>
          <li>저장 시 확인 메시지</li>
        </ul>

        <h3>6.2 비밀번호 변경 <span class="path">/my-info/change-password</span></h3>
        <p><strong>설명:</strong> 계정 비밀번호를 변경할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
        
        <h4>주요 기능:</h4>
        <ul class="feature-list">
          <li>현재 비밀번호 확인</li>
          <li>새 비밀번호 입력</li>
          <li>비밀번호 변경</li>
          <li>입력값 유효성 검사</li>
          <li>변경 시 확인 메시지</li>
        </ul>
      </div>
    `
  }
];

const tabs = computed(() => {
  return isAdminManual.value ? adminTabs : userTabs;
});
</script>

<style scoped>
.manual-container {
  display: flex;
  justify-content: center;
  padding: 20px;
  min-height: 100vh;
  background-color: #f8f9fa;
}

.manual-content {
  max-width: 1200px;
  width: 100%;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

h1 {
  color: #2c3e50;
  border-bottom: 2px solid #3498db;
  padding: 20px 30px;
  margin: 0;
  background: #f8f9fa;
  font-size: 24px;
  font-weight: 600;
}

.manual-tabs {
  display: flex;
  background: #fff;
  border-bottom: 1px solid #dee2e6;
  overflow-x: auto;
  position: sticky;
  top: 0;
  z-index: 100;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  padding: 0 20px;
}

.manual-tab {
  padding: 15px 20px;
  cursor: pointer;
  border-bottom: 3px solid transparent;
  white-space: nowrap;
  transition: all 0.3s ease;
  font-weight: 500;
  color: #6c757d;
  flex-shrink: 0;
}

.manual-tab:hover {
  background-color: #f8f9fa;
  color: #495057;
}

.manual-tab.active {
  border-bottom-color: #3498db;
  color: #3498db;
  background-color: #f8f9fa;
}

.manual-html-content {
  font-family: 'Noto Sans KR', sans-serif;
  line-height: 1.6;
  color: #333;
  padding: 20px;
}

.manual-html-content :deep(.section) {
  margin-bottom: 30px;
  padding: 20px;
  background: #f9f9f9;
  border-radius: 5px;
}

.manual-html-content :deep(h2) {
  color: #2980b9;
  margin-top: 0;
  margin-bottom: 20px;
  font-size: 20px;
}

.manual-html-content :deep(h3) {
  color: #16a085;
  margin-top: 25px;
  margin-bottom: 15px;
  font-size: 18px;
}

.manual-html-content :deep(h4) {
  color: #27ae60;
  margin-top: 20px;
  margin-bottom: 10px;
  font-size: 16px;
}

.manual-html-content :deep(.feature-list) {
  list-style-type: none;
  padding-left: 20px;
  margin: 15px 0;
}

.manual-html-content :deep(.feature-list li) {
  margin-bottom: 8px;
  position: relative;
  padding-left: 0;
}

.manual-html-content :deep(.feature-list li:before) {
  content: "•";
  color: #3498db;
  font-weight: bold;
  position: absolute;
  left: -15px;
}

.manual-html-content :deep(.path) {
  color: #7f8c8d;
  font-family: 'Courier New', monospace;
  background: #f1f1f1;
  padding: 2px 6px;
  border-radius: 3px;
  font-size: 14px;
}

.manual-html-content :deep(p) {
  margin: 15px 0;
  line-height: 1.6;
}

.manual-html-content :deep(strong) {
  color: #2c3e50;
  font-weight: 600;
}

.manual-html-content :deep(.image-placeholder) {
  width: 100%;
  height: 300px;
  border: 2px dashed #ddd;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 20px 0;
  background-color: #f8f9fa;
}

.manual-html-content :deep(.placeholder-text) {
  color: #999;
  font-size: 16px;
  font-weight: 500;
}

@media (max-width: 768px) {
  .manual-container {
    padding: 10px;
  }
  
  .manual-content {
    border-radius: 0;
  }
  
  h1 {
    font-size: 20px;
    padding: 15px 20px;
  }
  
  .manual-tabs {
    padding: 0 10px;
  }
  
  .manual-tab {
    padding: 12px 15px;
    font-size: 14px;
  }
  
  .manual-html-content :deep(.section) {
    padding: 15px;
  }
  
  .manual-html-content :deep(.image-placeholder) {
    height: 200px;
  }
}
</style> 