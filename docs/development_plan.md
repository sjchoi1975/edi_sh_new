# 신일제약 CSO 실적 관리 시스템 개발 기획서

## 1. 프로젝트 개요
- **목적**: CSO 업체의 실적을 효율적으로 관리하고 모니터링하며, 매출 데이터와 연계하여 정산 프로세스를 자동화합니다.
- **주요 이해관계자**: 관리자(제약사), CSO 업체 대표
- **핵심 기능**: CSO 업체 관리, 제품 및 거래처 정보 관리, 실적 등록, 매출 데이터 관리, 정산 관리, 공지사항 관리

## 2. 기술 스택
- **프론트엔드**: Vue.js 3, PrimeVue, Vite
- **백엔드**: Supabase (인증, PostgreSQL DB, Storage, RLS)
- **배포**: Vercel (프론트엔드), Supabase (백엔드)

## 3. 데이터베이스 설계

### 3.1 사용자 및 인증
```sql
-- CSO 업체 정보
CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    company_name TEXT NOT NULL,
    business_number TEXT UNIQUE NOT NULL,
    representative_name TEXT NOT NULL,
    address TEXT NOT NULL,
    contact_name TEXT NOT NULL,
    contact_phone TEXT NOT NULL,
    contact_email TEXT NOT NULL,
    commission_grade TEXT NOT NULL CHECK (commission_grade IN ('A', 'B')),
    approval_status TEXT NOT NULL DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- RLS 정책
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "관리자는 모든 업체 정보 조회 가능" ON companies
    FOR SELECT TO admin
    USING (true);

CREATE POLICY "관리자는 업체 정보 수정 가능" ON companies
    FOR UPDATE TO admin
    USING (true);

CREATE POLICY "업체는 자신의 정보만 조회 가능" ON companies
    FOR SELECT TO authenticated
    USING (auth.uid() = id);
```

### 3.2 제품 및 거래
```sql
-- 제품 정보
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    insurance_code TEXT UNIQUE NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    commission_rate_a DECIMAL(5,2) NOT NULL,
    commission_rate_b DECIMAL(5,2) NOT NULL,
    standard_code TEXT UNIQUE NOT NULL,
    unit TEXT NOT NULL,
    package_quantity INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 거래처(병원) 정보
CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    business_number TEXT UNIQUE NOT NULL,
    address TEXT NOT NULL,
    contact_name TEXT NOT NULL,
    contact_phone TEXT NOT NULL,
    contact_email TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 문전약국 정보
CREATE TABLE pharmacies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    business_number TEXT UNIQUE NOT NULL,
    address TEXT NOT NULL,
    contact_name TEXT NOT NULL,
    contact_phone TEXT NOT NULL,
    contact_email TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 거래처-업체 매핑
CREATE TABLE client_company_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID REFERENCES clients(id),
    company_id UUID REFERENCES companies(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(client_id, company_id)
);

-- 거래처-약국 매핑
CREATE TABLE client_pharmacy_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID REFERENCES clients(id),
    pharmacy_id UUID REFERENCES pharmacies(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(client_id, pharmacy_id)
);

-- 약국 매핑 (흡수율 분석용)
CREATE TABLE pharmacy_mappings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID REFERENCES clients(id),
    pharmacy_id UUID REFERENCES pharmacies(id),
    mapping_type TEXT NOT NULL CHECK (mapping_type IN ('primary', 'secondary')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(client_id, pharmacy_id, mapping_type)
);
```

### 3.3 매출 및 실적
```sql
-- 도매매출
CREATE TABLE wholesale_sales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pharmacy_id UUID REFERENCES pharmacies(id),
    product_id UUID REFERENCES products(id),
    sales_date DATE NOT NULL,
    quantity INTEGER NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 직거래매출
CREATE TABLE direct_sales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID REFERENCES clients(id),
    product_id UUID REFERENCES products(id),
    sales_date DATE NOT NULL,
    quantity INTEGER NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 실적 데이터
CREATE TABLE performance_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id),
    client_id UUID REFERENCES clients(id),
    product_id UUID REFERENCES products(id),
    performance_date DATE NOT NULL,
    quantity INTEGER NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    evidence_file_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 실적 증빙 파일
CREATE TABLE performance_evidence_files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    performance_id UUID REFERENCES performance_records(id),
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    mime_type TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### 3.4 정산
```sql
-- 정산월
CREATE TABLE settlement_months (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    year INTEGER NOT NULL,
    month INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(year, month)
);

-- 정산내역서 공유
CREATE TABLE settlement_share (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    settlement_month_id UUID REFERENCES settlement_months(id),
    company_id UUID REFERENCES companies(id),
    total_amount DECIMAL(10,2) NOT NULL,
    commission_amount DECIMAL(10,2) NOT NULL,
    report_url TEXT NOT NULL,
    shared_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### 3.5 기타
```sql
-- 공지사항
CREATE TABLE notices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    is_pinned BOOLEAN DEFAULT false,
    view_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 공지사항 첨부파일
CREATE TABLE notice_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notice_id UUID REFERENCES notices(id),
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    mime_type TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

## 4. 사용자 메뉴얼

### 4.1 관리자 메뉴얼

#### 4.1.1 업체 관리
##### 4.1.1.1 승인 업체 목록 (`/admin/companies/approved`)
- **설명**: CSO 업체의 기본 정보를 조회하고 관리할 수 있습니다.
- **화면 구성**:
  - 상단: 검색 필터 (업체명, 사업자번호, 담당자명)
  - 중앙: 업체 목록 테이블
  - 하단: 페이지네이션
- **주요 기능**:
  - 업체 목록 조회 (업체명, 사업자번호, 대표자명, 담당자, 연락처, 수수료 등급, 상태)
  - 업체 상세 정보 조회
  - 업체 정보 수정
  - 업체 상태 변경 (활성/비활성)
  - 업체 삭제

##### 4.1.1.2 미승인 업체 목록 (`/admin/companies/pending`)
- **설명**: 신규 등록된 CSO 업체의 승인/반려 처리를 할 수 있습니다.
- **화면 구성**:
  - 상단: 검색 필터 (업체명, 사업자번호)
  - 중앙: 미승인 업체 목록 테이블
  - 하단: 페이지네이션
- **주요 기능**:
  - 미승인 업체 목록 조회
  - 업체 정보 검토
  - 승인/반려 처리
  - 승인 시 수수료 등급 설정
  - 처리 결과 이메일 발송

##### 4.1.1.3 업체 등록 (`/admin/companies/create`)
- **설명**: 새로운 CSO 업체를 수동으로 등록할 수 있습니다.
- **화면 구성**:
  - 상단: 제목
  - 중앙: 입력 폼
  - 하단: 저장/취소 버튼
- **주요 기능**:
  - 기본 정보 입력 (업체명, 사업자번호, 대표자명, 주소)
  - 담당자 정보 입력 (이름, 연락처, 이메일)
  - 수수료 등급 설정
  - 입력값 유효성 검사
  - 사업자등록번호 중복 체크

#### 4.1.2 제품 관리
##### 4.1.2.1 제품 목록 (`/admin/products`)
- **설명**: 제품 정보를 조회하고 관리할 수 있습니다.
- **화면 구성**:
  - 상단: 기준월 선택 드롭다운, 검색 필터 (제품명, 보험코드, 표준코드)
  - 중앙: 제품 목록 테이블
  - 하단: 페이지네이션
- **주요 기능**:
  - 제품 목록 조회 (제품명, 보험코드, 가격, 수수료율, 표준코드, 상태)
  - 기준월별 필터링
  - 제품 상세 정보 조회
  - 제품 정보 수정
  - 제품 삭제
  - **기준월별 모두 삭제** (선택된 기준월의 제품만 삭제)
  - **엑셀 등록 (5단계 확인 프로세스)**:
    1. 기존 데이터 존재 확인
    2. 추가/대체 선택
    3. 중복 체크 (표준코드 기준)
    4. 중복 발견 시 진행 여부 확인
    5. 중복 해결 방법 선택 (교체/기존 유지)

##### 4.1.2.2 제품 등록 (`/admin/products/create`)
- **설명**: 새로운 제품을 등록하고 수수료율을 설정할 수 있습니다.
- **화면 구성**:
  - 상단: 제목
  - 중앙: 입력 폼
  - 하단: 저장/취소 버튼
- **주요 기능**:
  - 기본 정보 입력 (제품명, 보험코드, 가격, 표준코드)
  - 수수료율 설정 (A/B 등급)
  - 포장 정보 입력 (단위, 수량)
  - 입력값 유효성 검사
  - 보험코드/표준코드 중복 체크

#### 4.1.3 거래처 관리
##### 4.1.3.1 거래처 목록 (`/admin/clients`)
- **설명**: 거래처(병원) 정보를 조회하고 관리할 수 있습니다.
- **화면 구성**:
  - 상단: 검색 필터 (거래처명, 사업자번호, 담당자명)
  - 중앙: 거래처 목록 테이블
  - 하단: 페이지네이션
- **주요 기능**:
  - 거래처 목록 조회 (거래처명, 사업자번호, 담당자, 연락처, 상태)
  - 거래처 상세 정보 조회
  - 거래처 정보 수정
  - 거래처 삭제
  - **엑셀 등록 (5단계 확인 프로세스)** - 사업자등록번호 기준 중복 체크

##### 4.1.3.2 거래처 등록 (`/admin/clients/create`)
- **설명**: 새로운 거래처를 등록하고 기본 정보를 설정할 수 있습니다.
- **화면 구성**:
  - 상단: 제목
  - 중앙: 입력 폼
  - 하단: 저장/취소 버튼
- **주요 기능**:
  - 기본 정보 입력 (거래처명, 사업자번호, 주소)
  - 담당자 정보 입력 (이름, 연락처, 이메일)
  - 입력값 유효성 검사
  - 사업자번호 중복 체크
  - 저장 시 확인 메시지

##### 4.1.3.3 담당업체 지정 (`/admin/clients/assign-companies`)
- **설명**: 거래처와 CSO 업체 간의 담당 관계를 설정할 수 있습니다.
- **화면 구성**:
  - 좌측: 거래처 목록
  - 우측: CSO 업체 목록
  - 하단: 저장/취소 버튼
- **주요 기능**:
  - 거래처 선택
  - 담당 CSO 지정
  - 담당 관계 저장
  - 담당 관계 해제
  - 변경 사항 확인

#### 4.1.4 문전약국 관리
##### 4.1.4.1 문전약국 목록 (`/admin/pharmacies`)
- **설명**: 문전약국 정보를 조회하고 관리할 수 있습니다.
- **화면 구성**:
  - 상단: 검색 필터 (약국명, 사업자번호, 담당자명)
  - 중앙: 약국 목록 테이블
  - 하단: 페이지네이션
- **주요 기능**:
  - 약국 목록 조회 (약국명, 사업자번호, 담당자, 연락처, 상태)
  - 약국 상세 정보 조회
  - 약국 정보 수정
  - 약국 삭제
  - **엑셀 등록 (5단계 확인 프로세스)** - 사업자등록번호 기준 중복 체크

##### 4.1.4.2 문전약국 등록 (`/admin/pharmacies/create`)
- **설명**: 새로운 문전약국을 등록하고 기본 정보를 설정할 수 있습니다.
- **화면 구성**:
  - 상단: 제목
  - 중앙: 입력 폼
  - 하단: 저장/취소 버튼
- **주요 기능**:
  - 기본 정보 입력 (약국명, 사업자번호, 주소)
  - 담당자 정보 입력 (이름, 연락처, 이메일)
  - 입력값 유효성 검사
  - 사업자번호 중복 체크
  - 저장 시 확인 메시지

##### 4.1.4.3 문전약국 지정 (`/admin/clients/assign-pharmacies`)
- **설명**: 거래처와 문전약국 간의 매핑 관계를 설정할 수 있습니다.
- **화면 구성**:
  - 좌측: 거래처 목록
  - 우측: 문전약국 목록
  - 하단: 저장/취소 버튼
- **주요 기능**:
  - 거래처 선택
  - 담당 약국 지정
  - 담당 관계 저장
  - 담당 관계 해제
  - 변경 사항 확인

#### 4.1.5 매출 관리
##### 4.1.5.1 도매매출 관리 (`/admin/wholesale-revenue`)
- **설명**: 도매매출 데이터를 등록하고 관리할 수 있습니다.
- **화면 구성**:
  - 상단: 검색 필터 (약국명, 제품명, 기간)
  - 중앙: 매출 목록 테이블
  - 하단: 페이지네이션
- **주요 기능**:
  - 매출 데이터 조회 (약국명, 제품명, 매출액, 매출일자)
  - 매출 데이터 수정
  - 매출 데이터 삭제
  - 엑셀 업로드로 대량 등록
  - 리포트 생성

##### 4.1.5.2 직거래매출 관리 (`/admin/direct-revenue`)
- **설명**: 직거래매출 데이터를 등록하고 관리할 수 있습니다.
- **화면 구성**:
  - 상단: 검색 필터 (거래처명, 제품명, 기간)
  - 중앙: 매출 목록 테이블
  - 하단: 페이지네이션
- **주요 기능**:
  - 매출 데이터 조회 (거래처명, 제품명, 매출액, 매출일자)
  - 매출 데이터 수정
  - 매출 데이터 삭제
  - 엑셀 업로드로 대량 등록
  - 리포트 생성

#### 4.1.6 실적 관리
##### 4.1.6.1 업체별 등록 현황 (`/admin/performance/companies`)
- **설명**: CSO 업체별 실적 등록 현황을 조회하고 관리할 수 있습니다.
- **화면 구성**:
  - 상단: 검색 필터 (업체명, 기간)
  - 중앙: 실적 목록 테이블
  - 하단: 페이지네이션
- **주요 기능**:
  - 실적 등록 현황 조회 (업체명, 등록 건수, 총 금액, 등록일시)
  - 실적 데이터 검증
  - 실적 데이터 수정
  - 실적 데이터 삭제
  - 리포트 생성

##### 4.1.6.2 전체 등록 현황 (`/admin/performance/whole`)
- **설명**: 전체 실적 데이터를 조회하고 관리할 수 있습니다.
- **화면 구성**:
  - 상단: 검색 필터 (업체명, 거래처명, 제품명, 기간)
  - 중앙: 실적 목록 테이블
  - 하단: 페이지네이션
- **주요 기능**:
  - 전체 실적 데이터 조회 (업체명, 거래처명, 제품명, 수량, 금액, 등록일시)
  - 실적 데이터 검증
  - 실적 데이터 수정
  - 실적 데이터 삭제
  - 리포트 생성

#### 4.1.7 정산 관리
##### 4.1.7.1 정산월 관리 (`/admin/settlement-months`)
- **설명**: 정산월을 설정하고 관리할 수 있습니다.
- **화면 구성**:
  - 상단: 검색 필터 (년월)
  - 중앙: 정산월 목록 테이블
  - 하단: 페이지네이션
- **주요 기능**:
  - 정산월 목록 조회 (년월, 상태, 생성일시)
  - 정산월 등록
  - 정산월 상태 관리
  - 정산월 삭제
  - 정산 내역 확인

##### 4.1.7.2 흡수율 분석 (`/admin/absorption-analysis`)
- **설명**: 매출 대비 실적 흡수율을 분석하고 리포트를 생성할 수 있습니다.
- **화면 구성**:
  - 상단: 검색 필터 (기간, 업체명, 거래처명)
  - 중앙: 분석 결과 테이블
  - 하단: 리포트 생성 버튼
- **주요 기능**:
  - 기간별 흡수율 조회
  - 업체별 흡수율 분석
  - 제품별 흡수율 분석
  - 리포트 생성
  - 데이터 시각화

##### 4.1.7.3 정산내역서 공유 (`/admin/settlement-share`)
- **설명**: CSO 업체별 정산내역서를 생성하고 공유할 수 있습니다.
- **화면 구성**:
  - 상단: 검색 필터 (정산월, 업체명)
  - 중앙: 정산내역서 목록 테이블
  - 하단: 페이지네이션
- **주요 기능**:
  - 정산내역서 생성
  - 업체별 공유 설정
  - 공유 상태 관리
  - 정산내역서 조회
  - 리포트 생성

#### 4.1.8 공지사항 관리
##### 4.1.8.1 공지사항 목록 (`/admin/notices`)
- **설명**: 공지사항을 조회하고 관리할 수 있습니다.
- **화면 구성**:
  - 상단: 검색 필터 (제목, 내용)
  - 중앙: 공지사항 목록 테이블
  - 하단: 페이지네이션
- **주요 기능**:
  - 공지사항 목록 조회 (제목, 작성일시, 조회수, 고정여부)
  - 공지사항 등록
  - 공지사항 수정
  - 공지사항 삭제
  - 첨부파일 관리

##### 4.1.8.2 공지사항 등록 (`/admin/notices/create`)
- **설명**: 새로운 공지사항을 등록하고 관리할 수 있습니다.
- **화면 구성**:
  - 상단: 제목
  - 중앙: 입력 폼
  - 하단: 저장/취소 버튼
- **주요 기능**:
  - 기본 정보 입력 (제목, 내용)
  - 고정 여부 설정
  - 첨부파일 업로드
  - 입력값 유효성 검사
  - 저장 시 확인 메시지

### 4.2 CSO 업체(이용자) 메뉴얼

#### 4.2.1 실적 관리
##### 4.2.1.1 실적 등록 (`/performance/register`)
- **설명**: 담당 거래처에 대한 실적 데이터를 등록할 수 있습니다.
- **화면 구성**:
  - 상단: 제목
  - 중앙: 입력 폼
  - 하단: 저장/취소 버튼
- **주요 기능**:
  - 기본 정보 입력 (거래처, 제품, 수량, 금액)
  - 증빙 파일 업로드
  - 입력값 유효성 검사
  - 저장 시 확인 메시지
  - 실적 데이터 수정

##### 4.2.1.2 엑셀 업로드 (`/performance/excell`)
- **설명**: 엑셀 파일을 통해 실적 데이터를 대량으로 등록할 수 있습니다.
- **화면 구성**:
  - 상단: 제목
  - 중앙: 업로드 영역
  - 하단: 업로드/취소 버튼
- **주요 기능**:
  - 엑셀 파일 업로드
  - 데이터 검증
  - 업로드 결과 확인
  - 템플릿 다운로드
  - 오류 데이터 확인

##### 4.2.1.3 등록 현황 (`/performance/list`)
- **설명**: 등록한 실적 데이터를 조회하고 관리할 수 있습니다.
- **화면 구성**:
  - 상단: 검색 필터 (거래처명, 제품명, 기간)
  - 중앙: 실적 목록 테이블
  - 하단: 페이지네이션
- **주요 기능**:
  - 실적 데이터 조회 (거래처명, 제품명, 수량, 금액, 등록일시)
  - 실적 데이터 수정
  - 실적 데이터 삭제
  - 증빙 파일 관리
  - 리포트 생성

#### 4.2.2 데이터 조회
##### 4.2.2.1 제품 조회 (`/products`)
- **설명**: 제품 정보를 조회하고 상세 내용을 확인할 수 있습니다.
- **화면 구성**:
  - 상단: 검색 필터 (제품명, 보험코드)
  - 중앙: 제품 목록 테이블
  - 하단: 페이지네이션
- **주요 기능**:
  - 제품 목록 조회 (제품명, 보험코드, 가격, 표준코드)
  - 제품 상세 정보 조회
  - 제품 검색
  - 정렬 기능
  - 필터링 기능

##### 4.2.2.2 거래처 조회 (`/clients`)
- **설명**: 담당 거래처 정보를 조회하고 상세 내용을 확인할 수 있습니다.
- **화면 구성**:
  - 상단: 검색 필터 (거래처명, 사업자번호)
  - 중앙: 거래처 목록 테이블
  - 하단: 페이지네이션
- **주요 기능**:
  - 거래처 목록 조회 (거래처명, 사업자번호, 담당자, 연락처)
  - 거래처 상세 정보 조회
  - 거래처 검색
  - 정렬 기능
  - 필터링 기능

#### 4.2.3 정산 조회
##### 4.2.3.1 정산내역서 조회 (`/settlements`)
- **설명**: 공유된 정산내역서를 조회하고 다운로드할 수 있습니다.
- **화면 구성**:
  - 상단: 검색 필터 (년월)
  - 중앙: 정산내역서 목록 테이블
  - 하단: 페이지네이션
- **주요 기능**:
  - 정산내역서 목록 조회 (년월, 정산액, 상태)
  - 정산내역서 상세 조회
  - 정산내역서 다운로드
  - 정렬 기능
  - 필터링 기능

#### 4.2.4 공지사항
##### 4.2.4.1 공지사항 조회 (`/notices`)
- **설명**: 관리자(제약사)의 주요 공지사항을 확인할 수 있습니다.
- **화면 구성**:
  - 상단: 검색 필터 (제목, 내용)
  - 중앙: 공지사항 목록 테이블
  - 하단: 페이지네이션
- **주요 기능**:
  - 공지사항 목록 조회 (제목, 작성일시, 조회수)
  - 공지사항 상세 조회
  - 고정 공지사항 확인
  - 첨부파일 다운로드
  - 검색 기능

#### 4.2.5 내 정보 관리
##### 4.2.5.1 내 정보 조회/수정 (`/my-info`)
- **설명**: 계정 정보를 조회하고 수정할 수 있습니다.
- **화면 구성**:
  - 상단: 제목
  - 중앙: 정보 표시/수정 폼
  - 하단: 저장/취소 버튼
- **주요 기능**:
  - 기본 정보 조회
  - 담당자 정보 수정
  - 연락처 수정
  - 이메일 수정
  - 저장 시 확인 메시지

##### 4.2.5.2 비밀번호 변경 (`/my-info/change-password`)
- **설명**: 계정 비밀번호를 변경할 수 있습니다.
- **화면 구성**:
  - 상단: 제목
  - 중앙: 입력 폼
  - 하단: 저장/취소 버튼
- **주요 기능**:
  - 현재 비밀번호 확인
  - 새 비밀번호 입력
  - 비밀번호 변경
  - 입력값 유효성 검사
  - 변경 시 확인 메시지 