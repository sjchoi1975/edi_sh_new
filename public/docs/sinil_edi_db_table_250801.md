# 신일제약 실적관리 시스템 데이터베이스 테이블 구조 (2025-08-01)

## 📋 개요
본 문서는 신일제약 실적관리 시스템의 전체 데이터베이스 테이블 구조를 정리한 문서입니다.
모든 테이블은 PostgreSQL 기반으로 설계되었으며, Supabase에서 호스팅됩니다.

---

## 🗂️ 테이블 분류

### 1. 핵심 실적 관리 테이블
- `performance_records` - 사용자 실적 원본 데이터
- `performance_records_absorption` - 관리자 검수 및 분석용 테이블
- `performance_evidence_files` - 실적 증빙 파일 관리

### 2. 마스터 데이터 테이블
- `companies` - 업체 정보
- `clients` - 거래처(병의원) 정보
- `products` - 제품 정보
- `pharmacies` - 약국 정보
- `settlement_months` - 정산월 관리

### 3. 매핑 테이블
- `client_company_assignments` - 거래처-업체 매핑
- `client_pharmacy_assignments` - 거래처-약국 매핑

### 4. 매출 데이터 테이블
- `wholesale_sales` - 도매 매출 데이터
- `direct_sales` - 직거래 매출 데이터

### 5. 시스템 관리 테이블
- `notices` - 공지사항
- `notice_views` - 공지사항 조회 이력
- `settlement_share` - 정산내역서 공유 설정

---

## 📊 상세 테이블 구조

### 1. 핵심 실적 관리 테이블

#### 1.1. `performance_records` (사용자 실적 원본 테이블)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | bigint | NO | nextval('performance_records_id_seq') | 레코드 고유 ID (PK) |
| company_id | uuid | NO | null | 업체 ID (FK → companies.id) |
| settlement_month | varchar | NO | null | 정산월 (예: '2025-01') |
| prescription_month | varchar | NO | null | 처방월 (예: '2024-12') |
| client_id | bigint | NO | null | 거래처 ID (FK → clients.id) |
| product_id | uuid | NO | null | 제품 ID (FK → products.id) |
| prescription_qty | numeric | NO | null | 처방 수량 |
| prescription_type | varchar | NO | 'EDI' | 처방 유형 |
| remarks | text | YES | null | 비고 |
| registered_by | uuid | NO | null | 등록자 ID (FK → auth.users.id) |
| review_status | text | YES | '대기' | 검수 상태 ('대기', '검수중', '완료') |
| review_action | text | YES | null | 검수 작업 유형 |
| commission_rate | numeric | YES | null | 수수료율 |
| updated_by | uuid | YES | null | 수정자 ID (FK → auth.users.id) |
| created_at | timestamptz | YES | now() | 생성 시각 |
| updated_at | timestamptz | YES | now() | 수정 시각 |

#### 1.2. `performance_records_absorption` (관리자 검수 및 분석용 테이블)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | bigint | NO | null | 검수 레코드 고유 ID (PK) |
| created_at | timestamptz | NO | now() | 생성 시각 |
| settlement_month | varchar | YES | null | 정산월 |
| company_id | uuid | YES | null | 업체 ID (FK → companies.id) |
| client_id | bigint | YES | null | 거래처 ID (FK → clients.id) |
| product_id | uuid | YES | null | 제품 ID (FK → products.id) |
| prescription_month | varchar | YES | null | 처방월 |
| prescription_qty | numeric | YES | null | 처방 수량 |
| prescription_type | varchar | YES | null | 처방 유형 |
| commission_rate | numeric | YES | null | 수수료율 |
| remarks | text | YES | null | 비고 |
| registered_by | uuid | YES | null | 등록자 ID (FK → auth.users.id) |
| updated_at | timestamptz | YES | null | 수정 시각 |
| updated_by | uuid | YES | null | 수정자 ID (FK → auth.users.id) |
| review_action | varchar | YES | null | 검수 작업 유형 ('수정', '추가', '삭제') |
| wholesale_revenue | numeric | YES | 0 | 도매 매출액 |
| direct_revenue | numeric | YES | 0 | 직거래 매출액 |
| total_revenue | numeric | YES | 0 | 총 매출액 |
| absorption_rate | numeric | YES | 0 | 흡수율 (%) |

#### 1.3. `performance_evidence_files` (실적 증빙 파일)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | uuid | NO | gen_random_uuid() | 파일 고유 ID (PK) |
| company_id | uuid | YES | null | 업체 ID (FK → companies.id) |
| client_id | bigint | YES | null | 거래처 ID (FK → clients.id) |
| settlement_month | text | NO | null | 정산월 |
| file_name | text | NO | null | 원본 파일명 |
| file_path | text | NO | null | Supabase Storage 내 파일 경로 |
| file_size | bigint | YES | null | 파일 크기 (bytes) |
| uploaded_by | uuid | YES | null | 업로드한 사용자 (FK → auth.users.id) |
| uploaded_at | timestamp | YES | now() | 업로드 시각 |
| created_at | timestamp | YES | now() | 생성 시각 |

### 2. 마스터 데이터 테이블

#### 2.1. `companies` (업체 정보)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | uuid | NO | gen_random_uuid() | 업체 고유 ID (PK) |
| user_id | uuid | YES | null | 사용자 ID (FK → auth.users.id) |
| company_name | text | NO | null | 업체명 |
| business_registration_number | text | NO | null | 사업자등록번호 |
| representative_name | text | NO | null | 대표자명 |
| business_address | text | NO | null | 사업장 주소 |
| landline_phone | text | YES | null | 대표전화 |
| contact_person_name | text | NO | null | 담당자명 |
| mobile_phone | text | NO | null | 휴대폰번호 |
| mobile_phone_2 | text | YES | null | 휴대폰번호2 |
| email | text | NO | null | 이메일 |
| default_commission_grade | text | NO | 'A' | 기본 수수료 등급 |
| remarks | text | YES | null | 비고 |
| approval_status | text | NO | 'pending' | 승인 상태 ('pending', 'approved', 'rejected') |
| status | text | NO | 'active' | 상태 ('active', 'inactive') |
| user_type | text | NO | 'user' | 사용자 유형 ('admin', 'user') |
| company_group | text | YES | null | 업체 그룹 |
| assigned_pharmacist_contact | text | YES | null | 담당 약사 연락처 |
| receive_email | text | YES | null | 수신 이메일 |
| created_by | uuid | YES | null | 생성자 ID (FK → auth.users.id) |
| approved_at | timestamptz | YES | now() | 승인 시각 |
| updated_by | uuid | YES | null | 수정자 ID (FK → auth.users.id) |
| created_at | timestamptz | NO | now() | 생성 시각 |
| updated_at | timestamptz | YES | now() | 수정 시각 |

#### 2.2. `clients` (거래처 정보)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | bigint | NO | nextval('clients_id_seq') | 거래처 고유 ID (PK) |
| client_code | text | YES | null | 거래처 코드 |
| name | text | NO | null | 거래처명 |
| business_registration_number | text | NO | null | 사업자등록번호 |
| owner_name | text | YES | null | 대표자명 |
| address | text | YES | null | 주소 |
| remarks | text | YES | null | 비고 |
| status | text | NO | 'active' | 상태 ('active', 'inactive') |
| created_at | timestamptz | YES | now() | 생성 시각 |
| updated_at | timestamptz | YES | now() | 수정 시각 |
| created_by | uuid | YES | null | 생성자 ID (FK → auth.users.id) |
| updated_by | uuid | YES | null | 수정자 ID (FK → auth.users.id) |
| remarks_settlement | text | YES | null | 정산 관련 비고 |

#### 2.3. `products` (제품 정보)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | uuid | NO | gen_random_uuid() | 제품 고유 ID (PK) |
| product_name | text | NO | null | 제품명 |
| insurance_code | text | YES | null | 보험코드 |
| price | integer | YES | null | 약가 |
| commission_rate_a | numeric | NO | null | A등급 수수료율 |
| commission_rate_b | numeric | NO | null | B등급 수수료율 |
| commission_rate_c | numeric | YES | null | C등급 수수료율 |
| commission_rate_d | numeric | YES | 0 | D등급 수수료율 |
| commission_rate_e | numeric | YES | 0 | E등급 수수료율 |
| standard_code | text | NO | null | 표준코드 |
| unit_packaging_desc | text | YES | null | 단위포장 설명 |
| unit_quantity | integer | YES | null | 단위 수량 |
| remarks | text | YES | null | 비고 |
| status | text | NO | 'active' | 상태 ('active', 'inactive') |
| base_month | text | NO | null | 기준월 |
| created_at | timestamptz | NO | now() | 생성 시각 |
| updated_at | timestamptz | YES | now() | 수정 시각 |
| created_by | uuid | NO | null | 생성자 ID (FK → auth.users.id) |
| updated_by | uuid | YES | null | 수정자 ID (FK → auth.users.id) |

#### 2.4. `pharmacies` (약국 정보)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | bigint | NO | nextval('pharmacies_id_seq') | 약국 고유 ID (PK) |
| pharmacy_code | text | YES | null | 약국 코드 |
| name | text | NO | null | 약국명 |
| business_registration_number | text | NO | null | 사업자등록번호 |
| address | text | YES | null | 주소 |
| remarks | text | YES | null | 비고 |
| status | text | NO | 'active' | 상태 ('active', 'inactive') |
| created_at | timestamptz | NO | now() | 생성 시각 |
| updated_at | timestamptz | YES | now() | 수정 시각 |
| created_by | uuid | NO | null | 생성자 ID (FK → auth.users.id) |
| updated_by | uuid | YES | null | 수정자 ID (FK → auth.users.id) |

#### 2.5. `settlement_months` (정산월 관리)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | bigint | NO | nextval('settlement_months_id_seq') | 정산월 고유 ID (PK) |
| settlement_month | varchar | NO | null | 정산월 (예: '2025-01') |
| start_date | date | NO | null | 실적입력 시작일 |
| end_date | date | NO | null | 실적입력 종료일 |
| notice | text | YES | null | 전달 사항 |
| status | varchar | NO | 'active' | 상태 ('active', 'inactive') |
| remarks | text | YES | null | 비고 |
| created_at | timestamptz | NO | now() | 생성 시각 |
| created_by | uuid | NO | null | 생성자 ID (FK → auth.users.id) |
| updated_by | uuid | YES | null | 수정자 ID (FK → auth.users.id) |
| updated_at | timestamptz | YES | null | 수정 시각 |

### 3. 매핑 테이블

#### 3.1. `client_company_assignments` (거래처-업체 매핑)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | bigint | NO | nextval('client_company_assignments_id_seq') | 매핑 고유 ID (PK) |
| client_id | bigint | YES | null | 거래처 ID (FK → clients.id) |
| company_id | uuid | YES | null | 업체 ID (FK → companies.id) |
| created_at | timestamptz | YES | now() | 생성 시각 |
| company_default_commission_grade | text | YES | 'A' | 업체 기본 수수료 등급 |
| modified_commission_grade | text | YES | null | 수정된 수수료 등급 |
| created_by | uuid | YES | null | 생성자 ID (FK → auth.users.id) |

#### 3.2. `client_pharmacy_assignments` (거래처-약국 매핑)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | bigint | NO | null | 매핑 고유 ID (PK) |
| client_id | bigint | NO | null | 거래처 ID (FK → clients.id) |
| pharmacy_id | bigint | NO | null | 약국 ID (FK → pharmacies.id) |
| created_at | timestamptz | YES | now() | 생성 시각 |

### 4. 매출 데이터 테이블

#### 4.1. `wholesale_sales` (도매 매출 데이터)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | bigint | NO | nextval('wholesale_sales_id_seq') | 매출 고유 ID (PK) |
| pharmacy_code | text | YES | null | 약국 코드 |
| pharmacy_name | text | YES | null | 약국명 |
| business_registration_number | text | NO | null | 사업자등록번호 |
| address | text | YES | null | 주소 |
| standard_code | text | NO | null | 표준코드 |
| product_name | text | YES | null | 제품명 |
| sales_amount | numeric | YES | null | 매출액 |
| sales_date | date | YES | null | 매출일 |
| created_at | timestamptz | YES | now() | 생성 시각 |
| updated_at | timestamptz | YES | now() | 수정 시각 |
| created_by | text | YES | null | 생성자 |
| updated_by | text | YES | null | 수정자 |

#### 4.2. `direct_sales` (직거래 매출 데이터)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | bigint | NO | nextval('direct_sales_id_seq') | 매출 고유 ID (PK) |
| pharmacy_code | text | YES | null | 약국 코드 |
| pharmacy_name | text | YES | null | 약국명 |
| business_registration_number | text | NO | null | 사업자등록번호 |
| address | text | YES | null | 주소 |
| standard_code | text | NO | null | 표준코드 |
| product_name | text | YES | null | 제품명 |
| sales_amount | numeric | YES | null | 매출액 |
| sales_date | date | YES | null | 매출일 |
| created_at | timestamptz | YES | now() | 생성 시각 |
| updated_at | timestamptz | YES | now() | 수정 시각 |
| created_by | text | YES | null | 생성자 |
| updated_by | text | YES | null | 수정자 |

### 5. 시스템 관리 테이블

#### 5.1. `notices` (공지사항)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | uuid | NO | gen_random_uuid() | 공지사항 고유 ID (PK) |
| title | text | NO | null | 제목 |
| content | text | NO | null | 내용 |
| is_pinned | boolean | NO | false | 상단 고정 여부 |
| view_count | integer | NO | 0 | 조회수 |
| created_by | uuid | NO | null | 작성자 ID (FK → auth.users.id) |
| created_at | timestamptz | NO | now() | 작성 시각 |
| updated_at | timestamptz | YES | null | 수정 시각 |
| file_url | text | YES | null | 첨부 파일 URL |
| links | text | YES | null | 외부 링크 |
| updated_by | uuid | YES | null | 수정자 ID (FK → auth.users.id) |

#### 5.2. `notice_views` (공지사항 조회 이력)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | uuid | NO | gen_random_uuid() | 조회 이력 고유 ID (PK) |
| notice_id | uuid | NO | null | 공지사항 ID (FK → notices.id) |
| user_id | uuid | NO | null | 사용자 ID (FK → auth.users.id) |
| viewed_at | timestamptz | YES | now() | 조회 시각 |

#### 5.3. `settlement_share` (정산내역서 공유 설정)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | bigint | NO | null | 공유 설정 고유 ID (PK) |
| settlement_month | text | NO | null | 정산월 |
| company_id | uuid | NO | gen_random_uuid() | 업체 ID (FK → companies.id) |
| share_enabled | boolean | NO | null | 공유 활성화 여부 |
| created_at | timestamptz | NO | now() | 생성 시각 |

---

## 🔗 테이블 관계도

```
auth.users (1) ──── (N) companies
                    │
                    │ (1) ──── (N) performance_records
                    │                    │
                    │                    │ (1) ──── (1) performance_records_absorption
                    │                    │
                    │ (1) ──── (N) performance_evidence_files
                    │
                    │ (N) ──── (N) clients (through client_company_assignments)
                    │
                    │ (N) ──── (N) pharmacies (through client_pharmacy_assignments)

clients (N) ──── (N) pharmacies (through client_pharmacy_assignments)

products (1) ──── (N) performance_records
products (1) ──── (N) performance_records_absorption

notices (1) ──── (N) notice_views
```

---

## 📝 주요 특징

### 1. 데이터 무결성 보장
- 모든 테이블에 `created_at`, `updated_at` 타임스탬프 필드 포함
- 외래키 제약조건으로 참조 무결성 보장
- UUID와 BigInt를 적절히 활용한 ID 체계

### 2. 감사 추적 (Audit Trail)
- `created_by`, `updated_by` 필드로 변경 이력 추적
- `review_status`, `review_action` 필드로 검수 과정 기록
- `performance_records_absorption` 테이블로 모든 변경사항 이력화

### 3. 권한 관리
- `user_type` 필드로 관리자/일반 사용자 구분
- `approval_status` 필드로 업체 승인 상태 관리
- `status` 필드로 데이터 활성/비활성 상태 관리

### 4. 성능 최적화
- 적절한 인덱스 설정 (기본키, 외래키)
- 정규화된 테이블 구조로 데이터 중복 최소화
- 뷰(View)를 통한 복잡한 조인 쿼리 최적화

---

## 🔧 인덱스 전략

### 1. 기본 인덱스
- 모든 테이블의 `id` 필드 (기본키)
- 외래키 필드들 (`company_id`, `client_id`, `product_id` 등)

### 2. 성능 최적화 인덱스
- `performance_records`: `(settlement_month, review_status)`
- `performance_records_absorption`: `(settlement_month, review_status)`
- `companies`: `(user_type, approval_status)`
- `products`: `(base_month, status)`

### 3. 복합 인덱스
- `performance_records`: `(company_id, settlement_month, review_status)`
- `performance_records_absorption`: `(company_id, settlement_month, review_status)`

---

## 📊 데이터 타입별 분류

### UUID 타입
- `companies.id`
- `products.id`
- `notices.id`
- `notice_views.id`
- `performance_evidence_files.id`

### BigInt 타입
- `performance_records.id`
- `performance_records_absorption.id`
- `clients.id`
- `pharmacies.id`
- `settlement_months.id`
- `settlement_share.id`
- `wholesale_sales.id`
- `direct_sales.id`

### Text 타입
- 대부분의 문자열 필드
- 상태값들 (`status`, `review_status`, `user_type` 등)

### Numeric 타입
- 금액 관련 필드 (`sales_amount`, `prescription_qty` 등)
- 비율 관련 필드 (`commission_rate`, `absorption_rate` 등)

### Timestamp 타입
- `created_at`, `updated_at` 필드들
- 날짜 관련 필드 (`sales_date`, `start_date`, `end_date` 등)

---

## 🎯 테이블별 주요 용도

| 테이블명 | 주요 용도 | 핵심 기능 |
|----------|-----------|-----------|
| `performance_records` | 실적 데이터 원본 저장 | 사용자 실적 입력, 검수 대기 |
| `performance_records_absorption` | 검수 및 분석 데이터 | 관리자 검수, 흡수율 분석 |
| `companies` | 업체 정보 관리 | 사용자 계정 연동, 권한 관리 |
| `clients` | 거래처 정보 관리 | 병의원 정보 관리 |
| `products` | 제품 정보 관리 | 약가, 수수료율 관리 |
| `pharmacies` | 약국 정보 관리 | 매출 데이터 연결 |
| `settlement_months` | 정산월 관리 | 실적입력기간 제어 |
| `notices` | 공지사항 관리 | 시스템 공지, 파일 첨부 |
| `wholesale_sales` | 도매 매출 데이터 | 흡수율 분석용 |
| `direct_sales` | 직거래 매출 데이터 | 흡수율 분석용 | 