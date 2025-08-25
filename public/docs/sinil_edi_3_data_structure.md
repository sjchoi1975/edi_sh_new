# 신일제약 실적관리 시스템 데이터 구조 상세 (v3.3)

**문서 버전: 3.4 (2025-01-07)**

## 1. 개요

본 문서는 신일제약 실적관리 시스템의 **데이터베이스 구조와 테이블 관계를 상세히 기술**합니다. 핵심 테이블의 설계 원칙, 데이터 흐름, 그리고 Row Level Security (RLS) 정책을 포함합니다.

**참고**: 주요 기능과 관련된 상세 내용은 `sinil_edi_2_main_features.md`를 참조하세요.

## 2. 데이터 흐름 및 설계 원칙

본 문서는 신일제약 실적관리 시스템의 핵심 데이터 구조, 테이블 간의 관계, 그리고 데이터 흐름의 중심이 되는 뷰(`View`)에 대해 상세히 기술합니다. 시스템의 모든 데이터 처리는 이 구조를 기반으로 이루어지므로, 유지보수 및 기능 확장 시 반드시 본 문서를 참고해야 합니다. 데이터 모델은 **원본 데이터의 불변성**을 유지하고, **관리자의 모든 변경 행위를 추적** 가능하게 하는 것에 중점을 두고 설계되었습니다.

---

## 2. 데이터 흐름도 (Lifecycle of Data)

하나의 실적 데이터가 생성되어 최종 정산되기까지의 여정은 다음과 같습니다.

```
(사용자)                        (관리자)
   |                              |
[1. 실적 입력] ------------> [2. 데이터 로드 & 동기화] -------> [3. 검수 진행 (수정/추가/삭제)] ----> [4. 검수 완료] ----> [5. 데이터 활용]
   | (performance_records)      | (performance_records_absorption) | (performance_records_absorption)   | (상태값 변경)         | (review_details_view)
   | - review_status: '대기'    | - pr.status -> '검수중'         | - review_action 기록               | - status -> '완료'    | - 흡수율 분석
   |                            | - pra.status -> '검수중'        | - _modify, _add 필드에 값 저장      |                       | - 정산내역서 공유
   |                            | - _add 필드 -> NULL로 초기화     |                                   |                       |
```

---

## 3. 테이블 관계도 (Text-based ERD)

```
[auth.users] 1--* [performance_records] 1--1 [performance_records_absorption] *--1 [companies]
   |                                            |                        |
   *--1 [companies] (user_id)                   *--1 [clients]           *--1 [clients]
                                                *--1 [products]
```

-   `1--*` : 일대다 (One-to-Many)
-   `1--1` : 일대일 (One-to-One)

---

## 4. 주요 테이블 상세 정의

### 4.1. `performance_records` (사용자 실적 원본 테이블)

-   **역할**: 사용자가 입력하는 모든 실적 데이터의 **원본(Raw Data)** 을 저장하는 가장 기초적인 테이블입니다.
-   **특징**: 이 테이블의 데이터는 **절대 직접 수정되거나 삭제되지 않습니다.**
-   **컬럼 정의**:
    -   `id` (bigint, PK): 레코드 고유 ID.
    -   `company_id` (uuid, FK -> `companies.id`): 실적의 주체인 업체 정보.
    -   `settlement_month` (varchar): 정산월 정보.
    -   `prescription_month` (varchar): 처방월 정보.
    -   `client_id` (bigint, FK -> `clients.id`): 관련 거래처 정보.
    -   `product_id` (uuid, FK -> `products.id`): 관련 제품 정보.
    -   `prescription_qty` (numeric): 처방 수량.
    -   `prescription_type` (varchar): 처방 유형 ('EDI' 기본값).
    -   `remarks` (text): 비고.
    -   `registered_by` (uuid, FK -> `auth.users.id`): 실적을 입력한 사용자 정보.
    -   `created_at`, `updated_at` (timestamptz): 생성/수정 시각.
    -   `review_status` (text): 레코드의 검수 상태 ('대기', '검수중', '완료'). 데이터 흐름을 제어하는 핵심 필드.
    -   `review_action` (text): 검수 작업 유형 ('수정', '추가', '삭제'). 삭제된 건은 '삭제'로 표시되며, 처방액과 지급액이 0으로 처리됨.
    -   `updated_by` (uuid, FK -> `auth.users.id`): 수정자 정보.
    -   `commission_rate` (numeric): 수수료율.

### 4.2. `performance_records_absorption` (관리자 검수 및 분석용 테이블)

-   **역할**: 관리자의 모든 검수 작업(수정, 추가, 삭제)의 **결과와 이력을 기록**하는 시스템의 핵심 운영 테이블입니다.
-   **컬럼 정의**:
    -   `id` (bigint, PK): 검수 레코드 고유 ID.
    -   `created_at` (timestamptz): 생성 시각.
    -   `settlement_month` (varchar): 정산월.
    -   `company_id` (uuid, FK -> `companies.id`): 업체 ID.
    -   `client_id` (bigint, FK -> `clients.id`): 거래처 ID.
    -   `product_id` (uuid, FK -> `products.id`): 제품 ID.
    -   `prescription_month` (varchar): 처방월.
    -   `prescription_qty` (numeric): 처방 수량.
    -   `prescription_type` (varchar): 처방 유형.
    -   `commission_rate` (numeric): 수수료율.
    -   `remarks` (text): 비고.
    -   `registered_by` (uuid, FK -> `auth.users.id`): 등록자.
    -   `updated_at` (timestamptz): 수정 시각.
    -   `updated_by` (uuid, FK -> `auth.users.id`): 수정자.
    -   `review_action` (varchar): 관리자의 작업 유형 (`'수정'`, `'추가'`, `'삭제'`). 수정/추가/삭제 시 자동으로 `review_status`가 '완료'로 변경됨.
    -   `wholesale_revenue` (numeric): 도매 매출액 (0 기본값).
    -   `direct_revenue` (numeric): 직거래 매출액 (0 기본값).
    -   `total_revenue` (numeric): 총 매출액 (0 기본값).
    -   `absorption_rate` (numeric): 흡수율 (0 기본값).
    -   `analysis_time` (timestamptz): 흡수율 분석 데이터 복사 시점의 시간. 재분석 필요성 체크의 기준으로 사용됨.

### 4.3. 마스터 테이블

-   **`companies`**: 
    -   `id` (uuid, PK), `user_id` (uuid, FK -> `auth.users.id`)
    -   `company_name`, `business_registration_number`, `representative_name`
    -   `business_address`, `landline_phone`, `contact_person_name`, `mobile_phone`, `mobile_phone_2`
    -   `email`, `default_commission_grade` (text, 'A' 기본값), `remarks`
    -   `approval_status` (text, 'pending' 기본값), `status` (text, 'active' 기본값)
    -   `user_type` (text, 'user' 기본값), `company_group` (text)
    -   `assigned_pharmacist_contact`, `receive_email` (text)
    -   `created_by`, `approved_at`, `updated_by` (uuid, FK -> `auth.users.id`)
    -   `created_at`, `updated_at` (timestamptz)
    -   **RLS 정책**: 관리자 전체 접근, 일반 사용자는 자신의 업체만 접근

-   **`clients`**: 
    -   `id` (bigint, PK), `client_code` (text)
    -   `name`, `business_registration_number`, `owner_name`, `address`, `remarks`
    -   `status` (text, 'active' 기본값)
    -   `created_at`, `updated_at` (timestamptz)
    -   `created_by`, `updated_by` (uuid, FK -> `auth.users.id`)
    -   `remarks_settlement` (text): 정산 관련 비고

-   **`products`**: 
    -   `id` (uuid, PK), `product_name`, `insurance_code`, `price` (integer)
    -   `commission_rate_a`, `commission_rate_b`, `commission_rate_c` (numeric)
    -   `commission_rate_d`, `commission_rate_e` (numeric, 0 기본값)
    -   `remarks`, `status` (text, 'active' 기본값)
    -   `base_month` (text), `created_at`, `updated_at` (timestamptz)
    -   `created_by`, `updated_by` (uuid, FK -> `auth.users.id`)
    -   **RLS 정책**: 관리자 전체 접근, 일반 사용자는 활성 제품만 조회

-   **`pharmacies`**: 
    -   `id` (bigint, PK), `pharmacy_code` (text)
    -   `name`, `business_registration_number`, `address`, `remarks`
    -   `status` (text, 'active' 기본값)
    -   `created_at`, `updated_at` (timestamptz)
    -   `created_by`, `updated_by` (uuid, FK -> `auth.users.id`)

-   **`settlement_months`**: 
    -   `id` (bigint, PK), `settlement_month` (varchar)
    -   `start_date`, `end_date` (date), `notice` (text)
    -   `status` (varchar, 'active' 기본값), `remarks` (text)
    -   `created_at` (timestamptz)
    -   `created_by`, `updated_by` (uuid, FK -> `auth.users.id`)
    -   `updated_at` (timestamptz)
    -   `notice_payment` (text): 지급 관련 전달 사항
    -   **RLS 정책**: 모든 인증된 사용자가 조회 가능

-   **`settlement_share`**: 
    -   `id` (bigint, PK), `settlement_month` (text)
    -   `company_id` (uuid, FK -> `companies.id`)
    -   `share_enabled` (boolean), `created_at` (timestamptz)
    -   `notice_individual` (text): 개별 업체 전달 사항
    -   **RLS 정책**: 인증된 사용자는 모든 작업 가능

### 4.4. 매핑 테이블

-   **`client_company_assignments`**: 
    -   `id` (bigint, PK), `client_id` (bigint, FK -> `clients.id`)
    -   `company_id` (uuid, FK -> `companies.id`)
    -   `created_at` (timestamptz)
    -   `company_default_commission_grade` (text, 'A' 기본값)
    -   `modified_commission_grade` (text)
    -   `created_by` (uuid, FK -> `auth.users.id`)

-   **`client_pharmacy_assignments`**: 
    -   `id` (bigint, PK), `client_id` (bigint, FK -> `clients.id`)
    -   `pharmacy_id` (bigint, FK -> `pharmacies.id`)
    -   `created_at` (timestamptz)

-   **`product_company_not_assignments`**: 
    -   `id` (bigint, PK), `product_id` (uuid, FK -> `products.id`)
    -   `company_id` (uuid, FK -> `companies.id`)
    -   `created_at`, `updated_at` (timestamptz)
    -   `created_by`, `updated_by` (uuid, FK -> `auth.users.id`)

### 4.5. 매출 데이터 테이블

-   **`wholesale_sales`**: 
    -   `id` (bigint, PK), `pharmacy_code`, `pharmacy_name`
    -   `business_registration_number`, `address`, `standard_code`
    -   `product_name`, `sales_amount` (numeric), `sales_date` (date)
    -   `created_at`, `updated_at` (timestamptz)
    -   `created_by`, `updated_by` (text)

-   **`direct_sales`**: 
    -   `id` (bigint, PK), `pharmacy_code`, `pharmacy_name`
    -   `business_registration_number`, `address`, `standard_code`
    -   `product_name`, `sales_amount` (numeric), `sales_date` (date)
    -   `created_at`, `updated_at` (timestamptz)
    -   `created_by`, `updated_by` (text)

### 4.6. 기타 테이블

-   **`notices`**: 
    -   `id` (uuid, PK), `title`, `content`
    -   `is_pinned` (boolean, false 기본값), `view_count` (integer, 0 기본값)
    -   `created_by` (uuid, FK -> `auth.users.id`)
    -   `created_at`, `updated_at` (timestamptz)
    -   `file_url`, `links` (text)
    -   `updated_by` (uuid, FK -> `auth.users.id`)
    -   **RLS 정책**: 관리자만 작성/수정/삭제, 모든 인증된 사용자가 조회

-   **`performance_evidence_files`**: 
    -   `id` (uuid, PK), `company_id` (uuid, FK -> `companies.id`)
    -   `client_id` (bigint, FK -> `clients.id`)
    -   `settlement_month` (text), `file_name`, `file_path`
    -   `file_size` (bigint), `uploaded_by` (uuid, FK -> `auth.users.id`)
    -   `uploaded_at`, `created_at` (timestamp)
    -   **RLS 정책**: 관리자 전체 접근, 일반 사용자는 자신의 업체 파일만 관리

-   **`notice_views`**: 
    -   `id` (uuid, PK), `notice_id` (uuid, FK -> `notices.id`)
    -   `user_id` (uuid, FK -> `auth.users.id`)
    -   `viewed_at` (timestamptz, now() 기본값)
    -   **용도**: 공지사항 조회 이력 추적

-   **`products_standard_code`**: 
    -   `id` (bigint, PK), `insurance_code` (text)
    -   `standard_code` (text), `unit_packaging_desc` (text)
    -   `unit_quantity` (integer), `remarks` (text, '' 기본값)
    -   `status` (text, 'active' 기본값)
    -   `created_at`, `updated_at` (timestamptz)
    -   `created_by`, `updated_by` (uuid, FK -> `auth.users.id`)

-   **`user_preferences`**: 
    -   `id` (integer, PK), `user_id` (uuid, FK -> `auth.users.id`)
    -   `preference_key` (varchar), `created_at` (timestamptz)
    -   `settlement_month_id` (integer)
    -   **RLS 정책**: 사용자는 자신의 설정만 관리

---

## 5. 핵심 데이터 뷰 (View): `review_details_view`

`review_details_view`는 시스템의 **데이터 조회 로직을 극적으로 단순화**시키는 가장 중요한 가상 테이블입니다.

### 5.1. View의 SQL 구조 (실제 코드)

```sql
CREATE OR REPLACE VIEW public.review_details_view AS
WITH analysis_base AS (
    SELECT
        aa.id AS absorption_analysis_id,
        aa.performance_record_id,
        aa.review_status,
        aa.review_action,
        pr.user_edit_status,
        -- 등록자 ID 결정 (관리자가 추가했으면 관리자 ID, 아니면 원본 등록자 ID)
        COALESCE(aa.registered_add_by, pr.registered_by) AS final_registered_by_id,
        aa.update_by, -- 수정자 ID
        COALESCE(aa.company_id_add, pr.company_id) AS final_company_id,
        COALESCE(aa.client_id_add, pr.client_id) AS final_client_id,
        COALESCE(aa.product_id_modify, pr.product_id) AS final_product_id,
        COALESCE(aa.prescription_month_modify, pr.prescription_month) AS prescription_month,
        COALESCE(aa.prescription_qty_modify, pr.prescription_qty) AS prescription_qty,
        COALESCE(aa.prescription_type_modify, (pr.prescription_type)::text) AS prescription_type,
        COALESCE(aa.remarks_modify, pr.remarks) AS remarks,
        aa.commission_rate_modify,
        -- 날짜 결정 (관리자 추가일 우선)
        COALESCE(aa.created_add_at, pr.created_at) AS final_created_at,
        COALESCE(aa.settlement_month_add, pr.settlement_month) AS final_settlement_month,
        aa.updated_at
    FROM absorption_analysis aa
    LEFT JOIN performance_records pr ON aa.performance_record_id = pr.id
)
SELECT
    ab.absorption_analysis_id,
    ab.performance_record_id,
    ab.review_status,
    ab.review_action,
    ab.user_edit_status,
    ab.final_company_id AS company_id,
    ab.final_client_id AS client_id,
    ab.final_product_id AS product_id,
    ab.prescription_month,
    ab.prescription_qty,
    ab.prescription_type,
    ab.remarks,
    ab.final_created_at AS created_at,
    ab.final_settlement_month AS settlement_month,
    ab.updated_at,
    -- 최종 등록자 이름 결정 로직 수정
    CASE
        WHEN registrant.role = 'admin' THEN registrant.contact_person_name
        ELSE registrant.company_name
    END AS registered_by_name,
    updater.contact_person_name AS updated_by_name, -- 수정자 이름
    c.company_name,
    c.company_group,
    c.business_registration_number,
    c.representative_name,
    c.assigned_pharmacist_contact AS manager_name,
    cl.name AS client_name,
    p.product_name AS product_name_display,
    p.insurance_code,
    p.price,
    (ab.prescription_qty * p.price) AS prescription_amount,
    COALESCE(
        ab.commission_rate_modify,
        CASE
            WHEN c.default_commission_grade = 'B' THEN p.commission_rate_b
            ELSE p.commission_rate_a
        END
    ) AS commission_rate
FROM analysis_base ab
-- 이름 조인을 위한 조인
LEFT JOIN companies registrant ON ab.final_registered_by_id = registrant.user_id
LEFT JOIN companies updater ON ab.update_by = updater.user_id
-- 나머지 데이터 조인
LEFT JOIN companies c ON ab.final_company_id = c.id
LEFT JOIN clients cl ON ab.final_client_id = cl.id
LEFT JOIN products p ON ab.final_product_id = p.id;
```

### 5.2. `COALESCE` 로직의 중요성

`COALESCE`는 "NULL이 아닌 첫 번째 값을 반환하라"는 의미의 SQL 함수입니다. 이 View는 `COALESCE`를 적극적으로 사용하여, 관리자의 수정/추가 이력을 종합하고 **최종적으로 사용해야 할 데이터를 동적으로 결정**합니다.

-   **예시 시나리오**:
    1.  **원본 데이터**: `performance_records`에 `prescription_qty = 100`인 데이터가 있음.
    2.  **수정 발생**: 관리자가 이 데이터를 120으로 수정하면, `performance_records_absorption`에 `prescription_qty_modify = 120`이 저장됨.
    3.  **View 조회**: `COALESCE(aa.prescription_qty_modify, pr.prescription_qty)`는 `aa.prescription_qty_modify`가 `NULL`이 아니므로 **120**을 반환함.
    4.  **수정 미발생**: 만약 수정되지 않았다면, `aa.prescription_qty_modify`는 `NULL`이므로, `COALESCE`는 두 번째 값인 `pr.prescription_qty` 즉, **100**을 반환함.

-   **기대 효과**: 이 패턴 덕분에 프론트엔드는 데이터의 수정 여부나 추가 여부를 전혀 신경 쓸 필요 없이, `review_details_view`의 최종 필드(`prescription_qty`, `company_id` 등)만 조회하면 **항상 올바른 최신 데이터**를 얻을 수 있습니다. 이는 코드의 가독성과 유지보수성을 극대화합니다. 

---

## 7. 최신 추가 테이블 및 기능

### 7.1. 실적 증빙 파일 관리 (`performance_evidence_files`)

**목적**: 실적 데이터의 증빙 자료를 안전하게 저장하고 관리

**컬럼 정의**:
- `id` (uuid, PK): 파일 고유 ID
- `company_id` (uuid, FK -> `companies.id`): 업체 ID
- `client_id` (bigint, FK -> `clients.id`): 거래처 ID
- `settlement_month` (text): 정산월
- `file_name` (text): 원본 파일명
- `file_path` (text): Supabase Storage 내 파일 경로
- `file_size` (bigint): 파일 크기 (bytes)
- `uploaded_by` (uuid, FK -> `auth.users.id`): 업로드한 사용자
- `uploaded_at` (timestamp): 업로드 시각
- `created_at` (timestamp): 생성 시각

**특징**:
- Supabase Storage를 활용한 안전한 파일 저장
- 업체별 접근 권한 제어 (RLS 정책)
- 파일 메타데이터 추적으로 관리 효율성 향상

### 7.2. 실적입력기간 관리 (`settlement_months` 확장)

**기존 컬럼에 추가된 기능**:
- `start_date` (date): 실적입력 시작일
- `end_date` (date): 실적입력 종료일
- `notice` (text): 전달 사항
- `status` (varchar, 'active' 기본값): 활성/비활성 상태

**핵심 기능**:
- **일반 사용자**: 실적입력기간 내에서만 실적 등록/수정 가능
- **관리자**: 실적입력기간과 무관하게 언제든지 실적 등록/수정 가능
- **UI 제어**: 기간 외에는 모든 입력 버튼 비활성화

### 7.3. 사용자 편집 상태 추적 (`performance_records` 확장)

**추가된 컬럼**:
- `user_edit_status` (text): 사용자 편집 상태
- `updated_by` (uuid, FK -> `auth.users.id`): 수정자 정보
- `updated_at` (timestamptz): 수정 시각

**상태 값**:
- `'editable'`: 편집 가능
- `'locked'`: 편집 불가 (검수중/완료)
- `'pending'`: 대기 중

### 7.4. 제품 정보 월별 관리 (`products` 확장)

**핵심 기능**:
- **월별 제품 정보**: `base_month` 필드로 월별 제품 정보 관리
- **보험코드 유니크**: 같은 보험코드의 제품은 월별로 하나만 유지
- **자동 업데이트**: 처방월 변경 시 제품 정보 자동 업데이트

**데이터 무결성**:
- 보험코드 기준 유니크 처리로 중복 방지
- 월별 제품 정보 캐싱으로 성능 최적화
- 제품 정보 변경 시 실적 데이터 자동 반영

### 7.5. 키보드 네비게이션 상태 관리

**프론트엔드 상태 변수**:
- `currentCell` (ref): 현재 포커스된 셀 정보 `{ row: number, col: string }`
- `fieldRefs` (ref): 각 입력 필드의 DOM 참조
- `productInputRefs` (ref): 제품명 입력 필드의 DOM 참조

**키보드 이벤트 처리**:
- **전역 이벤트**: document 레벨에서 키보드 이벤트 처리
- **조건부 처리**: 편집 가능한 상태에서만 키보드 기능 활성화
- **충돌 방지**: 제품 검색 중 특정 키 차단

### 7.6. 제품 검색 시스템 상태 관리

**상태 변수**:
- `productSearchForRow` (ref): 제품 검색 상태
  - `query`: 검색 쿼리
  - `results`: 검색 결과 배열
  - `selectedIndex`: 선택된 항목 인덱스
  - `show`: 드롭다운 표시 여부
  - `activeRowIndex`: 활성 행 인덱스

**캐싱 시스템**:
- `productsByMonth` (ref): 월별 제품 목록 캐시
- `productDropdownStyle` (ref): 드롭다운 위치 스타일

### 7.7. 실시간 검증 시스템

**입력 검증 규칙**:
- **제품명**: 제품 선택 필수 (자동완성 지원)
- **처방수량**: 숫자만 입력 가능, 0보다 큰 값
- **처방액**: 자동 계산, 수정 불가
- **필수 필드**: 제품명 + 처방수량 조합 필수

**실시간 피드백**:
- **처방액 계산**: 수량 입력 시 즉시 계산
- **제품 정보 업데이트**: 처방월 변경 시 자동 업데이트
- **상태 표시**: 검수상태별 색상 구분

### 7.8. 정렬 규칙 시스템

**사용자별 정렬 규칙**:
- **일반 사용자**: 처방건수 0건 → 1건 이상 (입력된 것이 아래로)
- **관리자**: 처방건수 0건 → 1건 이상 (입력된 것이 위로)
- **실적 검수**: 검수상태별 정렬 (신규 → 검수중 → 완료)

**정렬 로직**:
- **가나다순**: `localeCompare()` 메서드 사용
- **상태별 그룹화**: 조건에 따라 그룹별로 분리 후 정렬
- **실시간 정렬**: computed 속성으로 실시간 정렬

### 7.9. 상태별 편집 권한 시스템

**권한 규칙**:
- **일반 사용자**: '대기' 상태만 편집 가능
- **관리자**: 모든 상태 편집 가능
- **상태별 UI**: 편집 불가 상태의 시각적 표시

**구현 방식**:
- `isRowEditable()` 함수로 행별 편집 가능 여부 판단
- `isInputEnabled` ref로 전체 편집 상태 제어
- 키보드 이벤트 조건부 처리

### 7.10. 성능 최적화 시스템

**제품 데이터 캐싱**:
- **월별 캐시**: `productsByMonth` 객체로 월별 제품 목록 캐시
- **중복 제거**: 보험코드 기준 유니크 처리
- **지연 로딩**: 필요한 월의 제품만 로드

**키보드 이벤트 최적화**:
- **전역 이벤트**: document 레벨에서 키보드 이벤트 처리
- **조건부 처리**: 편집 가능한 상태에서만 키보드 기능 활성화
- **충돌 방지**: 제품 검색 중 특정 키 차단

### 7.11. 전체 등록 현황 시스템 (`AdminPerformanceWholeView.vue`)

**목적**: 모든 업체의 실적 데이터를 통합 조회하고 관리

**핵심 기능**:
- **통합 조회**: 모든 업체의 실적 데이터를 한 화면에서 조회
- **고급 필터링**: 정산월, 처방월, 업체, 병의원, 검수상태별 필터링
- **대용량 데이터 처리**: 페이지네이션과 스크롤을 통한 효율적인 데이터 표시
- **엑셀 다운로드**: 필터링된 데이터를 엑셀 형식으로 내보내기

**데이터 구조**:
- `displayRows` (ref): 화면에 표시되는 데이터 배열
- `selectedSettlementMonth` (ref): 선택된 정산월
- `prescriptionOffset` (ref): 처방월 오프셋 (-1, -2, -3개월)
- `selectedCompanyId` (ref): 선택된 업체 ID
- `selectedHospitalId` (ref): 선택된 병의원 ID
- `selectedReviewStatus` (ref): 선택된 검수상태

**성능 최적화**:
- **페이지네이션**: 100건 단위로 데이터 로딩
- **스크롤 최적화**: 가상 스크롤링으로 대용량 데이터 처리
- **컬럼 고정**: 중요 컬럼(No, 검수, 업체명) 고정으로 사용성 향상

---

## 7. 데이터 흐름 최적화

### 7.1. 제품 정보 자동 업데이트 흐름

```
1. 사용자가 처방월 변경
   ↓
2. 기존 제품의 보험코드로 새 처방월에서 검색
   ↓
3. 검색 결과에 따라 분기:
   - 결과 있음: 새 제품 정보로 자동 업데이트
   - 결과 없음: 제품 선택 해제
   ↓
4. 처방수량이 있으면 처방액 재계산
```

### 7.2. 키보드 네비게이션 흐름

```
1. 사용자가 키보드 입력
   ↓
2. 전역 키보드 이벤트 핸들러에서 처리
   ↓
3. 편집 가능 여부 확인
   ↓
4. 제품 검색 상태 확인
   ↓
5. 적절한 동작 실행:
   - 화살표 키: 셀 간 이동
   - Enter 키: 필드별 특별 동작
   - 특수 키: 행 관리 동작
```

### 7.3. 실시간 검증 흐름

```
1. 사용자가 데이터 입력
   ↓
2. 입력값 실시간 검증
   ↓
3. 검증 결과에 따라 피드백 제공:
   - 성공: 정상 처리
   - 실패: 오류 메시지 표시
   ↓
4. 관련 필드 자동 업데이트 (처방액 계산 등)
```

### 7.4. 상태별 편집 권한 흐름

```
1. 화면 로드 시 사용자 권한 확인
   ↓
2. 실적 데이터의 검수 상태 확인
   ↓
3. 권한과 상태에 따라 편집 가능 여부 결정
   ↓
4. UI 요소 활성화/비활성화
   ↓
5. 키보드 이벤트 조건부 처리
```

이러한 최신 기능들을 통해 신일 PMS는 더욱 효율적이고 사용자 친화적인 실적 관리 시스템으로 발전했습니다. 모든 기능은 데이터 무결성을 보장하면서 사용자 경험을 최적화하는 방향으로 설계되었습니다.

---

## 8. 최신 데이터베이스 테이블 구조 (2025-08-07)

### 8.1. 핵심 실적 관리 테이블

#### 8.1.1. `performance_records` (사용자 실적 원본 테이블)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | bigint | NO | null | 레코드 고유 ID (PK) |
| company_id | uuid | NO | null | 업체 ID (FK → companies.id) |
| settlement_month | varchar | NO | null | 정산월 (예: '2025-01') |
| prescription_month | varchar | NO | null | 처방월 (예: '2024-12') |
| client_id | bigint | NO | null | 거래처 ID (FK → clients.id) |
| product_id | uuid | NO | null | 제품 ID (FK → products.id) |
| prescription_qty | numeric | NO | null | 처방 수량 |
| prescription_type | varchar | NO | 'EDI' | 처방 유형 |
| remarks | text | YES | null | 비고 |
| registered_by | uuid | NO | null | 등록자 ID (FK → auth.users.id) |
| created_at | timestamptz | YES | now() | 생성 시각 |
| updated_at | timestamptz | YES | now() | 수정 시각 |
| review_status | text | YES | '대기' | 검수 상태 ('대기', '검수중', '완료') |
| review_action | text | YES | null | 검수 작업 유형 |
| updated_by | uuid | YES | null | 수정자 ID (FK → auth.users.id) |
| commission_rate | numeric | YES | null | 수수료율 |

#### 8.1.2. `performance_records_absorption` (관리자 검수 및 분석용 테이블)
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

### 8.2. 마스터 데이터 테이블

#### 8.2.1. `companies` (업체 정보)
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
| created_at | timestamptz | NO | now() | 생성 시각 |
| updated_at | timestamptz | YES | now() | 수정 시각 |
| user_type | text | NO | 'user' | 사용자 유형 ('admin', 'user') |
| company_group | text | YES | null | 업체 그룹 |
| assigned_pharmacist_contact | text | YES | null | 담당 약사 연락처 |
| receive_email | text | YES | null | 수신 이메일 |
| created_by | uuid | NO | null | 생성자 ID (FK → auth.users.id) |
| approved_at | timestamptz | YES | now() | 승인 시각 |
| updated_by | uuid | YES | null | 수정자 ID (FK → auth.users.id) |

#### 8.2.2. `clients` (거래처 정보)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | bigint | NO | null | 거래처 고유 ID (PK) |
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

#### 8.2.3. `products` (제품 정보)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | uuid | NO | gen_random_uuid() | 제품 고유 ID (PK) |
| product_name | text | NO | null | 제품명 |
| insurance_code | text | YES | null | 보험코드 |
| price | integer | YES | null | 약가 |
| commission_rate_a | numeric | NO | null | A등급 수수료율 |
| commission_rate_b | numeric | NO | null | B등급 수수료율 |
| commission_rate_c | numeric | YES | null | C등급 수수료율 |
| remarks | text | YES | null | 비고 |
| status | text | NO | 'active' | 상태 ('active', 'inactive') |
| created_at | timestamptz | NO | now() | 생성 시각 |
| updated_at | timestamptz | YES | now() | 수정 시각 |
| base_month | text | NO | null | 기준월 |
| commission_rate_d | numeric | YES | 0 | D등급 수수료율 |
| commission_rate_e | numeric | YES | 0 | E등급 수수료율 |
| created_by | uuid | YES | null | 생성자 ID (FK → auth.users.id) |
| updated_by | uuid | YES | null | 수정자 ID (FK → auth.users.id) |

#### 8.2.4. `settlement_months` (정산월 관리)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | bigint | NO | null | 정산월 고유 ID (PK) |
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
| notice_payment | text | YES | null | 지급 관련 전달 사항 |

### 8.3. 매핑 테이블

#### 8.3.1. `client_company_assignments` (거래처-업체 매핑)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | bigint | NO | null | 매핑 고유 ID (PK) |
| client_id | bigint | YES | null | 거래처 ID (FK → clients.id) |
| company_id | uuid | YES | null | 업체 ID (FK → companies.id) |
| created_at | timestamptz | YES | now() | 생성 시각 |
| company_default_commission_grade | text | YES | 'A' | 업체 기본 수수료 등급 |
| modified_commission_grade | text | YES | null | 수정된 수수료 등급 |
| created_by | uuid | YES | null | 생성자 ID (FK → auth.users.id) |

#### 8.3.2. `product_company_assignments` (제품-업체 비할당)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | bigint | NO | null | 비할당 고유 ID (PK) |
| product_id | uuid | NO | null | 제품 ID (FK → products.id) |
| company_id | uuid | NO | null | 업체 ID (FK → companies.id) |
| created_at | timestamptz | YES | now() | 생성 시각 |
| updated_at | timestamptz | YES | now() | 수정 시각 |
| created_by | uuid | YES | null | 생성자 ID (FK → auth.users.id) |
| updated_by | uuid | YES | null | 수정자 ID (FK → auth.users.id) |

### 8.4. 시스템 관리 테이블

#### 8.4.1. `notices` (공지사항)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | uuid | NO | gen_random_uuid() | 공지사항 고유 ID (PK) |
| title | text | NO | null | 제목 |
| content | text | NO | null | 내용 |
| is_pinned | boolean | NO | false | 상단 고정 여부 |
| view_count | integer | NO | 0 | 조회수 |
| created_by | uuid | YES | null | 작성자 ID (FK → auth.users.id) |
| created_at | timestamptz | NO | now() | 작성 시각 |
| updated_at | timestamptz | YES | null | 수정 시각 |
| file_url | text | YES | null | 첨부 파일 URL |
| links | text | YES | null | 외부 링크 |
| updated_by | uuid | YES | null | 수정자 ID (FK → auth.users.id) |

#### 8.4.2. `products_standard_code` (제품 표준코드)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | bigint | NO | nextval('products_standard_code_id_seq') | 표준코드 고유 ID (PK) |
| insurance_code | text | NO | null | 보험코드 |
| standard_code | text | NO | null | 표준코드 |
| unit_packaging_desc | text | YES | null | 단위포장 설명 |
| unit_quantity | integer | YES | null | 단위 수량 |
| created_at | timestamptz | NO | now() | 생성 시각 |
| updated_at | timestamptz | YES | null | 수정 시각 |
| created_by | uuid | NO | null | 생성자 ID (FK → auth.users.id) |
| updated_by | uuid | YES | null | 수정자 ID (FK → auth.users.id) |
| remarks | text | YES | '' | 비고 |
| status | text | NO | 'active' | 상태 ('active', 'inactive') |

#### 8.4.3. `user_preferences` (사용자 설정)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | integer | NO | nextval('user_preferences_id_seq') | 설정 고유 ID (PK) |
| user_id | uuid | NO | null | 사용자 ID (FK → auth.users.id) |
| preference_key | varchar | NO | null | 설정 키 |
| created_at | timestamptz | YES | now() | 생성 시각 |
| settlement_month_id | integer | NO | null | 정산월 ID |

---

## 9. 최신 RLS 정책 (Row Level Security) - 2025-08-07

### 9.1. 핵심 정책 개요

시스템은 Supabase의 RLS를 활용하여 데이터 접근을 제어합니다:

- **`companies` 테이블**: 
  - 관리자는 모든 업체 데이터 조회 가능
  - 일반 사용자는 자신의 업체 데이터만 조회/수정 가능
  - 회원가입 시 자동으로 업체 정보 생성

- **`performance_records` 테이블**:
  - 관리자는 모든 실적 데이터 접근 가능
  - 일반 사용자는 자신의 업체 실적만 조회/수정 가능

- **`notices` 테이블**:
  - 모든 인증된 사용자가 공지사항 조회 가능
  - 관리자만 공지사항 작성/수정/삭제 가능

- **`products` 테이블**:
  - 모든 인증된 사용자가 활성 제품 조회 가능
  - 관리자만 제품 관리 가능

- **`performance_evidence_files` 테이블**:
  - 관리자는 모든 증빙 파일 접근 가능
  - 일반 사용자는 자신의 업체 파일만 관리 가능

- **`settlement_months` 테이블**:
  - 모든 인증된 사용자가 정산월 조회 가능

- **`settlement_share` 테이블**:
  - 인증된 사용자는 모든 작업 가능

- **`user_preferences` 테이블**:
  - 사용자는 자신의 설정만 관리 가능

### 9.2. 상세 RLS 정책

#### 9.2.1. `companies` 테이블 정책
| 정책명 | 권한 | 역할 | 조건 | 설명 |
|--------|------|------|------|------|
| Admin can read all company data via user_metadata | SELECT | authenticated | `user_metadata.user_type = 'admin'` | 관리자는 모든 업체 데이터 조회 가능 |
| Allow admin to insert company data via user_metadata | INSERT | authenticated | - | 관리자는 업체 데이터 생성 가능 |
| Allow admin to update all company data | UPDATE | authenticated | `user_type = 'admin'` | 관리자는 모든 업체 데이터 수정 가능 |
| Allow individual user to read their own company data | SELECT | authenticated | `auth.uid() = user_id` | 자신의 업체 데이터만 조회 가능 |
| Allow user to update their own limited company info | UPDATE | authenticated | `auth.uid() = user_id AND user_type = 'user'` | 자신의 업체 정보만 제한적으로 수정 가능 |
| Allow users to insert their own company data upon signup | INSERT | authenticated | `auth.uid() = user_id AND user_type = 'user' AND approval_status = 'pending'` | 회원가입 시 자신의 업체 정보 생성 |
| Allow select for all | SELECT | public | `true` | 모든 사용자가 업체 목록 조회 가능 |

#### 9.2.2. `notices` 테이블 정책
| 정책명 | 권한 | 역할 | 조건 | 설명 |
|--------|------|------|------|------|
| Allow admin to insert notices | INSERT | authenticated | `user_type = 'admin'` | 관리자만 공지사항 작성 가능 |
| Allow admin to update notices | UPDATE | authenticated | `user_type = 'admin'` | 관리자만 공지사항 수정 가능 |
| Allow admin to delete notices | DELETE | authenticated | `user_type = 'admin'` | 관리자만 공지사항 삭제 가능 |
| Allow all authenticated users to read notices | SELECT | authenticated | `true` | 모든 인증된 사용자가 공지사항 조회 가능 |

#### 9.2.3. `performance_records` 테이블 정책
| 정책명 | 권한 | 역할 | 조건 | 설명 |
|--------|------|------|------|------|
| Admins can access all performance records | ALL | public | `user_type = 'admin'` | 관리자는 모든 실적 데이터 접근 가능 |
| Users can view their company performance records | SELECT | public | `company_id IN (SELECT id FROM companies WHERE user_id = auth.uid())` | 자신의 업체 실적만 조회 가능 |
| Users can insert their company performance records | INSERT | public | `company_id IN (SELECT id FROM companies WHERE user_id = auth.uid())` | 자신의 업체 실적만 생성 가능 |
| Users can update their company performance records | UPDATE | public | `company_id IN (SELECT id FROM companies WHERE user_id = auth.uid())` | 자신의 업체 실적만 수정 가능 |
| Users can delete their company performance records | DELETE | public | `company_id IN (SELECT id FROM companies WHERE user_id = auth.uid())` | 자신의 업체 실적만 삭제 가능 |

#### 9.2.4. `products` 테이블 정책
| 정책명 | 권한 | 역할 | 조건 | 설명 |
|--------|------|------|------|------|
| Allow admin to read all products | SELECT | authenticated | `user_type = 'admin'` | 관리자는 모든 제품 조회 가능 |
| Allow admin to insert product data | INSERT | authenticated | `user_type = 'admin'` | 관리자만 제품 생성 가능 |
| Allow admin to update product data | UPDATE | authenticated | `user_type = 'admin'` | 관리자만 제품 수정 가능 |
| Allow admin to delete product data | DELETE | authenticated | `user_type = 'admin'` | 관리자만 제품 삭제 가능 |
| Allow authenticated users to read active products | SELECT | authenticated | `status = 'active'` | 인증된 사용자는 활성 제품만 조회 가능 |

#### 9.2.5. `performance_evidence_files` 테이블 정책
| 정책명 | 권한 | 역할 | 조건 | 설명 |
|--------|------|------|------|------|
| Admin full access to evidence files | ALL | public | `user_metadata.user_type = 'admin'` | 관리자는 모든 증빙 파일 접근 가능 |
| Users can view their company evidence files | SELECT | public | `company_id IN (SELECT id FROM companies WHERE user_id = auth.uid())` | 자신의 업체 증빙 파일만 조회 가능 |
| Users can manage their company evidence files | ALL | public | `company_id IN (SELECT id FROM companies WHERE user_id = auth.uid())` | 자신의 업체 증빙 파일만 관리 가능 |
| Users can insert their company evidence files | INSERT | public | `company_id IN (SELECT id FROM companies WHERE user_id = auth.uid())` | 자신의 업체 증빙 파일만 업로드 가능 |
| Users can delete their company evidence files | DELETE | public | `company_id IN (SELECT id FROM companies WHERE user_id = auth.uid())` | 자신의 업체 증빙 파일만 삭제 가능 |

#### 9.2.6. `user_preferences` 테이블 정책
| 정책명 | 권한 | 역할 | 조건 | 설명 |
|--------|------|------|------|------|
| Users can view own preferences | SELECT | public | `auth.uid() = user_id` | 자신의 설정만 조회 가능 |
| Users can insert own preferences | INSERT | public | `auth.uid() = user_id` | 자신의 설정만 생성 가능 |
| Users can update own preferences | UPDATE | public | `auth.uid() = user_id` | 자신의 설정만 수정 가능 |
| Users can delete own preferences | DELETE | public | `auth.uid() = user_id` | 자신의 설정만 삭제 가능 |

### 9.3. 권한 관리 체계

- **`user_type`**: 'admin' 또는 'user'로 구분
- **`approval_status`**: 'pending', 'approved', 'rejected'로 업체 승인 상태 관리
- **`status`**: 'active', 'inactive'로 데이터 활성 상태 관리
- **JWT 토큰 기반 인증**: Supabase Auth를 통한 안전한 인증
- **업체별 데이터 격리**: 일반 사용자는 자신의 업체 데이터만 접근

### 9.4. 보안 강화 기능

- **JWT 토큰 기반 인증**: Supabase Auth를 통한 안전한 인증
- **세션 관리**: 자동 로그아웃 및 세션 만료 처리
- **감사 추적**: 모든 데이터 변경사항에 대한 이력 추적
- **파일 접근 제어**: 증빙 파일은 업체별로 접근 권한 제어

이러한 최신 기능들을 통해 신일 PMS는 더욱 효율적이고 사용자 친화적인 실적 관리 시스템으로 발전했습니다. 모든 기능은 데이터 무결성을 보장하면서 사용자 경험을 최적화하는 방향으로 설계되었습니다.

---

## 10. 수수료율 관리 테이블

### 10.1. 수수료율 관리 구조

#### 10.1.1. `companies` 테이블 (수수료율 관련 컬럼)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| default_commission_grade | text | NO | 'A' | 업체별 기본 수수료 등급 (A, B, C, D, E) |

#### 10.1.2. `client_company_assignments` 테이블 (수수료율 조정)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| company_default_commission_grade | text | NO | 'A' | 업체 기본 등급의 복사본 (자동 동기화) |
| modified_commission_grade | text | YES | null | 병의원별 개별 수수료 등급 (우선 적용) |

#### 10.1.3. `products` 테이블 (수수료율 정의)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| commission_rate_a | numeric | NO | null | A등급 수수료율 (소수점 형태, 예: 0.45) |
| commission_rate_b | numeric | NO | null | B등급 수수료율 |
| commission_rate_c | numeric | YES | null | C등급 수수료율 |
| commission_rate_d | numeric | YES | 0 | D등급 수수료율 |
| commission_rate_e | numeric | YES | 0 | E등급 수수료율 |

### 10.2. 수수료율 자동 동기화 메커니즘

#### 10.2.1. 동기화 트리거 함수
```sql
CREATE OR REPLACE FUNCTION sync_commission_grade()
RETURNS TRIGGER AS $$
BEGIN
    -- companies.default_commission_grade 변경 시 
    -- 해당 업체와 매핑된 모든 client_company_assignments의 company_default_commission_grade 업데이트
    UPDATE client_company_assignments 
    SET company_default_commission_grade = NEW.default_commission_grade
    WHERE company_id = NEW.id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

#### 10.2.2. 트리거 설정
```sql
CREATE TRIGGER trigger_sync_commission_grade
    AFTER UPDATE OF default_commission_grade ON companies
    FOR EACH ROW
    WHEN (OLD.default_commission_grade IS DISTINCT FROM NEW.default_commission_grade)
    EXECUTE FUNCTION sync_commission_grade();
```

### 10.3. 수수료율 적용 우선순위

1. **`modified_commission_grade`** (병의원별 개별 등급) - 최우선
2. **`company_default_commission_grade`** (업체 기본 등급) - 기본값
3. **`commission_rate_modify`** (검수 시 수정) - 관리자 재조정

---

## 11. 제품-업체 매핑 테이블

### 11.1. 제품 노출 관리 구조

#### 11.1.1. `products` 테이블 (제품 상태)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| status | text | NO | 'active' | 제품 기본 상태 ('active', 'inactive') |

#### 11.1.2. `product_company_assignments` 테이블 (업체별 제품 활성화)
| 컬럼명 | 데이터 타입 | NULL 허용 | 기본값 | 설명 |
|--------|-------------|-----------|--------|------|
| id | bigint | NO | null | 매핑 고유 ID (PK) |
| insurance_code | text | NO | null | 보험코드 (제품과 매핑) |
| company_id | uuid | NO | null | 업체 ID (FK → companies.id) |
| is_active | boolean | NO | true | 업체별 제품 활성/비활성 설정 |
| created_at | timestamptz | YES | now() | 생성 시각 |
| updated_at | timestamptz | YES | now() | 수정 시각 |

### 11.2. 제품 노출 관리 뷰

#### 11.2.1. 관리자용 제품 조회 뷰
```sql
CREATE VIEW admin_products_with_company_status AS
SELECT 
    p.id,
    p.product_name,
    p.insurance_code,
    p.price,
    p.commission_rate_a,
    p.commission_rate_b,
    p.commission_rate_c,
    p.commission_rate_d,
    p.commission_rate_e,
    p.base_month,
    p.status,
    p.created_at,
    p.updated_at,
    p.created_by,
    p.updated_by,
    -- 업체별 활성 상태 정보 (보험코드 기준)
    COALESCE(
        json_agg(
            json_build_object(
                'company_id', c.id,
                'company_name', c.company_name,
                'is_active', pica.is_active,
                'assignment_id', pica.id
            ) ORDER BY c.company_name
        ) FILTER (WHERE c.id IS NOT NULL),
        '[]'::json
    ) as company_assignments,
    -- 활성화된 업체 수 (보험코드 기준, 중복 제거)
    COUNT(DISTINCT pica.company_id) FILTER (WHERE pica.is_active = true) as active_companies_count,
    -- 전체 업체 수 (user 타입만)
    (SELECT COUNT(*) FROM companies WHERE status = 'active' AND user_type = 'user') as total_companies_count
FROM products p
LEFT JOIN product_insurance_code_company_assignments pica ON p.insurance_code = pica.insurance_code
LEFT JOIN companies c ON pica.company_id = c.id
WHERE p.status = 'active'
GROUP BY p.id, p.product_name, p.insurance_code, p.price,
         p.commission_rate_a, p.commission_rate_b, p.commission_rate_c,
         p.commission_rate_d, p.commission_rate_e, p.base_month, p.status,
         p.created_at, p.updated_at, p.created_by, p.updated_by;
```

#### 11.2.2. 사용자용 제품 조회 뷰
```sql
CREATE VIEW user_products AS
SELECT 
    p.id,
    p.product_name,
    p.insurance_code,
    p.price,
    p.commission_rate_a,
    p.commission_rate_b,
    p.commission_rate_c,
    p.commission_rate_d,
    p.commission_rate_e,
    p.base_month,
    p.status,
    p.created_at,
    p.updated_at,
    p.created_by,
    p.updated_by
FROM products p
WHERE p.status = 'active'
  AND EXISTS (
      SELECT 1 FROM product_insurance_code_company_assignments pica
      JOIN companies c ON pica.company_id = c.id
      WHERE pica.insurance_code = p.insurance_code
        AND pica.is_active = true
        AND c.user_id = auth.uid()
  );
```

### 11.3. 제품-업체 할당 관리 함수

#### 11.3.1. 업체별 제품 할당 함수
```sql
CREATE FUNCTION update_product_company_assignments(
    p_product_id uuid,
    p_assignments json
)
RETURNS void AS $$
DECLARE
    assignment json;
BEGIN
    -- 기존 할당 삭제
    DELETE FROM product_company_assignments 
    WHERE insurance_code = (SELECT insurance_code FROM products WHERE id = p_product_id);
    
    -- 새로운 할당 추가
    FOR assignment IN SELECT * FROM json_array_elements(p_assignments)
    LOOP
        INSERT INTO product_company_assignments (
            insurance_code, company_id, is_active
        ) VALUES (
            (SELECT insurance_code FROM products WHERE id = p_product_id),
            (assignment->>'company_id')::uuid,
            (assignment->>'is_active')::boolean
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
```

### 11.4. 제품 노출 제어 메커니즘

- **이중 구조 관리**: 제품 상태(`products.status`)와 업체별 활성화(`product_company_assignments.is_active`)를 독립적으로 관리
- **보험코드 기반 매핑**: 동일한 보험코드의 제품들이 업체별로 일괄 관리
- **권한별 접근 제어**: 관리자는 전체 제품 + 업체별 상태 조회, 사용자는 활성화된 제품만 조회

---

## 12. 참조 문서

- **`sinil_edi_1_develop_summary.md`**: 시스템 개요 및 설계 철학
- **`sinil_edi_2_main_features.md`**: 주요 기능 상세 (메뉴 구조, 화면별 기능)
- **`sinil_edi_4_main_logic.md`**: 주요 로직 상세 (핵심 기능 구현 로직)

각 문서는 상호 연관성을 고려하여 작성되었으며, 중복을 최소화하고 참조 관계를 명확히 표시했습니다.