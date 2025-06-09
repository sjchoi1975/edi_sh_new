<template>
  <div class="manual-container">
    <div class="manual-content">
      <!-- 고정될 헤더 영역 (제목 + 탭) -->
      <div class="manual-header">
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
          <li><strong>업체 목록 조회</strong> - 승인된 CSO 업체들의 기본 정보(업체명, 사업자번호, 대표자명, 담당자, 연락처, 수수료 등급, 상태)를 테이블 형태로 확인할 수 있습니다.</li>
          <li><strong>업체 상세 정보 조회</strong> - 특정 업체를 선택하여 등록된 모든 정보를 상세히 확인할 수 있습니다.</li>
          <li><strong>업체 정보 수정</strong> - 업체의 담당자, 연락처, 주소 등 기본 정보를 수정할 수 있습니다.</li>
          <li><strong>업체 상태 변경</strong> - 업체의 활성/비활성 상태를 변경하여 시스템 이용 권한을 관리할 수 있습니다.</li>
          <li><strong>업체 삭제</strong> - 더 이상 거래하지 않는 업체 정보를 시스템에서 완전히 삭제할 수 있습니다.</li>
        </ul>
        
        <h3>2.2 미승인 업체 목록 <span class="path">/admin/companies/pending</span></h3>
        <p><strong>설명:</strong> 신규 등록된 CSO 업체의 승인/반려 처리를 할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
        
        <h4>주요 기능:</h4>
        <ul class="feature-list">
          <li><strong>미승인 업체 목록 조회</strong> - 신규 가입 신청한 CSO 업체들의 대기 목록을 확인할 수 있습니다.</li>
          <li><strong>업체 정보 검토</strong> - 신청업체의 사업자등록증, 업체 정보, 담당자 정보 등을 상세히 검토할 수 있습니다.</li>
          <li><strong>승인/반려 처리</strong> - 검토 결과에 따라 업체 가입을 승인하거나 반려할 수 있습니다.</li>
          <li><strong>승인 시 수수료 등급 설정</strong> - 승인과 동시에 해당 업체의 수수료 등급(A, B, C 등)을 설정할 수 있습니다.</li>
          <li><strong>처리 결과 이메일 발송</strong> - 승인/반려 결과를 해당 업체 담당자에게 자동으로 이메일로 통지합니다.</li>
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
        <div class="process-steps">
          <div class="step">
            <strong>1단계: 기존 데이터 존재 확인</strong><br>
            <em>조건:</em> 기존 제품이 있는 경우<br>
            <em>메시지:</em> "기존 데이터가 있습니다. 계속 등록하시겠습니까?"<br>
            <em>확인:</em> 2단계로 진행 / <em>취소:</em> 작업 중단
          </div>
          <div class="step">
            <strong>2단계: 추가 vs 대체 선택</strong><br>
            <em>메시지:</em> "기존 데이터에 추가하시겠습니까? 대체하시겠습니까?"<br>
            <em>추가:</em> 추가 모드 → 3단계 (중복 체크)<br>
            <em>대체:</em> 대체 모드 → 기존 데이터 삭제 후 바로 등록 (중복 체크 건너뜀)
          </div>
          <div class="step">
            <strong>3단계: 중복 체크 (추가 모드에서만)</strong><br>
            <em>기준:</em> 표준코드 + 기준월 중복 확인<br>
            <em>중복 없음:</em> 바로 등록 / <em>중복 있음:</em> 4단계로 진행
          </div>
          <div class="step">
            <strong>4단계: 중복 발견 시 계속 진행 여부</strong><br>
            <em>메시지:</em> "n행: 이미 동일한 표준코드의 제품이 등록되어 있습니다. 계속 등록 작업을 진행하시겠습니까?"<br>
            <em>확인:</em> 5단계로 진행 / <em>취소:</em> 작업 중단
          </div>
          <div class="step">
            <strong>5단계: 중복 해결 방법 선택</strong><br>
            <em>메시지:</em> "이미 동일한 표준코드 제품을 어떻게 처리하시겠습니까?"<br>
            <em>교체:</em> 기존 제품정보 삭제 후 신규 제품 등록<br>
            <em>유지:</em> 중복되지 않는 신규 제품만 등록 (기존 유지)
          </div>
        </div>
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
        <div class="process-steps">
          <div class="step">
            <strong>1단계: 기존 데이터 존재 확인</strong><br>
            <em>조건:</em> 기존 거래처가 있는 경우<br>
            <em>메시지:</em> "기존 데이터가 있습니다. 계속 등록하시겠습니까?"<br>
            <em>확인:</em> 2단계로 진행 / <em>취소:</em> 작업 중단
          </div>
          <div class="step">
            <strong>2단계: 추가 vs 대체 선택</strong><br>
            <em>메시지:</em> "기존 데이터에 추가하시겠습니까? 대체하시겠습니까?"<br>
            <em>추가:</em> 추가 모드 → 3단계 (중복 체크)<br>
            <em>대체:</em> 대체 모드 → 기존 데이터 삭제 후 바로 등록 (중복 체크 건너뜀)
          </div>
          <div class="step">
            <strong>3단계: 중복 체크 (추가 모드에서만)</strong><br>
            <em>기준:</em> 사업자등록번호 중복 확인<br>
            <em>중복 없음:</em> 바로 등록 / <em>중복 있음:</em> 4단계로 진행
          </div>
          <div class="step">
            <strong>4단계: 중복 발견 시 계속 진행 여부</strong><br>
            <em>메시지:</em> "n행: 이미 동일한 사업자등록번호의 거래처가 등록되어 있습니다. 계속 등록 작업을 진행하시겠습니까?"<br>
            <em>확인:</em> 5단계로 진행 / <em>취소:</em> 작업 중단
          </div>
          <div class="step">
            <strong>5단계: 중복 해결 방법 선택</strong><br>
            <em>메시지:</em> "이미 동일한 사업자등록번호 거래처를 어떻게 처리하시겠습니까?"<br>
            <em>교체:</em> 기존 거래처정보 삭제 후 신규 거래처 등록<br>
            <em>유지:</em> 중복되지 않는 신규 거래처만 등록 (기존 유지)
          </div>
        </div>
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
        <div class="process-steps">
          <div class="step">
            <strong>1단계: 기존 데이터 존재 확인</strong><br>
            <em>조건:</em> 기존 문전약국이 있는 경우<br>
            <em>메시지:</em> "기존 데이터가 있습니다. 계속 등록하시겠습니까?"<br>
            <em>확인:</em> 2단계로 진행 / <em>취소:</em> 작업 중단
          </div>
          <div class="step">
            <strong>2단계: 추가 vs 대체 선택</strong><br>
            <em>메시지:</em> "기존 데이터에 추가하시겠습니까? 대체하시겠습니까?"<br>
            <em>추가:</em> 추가 모드 → 3단계 (중복 체크)<br>
            <em>대체:</em> 대체 모드 → 기존 데이터 삭제 후 바로 등록 (중복 체크 건너뜀)
          </div>
          <div class="step">
            <strong>3단계: 중복 체크 (추가 모드에서만)</strong><br>
            <em>기준:</em> 사업자등록번호 중복 확인<br>
            <em>중복 없음:</em> 바로 등록 / <em>중복 있음:</em> 4단계로 진행
          </div>
          <div class="step">
            <strong>4단계: 중복 발견 시 계속 진행 여부</strong><br>
            <em>메시지:</em> "n행: 이미 동일한 사업자등록번호의 약국이 등록되어 있습니다. 계속 등록 작업을 진행하시겠습니까?"<br>
            <em>확인:</em> 5단계로 진행 / <em>취소:</em> 작업 중단
          </div>
          <div class="step">
            <strong>5단계: 중복 해결 방법 선택</strong><br>
            <em>메시지:</em> "이미 동일한 사업자등록번호 약국을 어떻게 처리하시겠습니까?"<br>
            <em>교체:</em> 기존 약국정보 삭제 후 신규 약국 등록<br>
            <em>유지:</em> 중복되지 않는 신규 약국만 등록 (기존 유지)
          </div>
        </div>
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
          <li><strong>공지사항 목록 조회</strong> - 관리자가 등록한 공지사항들을 제목, 작성일시, 조회수와 함께 목록 형태로 확인할 수 있습니다.</li>
          <li><strong>공지사항 상세 조회</strong> - 제목을 클릭하여 공지사항의 전체 내용을 상세히 확인할 수 있습니다.</li>
          <li><strong>고정 공지사항 확인</strong> - 중요한 공지사항은 목록 상단에 고정되어 우선적으로 확인할 수 있습니다.</li>
          <li><strong>첨부파일 다운로드</strong> - 공지사항에 첨부된 파일들을 다운로드하여 확인할 수 있습니다.</li>
          <li><strong>검색 기능</strong> - 제목이나 내용에서 원하는 키워드로 공지사항을 검색할 수 있습니다.</li>
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
          <li><strong>제품 목록 조회</strong> - 판매 가능한 제품들의 제품명, 보험코드, 가격, 표준코드 정보를 테이블 형태로 확인할 수 있습니다.</li>
          <li><strong>제품 상세 정보 조회</strong> - 특정 제품을 선택하여 상세한 제품 정보와 규격을 확인할 수 있습니다.</li>
          <li><strong>제품 검색</strong> - 제품명, 보험코드, 표준코드로 원하는 제품을 빠르게 검색할 수 있습니다.</li>
          <li><strong>정렬 기능</strong> - 제품명, 가격, 등록일 등 다양한 기준으로 목록을 정렬하여 확인할 수 있습니다.</li>
          <li><strong>필터링 기능</strong> - 제품 카테고리나 가격 범위 등으로 제품 목록을 필터링할 수 있습니다.</li>
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
          <li><strong>거래처 목록 조회</strong> - 본인이 담당하는 거래처들의 거래처명, 사업자번호, 담당자, 연락처 정보를 확인할 수 있습니다.</li>
          <li><strong>거래처 상세 정보 조회</strong> - 특정 거래처를 선택하여 주소, 원장명, 진료과목 등 상세 정보를 확인할 수 있습니다.</li>
          <li><strong>거래처 검색</strong> - 거래처명이나 사업자번호로 담당 거래처를 빠르게 검색할 수 있습니다.</li>
          <li><strong>정렬 기능</strong> - 거래처명, 등록일, 지역 등 다양한 기준으로 목록을 정렬하여 확인할 수 있습니다.</li>
          <li><strong>필터링 기능</strong> - 지역이나 진료과목 등으로 거래처 목록을 필터링할 수 있습니다.</li>
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
          <li><strong>기본 정보 입력</strong> - 담당 거래처, 판매 제품, 처방 수량, 처방 금액 등 실적의 기본 정보를 입력할 수 있습니다.</li>
          <li><strong>증빙 파일 업로드</strong> - 처방전, 영수증 등 실적을 증명하는 파일을 업로드하여 관리할 수 있습니다.</li>
          <li><strong>입력값 유효성 검사</strong> - 필수 항목 누락, 숫자 형식 오류 등을 자동으로 체크하여 정확한 데이터 입력을 도와줍니다.</li>
          <li><strong>저장 시 확인 메시지</strong> - 실적 데이터 저장 전 입력 내용을 최종 확인할 수 있는 메시지를 제공합니다.</li>
          <li><strong>실적 데이터 수정</strong> - 이미 등록된 실적 데이터를 선택하여 내용을 수정할 수 있습니다.</li>
        </ul>

        <h3>4.2 엑셀 업로드 <span class="path">/performance/excell</span></h3>
        <p><strong>설명:</strong> 엑셀 파일을 통해 실적 데이터를 대량으로 등록할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
        
        <h4>주요 기능:</h4>
        <ul class="feature-list">
          <li><strong>엑셀 파일 업로드</strong> - 정해진 양식의 엑셀 파일을 선택하여 대량의 실적 데이터를 한 번에 업로드할 수 있습니다.</li>
          <li><strong>데이터 검증</strong> - 업로드된 엑셀 데이터의 형식과 내용을 자동으로 검증하여 오류를 사전에 확인합니다.</li>
          <li><strong>업로드 결과 확인</strong> - 성공/실패한 데이터 건수와 오류 내역을 상세히 확인할 수 있습니다.</li>
          <li><strong>템플릿 다운로드</strong> - 실적 데이터 입력을 위한 표준 엑셀 템플릿을 다운로드할 수 있습니다.</li>
          <li><strong>오류 데이터 확인</strong> - 업로드 실패한 데이터의 구체적인 오류 원인과 위치를 확인할 수 있습니다.</li>
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
          <li><strong>정산내역서 목록 조회</strong> - 관리자가 공유한 월별 정산내역서를 년월, 정산액, 공유 상태와 함께 확인할 수 있습니다.</li>
          <li><strong>정산내역서 상세 조회</strong> - 특정 월의 정산내역서를 선택하여 상세한 정산 내용과 실적 데이터를 확인할 수 있습니다.</li>
          <li><strong>정산내역서 다운로드</strong> - 정산내역서를 PDF나 Excel 파일로 다운로드하여 보관할 수 있습니다.</li>
          <li><strong>정렬 기능</strong> - 정산월, 정산액, 공유일 등 다양한 기준으로 정산내역서 목록을 정렬할 수 있습니다.</li>
          <li><strong>필터링 기능</strong> - 특정 기간이나 정산액 범위로 정산내역서를 필터링하여 조회할 수 있습니다.</li>
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
          <li><strong>기본 정보 조회</strong> - 현재 등록된 업체명, 담당자명, 연락처, 이메일 등 기본 정보를 확인할 수 있습니다.</li>
          <li><strong>담당자 정보 수정</strong> - 담당자명, 부서, 직책 등의 담당자 정보를 수정할 수 있습니다.</li>
          <li><strong>연락처 수정</strong> - 휴대폰 번호, 사무실 전화번호, 팩스 번호 등을 수정할 수 있습니다.</li>
          <li><strong>이메일 수정</strong> - 로그인 시 사용하는 이메일 주소를 변경할 수 있습니다.</li>
          <li><strong>저장 시 확인 메시지</strong> - 정보 수정 후 저장 시 변경사항을 최종 확인할 수 있는 메시지를 제공합니다.</li>
        </ul>

        <h3>6.2 비밀번호 변경 <span class="path">/my-info/change-password</span></h3>
        <p><strong>설명:</strong> 계정 비밀번호를 변경할 수 있습니다.</p>
        
        <div class="image-placeholder">
          <div class="placeholder-text">📷 화면 이미지</div>
        </div>
        
        <h4>주요 기능:</h4>
        <ul class="feature-list">
          <li><strong>현재 비밀번호 확인</strong> - 보안을 위해 현재 사용 중인 비밀번호를 입력하여 본인 확인을 수행합니다.</li>
          <li><strong>새 비밀번호 입력</strong> - 보안 정책에 맞는 새로운 비밀번호를 입력할 수 있습니다.</li>
          <li><strong>비밀번호 변경</strong> - 입력된 새 비밀번호로 계정 비밀번호를 변경합니다.</li>
          <li><strong>입력값 유효성 검사</strong> - 비밀번호 강도, 길이, 특수문자 포함 여부 등을 자동으로 검사합니다.</li>
          <li><strong>변경 시 확인 메시지</strong> - 비밀번호 변경 완료 시 성공 여부를 확인할 수 있는 메시지를 제공합니다.</li>
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
  height: 100vh;
  overflow-y: auto;
  background-color: #f8f9fa;
  padding: 0px;
  margin-left: 0px;
}

.manual-content {
  max-width: 1200px;
  margin: 0 auto;
  background: white;
  border-radius: 8px;
  box-shadow: 0 0px 0px rgba(0, 0, 0, 0);
  position: relative;
  overflow: visible;
}

.manual-header {
  position: sticky;
  top: 0;
  z-index: 1000;
  background: white;
  box-shadow: 0 0px 0px rgba(0,0,0,0);
  border-radius: 0px 0px 0px 0px;
  margin: 0;
}

h1 {
  color: #2c3e50;
  border-bottom: 2px solid #3498db;
  padding: 20px 30px;
  margin: 0;
  background: #fff;
  font-size: 24px;
  font-weight: 600;
}

.manual-tabs {
  display: flex;
  background: #fff;
  border-bottom: 1px solid #dee2e6;
  overflow-x: auto;
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
  background: #fff;
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

.manual-html-content :deep(.process-steps) {
  margin: 20px 0;
}

.manual-html-content :deep(.step) {
  background: #f8f9fa;
  border-left: 4px solid #3498db;
  padding: 15px 20px;
  margin-bottom: 15px;
  border-radius: 0 8px 8px 0;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.manual-html-content :deep(.step strong) {
  color: #2980b9;
  display: block;
  margin-bottom: 8px;
  font-size: 16px;
}

.manual-html-content :deep(.step em) {
  font-style: normal;
  font-weight: 600;
  color: #27ae60;
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