# 신일제약 CSO 실적 관리 시스템 개발 기획서 (2024)

## 1. 주요 기능 개요

### 1.1 관리자용(제약사)

#### 1.1.1 공지사항 관리
- 공지사항 CRUD
- 고정 공지사항 관리
- 첨부파일 관리
- 조회수 관리

#### 1.1.2 매출 관리
- 도매매출 데이터 관리
- 직거래매출 데이터 관리
- 매출 데이터 분석
- 리포트 생성

#### 1.1.3 실적 관리
- 정산월 관리
- 업체별 등록 현황 관리
- 전체 등록 현황 관리
- 실적 데이터 검증

#### 1.1.4 정산 관리
- 실적 검수
- 흡수율 분석
- 정산내역서 공유
- 정산 이력 관리

#### 1.1.5 기본 정보 관리
- CSO 업체 관리
- 제품 정보 관리
- 거래처/약국 관리
- 담당 관계 관리

### 1.2 이용자용(CSO 업체)

#### 1.2.1 공지사항
- 공지사항 조회
- 첨부파일 다운로드
- 고정 공지사항 확인

#### 1.2.2 실적 관리
- 실적 데이터 등록
- 등록 현황 조회
- 증빙 파일 관리

#### 1.2.3 정산 조회
- 정산내역서 조회
- 정산 이력 조회

#### 1.2.4 기본 정보 조회
- 제품 정보 조회
- 담당 거래처 조회
- 내 정보 관리

## 2. 데이터베이스 설계

### 2.1 사용자 및 인증
```sql
-- 사용자 프로필
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    role TEXT NOT NULL CHECK (role IN ('admin', 'company')),
    company_id UUID REFERENCES companies(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

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
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- 프로필 RLS
CREATE POLICY "관리자는 모든 프로필 조회 가능" ON profiles
    FOR SELECT TO admin
    USING (true);

CREATE POLICY "사용자는 자신의 프로필만 조회 가능" ON profiles
    FOR SELECT TO authenticated
    USING (auth.uid() = id);

-- 업체 RLS
CREATE POLICY "관리자는 모든 업체 정보 조회 가능" ON companies
    FOR SELECT TO admin
    USING (true);

CREATE POLICY "업체는 자신의 정보만 조회 가능" ON companies
    FOR SELECT TO authenticated
    USING (auth.uid() IN (SELECT id FROM profiles WHERE company_id = companies.id));
```

### 2.2 제품 관리
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

-- 제품 기준월
CREATE TABLE product_effective_dates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID REFERENCES products(id),
    effective_date DATE NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    commission_rate_a DECIMAL(5,2) NOT NULL,
    commission_rate_b DECIMAL(5,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_id, effective_date)
);

-- RLS 정책
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_effective_dates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "모든 인증된 사용자는 제품 조회 가능" ON products
    FOR SELECT TO authenticated
    USING (true);

CREATE POLICY "관리자만 제품 수정 가능" ON products
    FOR ALL TO admin
    USING (true);
```

### 2.3 거래처/약국 관리
```sql
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
    mapping_type TEXT NOT NULL CHECK (mapping_type IN ('primary', 'secondary')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(client_id, pharmacy_id, mapping_type)
);

-- RLS 정책
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE pharmacies ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_company_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_pharmacy_assignments ENABLE ROW LEVEL SECURITY;

-- 거래처 RLS
CREATE POLICY "관리자는 모든 거래처 조회 가능" ON clients
    FOR SELECT TO admin
    USING (true);

CREATE POLICY "업체는 담당 거래처만 조회 가능" ON clients
    FOR SELECT TO authenticated
    USING (id IN (
        SELECT client_id 
        FROM client_company_assignments 
        WHERE company_id IN (
            SELECT company_id 
            FROM profiles 
            WHERE id = auth.uid()
        )
    ));
```

### 2.4 실적 관리
```sql
-- 실적 데이터
CREATE TABLE performance_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id),
    client_id UUID REFERENCES clients(id),
    product_id UUID REFERENCES products(id),
    performance_date DATE NOT NULL,
    quantity INTEGER NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
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

-- RLS 정책
ALTER TABLE performance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_evidence_files ENABLE ROW LEVEL SECURITY;

-- 실적 RLS
CREATE POLICY "관리자는 모든 실적 조회 가능" ON performance_records
    FOR SELECT TO admin
    USING (true);

CREATE POLICY "업체는 자신의 실적만 조회 가능" ON performance_records
    FOR SELECT TO authenticated
    USING (company_id IN (
        SELECT company_id 
        FROM profiles 
        WHERE id = auth.uid()
    ));
```

### 2.5 매출 관리
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

-- RLS 정책
ALTER TABLE wholesale_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE direct_sales ENABLE ROW LEVEL SECURITY;

CREATE POLICY "관리자만 매출 데이터 접근 가능" ON wholesale_sales
    FOR ALL TO admin
    USING (true);

CREATE POLICY "관리자만 매출 데이터 접근 가능" ON direct_sales
    FOR ALL TO admin
    USING (true);
```

### 2.6 정산 관리
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

-- 정산내역서
CREATE TABLE settlement_reports (
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

-- RLS 정책
ALTER TABLE settlement_months ENABLE ROW LEVEL SECURITY;
ALTER TABLE settlement_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "관리자만 정산월 관리 가능" ON settlement_months
    FOR ALL TO admin
    USING (true);

CREATE POLICY "업체는 자신의 정산내역서만 조회 가능" ON settlement_reports
    FOR SELECT TO authenticated
    USING (company_id IN (
        SELECT company_id 
        FROM profiles 
        WHERE id = auth.uid()
    ));
```

### 2.7 공지사항
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

-- RLS 정책
ALTER TABLE notices ENABLE ROW LEVEL SECURITY;
ALTER TABLE notice_attachments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "모든 인증된 사용자는 공지사항 조회 가능" ON notices
    FOR SELECT TO authenticated
    USING (true);

CREATE POLICY "관리자만 공지사항 관리 가능" ON notices
    FOR ALL TO admin
    USING (true);
```

## 3. 기능별 상세 설계

### 3.1 관리자용(제약사)

#### 3.1.1 공지사항 관리
1. 공지사항 CRUD
   - 제목/내용 관리
   - 고정 여부 설정
   - 첨부파일 관리

2. 조회 관리
   - 조회수 관리
   - 정렬 관리
   - 검색 기능

#### 3.1.2 매출 관리
1. 도매매출 관리
   - 매출 데이터 등록
   - 매출 데이터 수정
   - 매출 데이터 삭제
   - 엑셀 업로드로 대량 등록

2. 직거래매출 관리
   - 매출 데이터 등록
   - 매출 데이터 수정
   - 매출 데이터 삭제
   - 엑셀 업로드로 대량 등록

#### 3.1.3 실적 관리

##### 3.1.3.1 정산월 관리
1. 정산월 설정
   - 년월 선택
   - 상태 관리 (대기/진행중/완료)
   - 이력 관리

2. 정산월별 데이터 관리
   - 실적 데이터 집계
   - 매출 데이터 집계
   - 검증 상태 관리

##### 3.1.3.2 업체별 등록 현황
1. 업체별 실적 조회
   - 업체 선택
   - 기간별 조회
   - 제품별 조회
   - 거래처별 조회

2. 실적 데이터 관리
   - 실적 검증
   - 승인/반려 처리
   - 수정 이력 관리
   - 증빙 파일 확인

##### 3.1.3.3 전체 등록 현황
1. 통합 실적 조회
   - 전체 업체 실적
   - 전체 제품 실적
   - 전체 거래처 실적
   - 기간별 조회

#### 3.1.4 정산 관리

##### 3.1.4.1 실적 검수
1. 실적 데이터 검증
   - 수량/금액 검증
   - 증빙 파일 확인
   - 검수 결과 기록

2. 검수 프로세스
   - 1차 검수
   - 2차 검수
   - 최종 승인
   - 반려 처리

3. 검수 이력 관리
   - 검수자 기록
   - 검수 일시 기록
   - 검수 결과 기록
   - 수정 이력 관리

##### 3.1.4.2 흡수율 분석
1. 매출 대비 실적 분석
   - 업체별 흡수율
   - 제품별 흡수율
   - 거래처별 흡수율
   - 기간별 흡수율

##### 3.1.4.3 정산내역서 공유
1. 정산내역서 생성
   - 실적 데이터 집계
   - 수수료 계산
   - 정산액 계산

2. 공유 관리
   - 업체별 공유 설정
   - 공유 일시 관리
   - 다운로드 관리
   - 공유 이력 관리

### 3.2 이용자용(CSO 업체)

#### 3.2.1 공지사항
1. 공지사항 조회
   - 목록 조회
   - 상세 조회
   - 고정 공지 확인
   - 검색 기능

2. 첨부파일
   - 파일 다운로드
   - 파일 목록 조회
   - 파일 크기 확인

#### 3.2.2 실적 관리
1. 실적 등록
   - 개별 등록
   - 증빙 파일 업로드
   - 등록 이력 관리

2. 등록 현황
   - 기간별 조회
   - 제품별 조회
   - 거래처별 조회
   - 상태별 조회

3. 증빙 파일
   - 파일 업로드
   - 파일 목록 관리
   - 파일 다운로드
   - 파일 삭제

#### 3.2.3 정산 조회
1. 정산내역서
   - 정산월별 조회
   - 정산액 확인
   - 수수료 확인

2. 정산 이력
   - 이력 조회
   - 상세 내역 확인

#### 3.2.4 기본 정보 조회
1. 제품 정보
   - 제품 목록 조회
   - 상세 정보 확인
   - 가격 정보 확인
   - 수수료율 확인

2. 담당 거래처
   - 거래처 목록 조회
   - 상세 정보 확인
   - 담당 약국 확인
   - 연락처 정보

3. 내 정보 관리
   - 기본 정보 조회
   - 담당자 정보 수정
   - 비밀번호 변경
   - 연락처 수정

## 4. 기술 스택

### 4.1 프론트엔드
- Vue.js 3
- PrimeVue
- Vite
- Supabase JS Client

### 4.2 백엔드
- Supabase
  - Authentication
  - PostgreSQL
  - Storage
  - Row Level Security

### 4.3 배포
- Vercel (프론트엔드)
- Supabase (백엔드)

## 5. 보안 고려사항

### 5.1 인증/인가
- JWT 기반 인증
- 역할 기반 접근 제어
- Row Level Security

### 5.2 데이터 보안
- 민감 정보 암호화
- 파일 업로드 제한
- API 요청 제한

### 5.3 감사
- 사용자 활동 로깅
- 데이터 변경 이력
- 접근 로그

