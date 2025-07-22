# 신일 PMS 주요 기능 및 핵심 로직 (v3.0)

**문서 버전: 3.0 (2025-07-22)**

## 1. 개요

본 문서는 신일 PMS의 핵심 기능인 '실적 검수', '흡수율 분석', '정산내역서 공유'의 상세한 동작 방식과 내부 로직을 설명합니다. 각 기능은 데이터베이스의 뷰(View)와 함수(RPC)를 적극적으로 활용하여 프론트엔드의 복잡성을 낮추고, 시스템 전체의 안정성과 일관성을 확보하는 방향으로 설계되었습니다.

---

## 2. 실적 검수 (`AdminPerformanceReviewView.vue`)

관리자가 사용자의 실적을 검수하고 확정하는 가장 중요하고 복잡한 기능입니다. 모든 데이터 변경 이력은 이 화면에서 발생하며, 프론트엔드는 사용자의 인터랙션을 `performance_records_absorption` 테이블의 변경 이력으로 변환하는 역할을 수행합니다.

### 2.1. 주요 상태 변수 (State Variables)

-   `loading` (ref): 데이터 로딩 상태를 제어하는 boolean. API 호출 시 `true`로 설정되어 로딩 인디케이터를 표시.
-   `displayRows` (ref): 화면의 데이터 테이블에 실제로 표시되는 데이터 배열.
-   `selectedRows` (ref): 사용자가 체크박스를 통해 선택한 행들의 데이터 배열.
-   `isAnyEditing` (computed): 현재 편집 중인 행이 하나라도 있는지 여부를 계산하는 boolean. 편집 중일 때는 다른 액션 버튼들을 비활성화하는 데 사용됨.
-   `fieldRefs`, `productInputRefs`: 인라인 편집 시 각 입력 필드(input, select)에 대한 참조(reference)를 저장하여, 키보드 네비게이션 등으로 직접 포커스를 제어하는 데 사용.

### 2.2. 데이터 조회 및 필터링 (`loadPerformanceData`)

-   **역할**: 필터 조건에 맞는 데이터를 조회하여 `displayRows`에 채워 넣는 메인 함수.
-   **동작 순서**:
    1.  필터링의 기준이 되는 `performance_records` 테이블을 직접 조회합니다.
    2.  `selectedSettlementMonth`, `selectedCompanyId`, `selectedHospitalId` 등 UI 필터 값을 바탕으로 `WHERE` 조건을 동적으로 추가합니다.
    3.  `selectedReviewStatus` 값에 따라 분기 처리됩니다.
        -   `'신규'`: '대기' 상태의 실적을 '검수중'으로 전환시킨 후, '검수중' 상태의 데이터를 조회합니다.
        -   `'전체'`: 마찬가지로 '대기' 상태 데이터를 '검수중'으로 전환한 후, 상태 조건 없이 모든 데이터를 조회합니다.
    4.  조회된 데이터를 `map()`을 통해 순회하며, 화면 표시에 필요한 형식(예: 숫자 포맷팅)으로 가공합니다.
    5.  가공된 데이터를 정해진 규칙(상태 > 작업 > 업체명 순)에 따라 `sort()`하고 최종적으로 `displayRows.value`에 할당합니다.

### 2.3. 데이터 동기화 (`syncNewRecordsToAnalysis`)

-   **역할**: 사용자가 입력한 '대기' 상태의 실적을 관리자가 검수할 수 있도록 `performance_records_absorption` 테이블로 가져오는 핵심 백그라운드 작업.
-   **상세 로직**:
    1.  `performance_records` 테이블에서 현재 선택된 '정산월'에 해당하는 `'대기'` 상태의 실적을 모두 `select` 합니다.
    2.  찾아낸 실적들의 데이터를 기반으로 `performance_records_absorption` 테이블에 삽입(INSERT)할 레코드 객체 배열을 생성합니다.
    3.  **가장 중요한 부분**: 이 때, 관리자가 직접 추가한 데이터와 구분하기 위해 `company_id_add`와 `client_id_add` 필드의 값을 **반드시 `NULL`로 명시**하여 삽입합니다. `review_status`는 '검수중'으로 설정합니다.
    4.  준비된 레코드 목록을 `performance_records_absorption`에 `insert`합니다.
    5.  성공적으로 삽입되면, 원본 실적의 `review_status`를 '대기'에서 **'검수중'**으로 `update`하여 중복해서 불러오는 것을 방지합니다.

### 2.4. 인라인 수정 및 저장 (`saveEdit`)

-   **역할**: 사용자가 수정한 내용을 데이터베이스에 저장하는 함수. `isNewRow` 플래그로 수정과 추가 로직을 분기합니다.
-   **수정 로직 (`isNewRow === false`)**:
    1.  사용자가 수정한 값들(처방월, 제품, 수량 등)을 모아 `recordData` 객체를 생성합니다. 이 객체에는 **`..._modify`** 필드들만 포함됩니다.
    2.  `review_action` 필드를 **'수정'**으로 설정하여 변경 이력을 남깁니다.
    3.  **핵심**: 이 로직에서는 `company_id_add`나 `client_id_add` 필드를 **절대 건드리지 않습니다.** 따라서 `NULL` 상태가 유지됩니다.
    4.  `supabase.from('performance_records_absorption').update(recordData).eq('id', row.id)`를 호출하여 DB를 업데이트합니다.
-   **추가 로직 (`isNewRow === true`)**:
    1.  `review_action` 필드를 **'추가'**로 설정하여 신규 데이터임을 명시합니다.
    2.  **핵심**: `company_id_add`와 `client_id_add` 필드에 **기준이 되었던 바로 위 행의 업체 ID (`row.company_id`)와 거래처 ID (`row.client_id`)**를 저장합니다.
    3.  나머지 수정된 정보(`..._modify` 필드)와 함께 `supabase.from('performance_records_absorption').insert(recordData)`를 호출하여 DB에 삽입합니다.

---

## 3. 흡수율 분석 (`AdminAbsorptionAnalysisView.vue`)

-   **역할**: 검수가 완료된 데이터를 기준으로, 제품별 처방액 대비 실제 매출(도매+직거래)의 비율을 분석합니다.
-   **핵심 로직**:
    -   프론트엔드에서는 복잡한 계산을 수행하지 않고, **`calculate_absorption_rates`** 라는 데이터베이스 함수(RPC)를 호출합니다.
    -   **`calculate_absorption_rates` 함수의 역할**:
        1.  `settlement_month`를 인자로 받습니다.
        2.  해당 월의 모든 '완료'된 실적(`review_status` = '완료')을 조회합니다.
        3.  각 실적의 `client_id`와 `product_id`를 기준으로, 관련된 도매/직거래 매출 테이블에서 해당 월의 매출 데이터를 찾아 합산합니다.
        4.  `(합산된 매출액 / 처방액) * 100` 공식을 통해 흡수율(%)을 계산합니다.
        5.  `performance_records_absorption`의 `id`와 계산된 결과를 함께 반환합니다.
    -   프론트엔드는 이 함수가 반환한 계산 결과를 기존에 `displayRows`에 있던 데이터와 `id` 기준으로 매핑하여 '합산액', '흡수율' 열을 업데이트합니다.

---

## 4. 정산내역서 공유 (`AdminSettlementShareView.vue`)

-   **역할**: 검수가 끝난 최종 실적을 **업체별로 합산**하여 보여주고, 각 업체에게 해당 내역을 공유할지 여부를 설정합니다.
-   **핵심 로직**:
    1.  **데이터 조회 (`loadSettlementData`)**:
        -   이 함수는 **`get_settlement_summary_by_company`** 라는 전용 데이터베이스 함수(RPC)를 호출하는 것이 전부입니다. 다른 프론트엔드 계산 로직이 전혀 없습니다.
    2.  **`get_settlement_summary_by_company` 함수의 내부 동작**:
        -   `performance_records_absorption`에서 특정 '정산월'과 `review_status`가 '완료'인 데이터를 모두 조회합니다.
        -   **`GROUP BY company_id`** 구문을 사용하여, 다른 어떤 필드에도 방해받지 않고 오직 **업체 ID를 기준으로** 모든 데이터를 완벽하게 합산합니다.
        -   합산 항목: `COUNT(DISTINCT client_id)`로 병의원 수를, `COUNT(*)`로 처방 건수를, `SUM()`으로 총 처방액/지급액을 계산합니다.
        -   `company_name` 등 그룹화되지 않은 다른 문자열 필드는 `MAX()` 집계 함수를 사용하여 대표값을 선택합니다. (업체 ID가 동일하면 이 값들은 모두 동일하므로 어떤 집계 함수든 무방합니다.)
        -   `settlement_share` 테이블과 `LEFT JOIN` 하여 현재 공유 상태까지 가져와 최종 결과를 한 번의 쿼리로 반환합니다.
    3.  **공유 상태 저장 (`saveShareStatus`)**:
        -   사용자가 체크박스를 변경하면, 변경된 내용(`company_id`, `is_shared`, `settlement_share_id`)만 `shareChanges` 객체에 추적됩니다.
        -   '저장' 버튼을 누르면, `shareChanges`에 기록된 업체들만 `settlement_share` 테이블에 `INSERT` (기존 공유 기록이 없던 업체) 또는 `UPDATE` (기존 공유 기록이 있던 업체)를 수행하여 불필요한 DB 접근을 최소화합니다.
    4.  **기대 효과**: 모든 계산과 그룹화가 데이터베이스 안에서 완벽하게 처리되므로, 프론트엔드 코드는 극적으로 단순해졌고 데이터 정합성 오류가 발생할 가능성이 원천적으로 차단되었습니다.

---

## 5. Database Functions 상세 분석

### 5.1. 핵심 비즈니스 로직 함수들

#### `calculate_absorption_rates(p_settlement_month text)`
```sql
-- Returns: TABLE(analysis_id bigint, wholesale_revenue numeric, direct_revenue numeric)
-- Security: Invoker
```
- **목적**: 흡수율 분석을 실행하고, 각 실적별로 연결된 도매/직거래 매출액을 계산
- **핵심 로직**:
  1. `review_details_view`에서 '완료' 상태의 실적 데이터 조회
  2. 병원-약국 매핑 정보를 통한 약국 연결
  3. 도매/직거래 매출 데이터와 매칭하여 매출액 계산
  4. 약국별 병원 수에 따른 매출 분배 로직 적용

#### `get_settlement_summary_by_company(p_settlement_month text)`
```sql
-- Returns: TABLE(company_id, company_name, client_count, total_records, total_prescription_amount, total_payment_amount, is_shared, settlement_share_id)
-- Security: DEFINER
```
- **목적**: 정산내역서 공유용 업체별 합산 데이터 조회
- **핵심 로직**:
  1. `performance_records_absorption`에서 '완료' 상태 데이터 조회
  2. 업체별로 GROUP BY하여 합산 계산
  3. `settlement_share` 테이블과 JOIN하여 공유 상태 포함

### 5.2. 변경사항 감지 함수들

#### `check_for_updates(p_settlement_month text)`
```sql
-- Returns: JSON
-- Security: Invoker
```
- **목적**: 정산월별 변경사항 확인 (검수, 매핑, 매출 데이터 변경)
- **반환 데이터**:
  ```json
  {
    "updated_reviews": 0,
    "updated_mappings": 0,
    "updated_sales": 0,
    "has_changes": false
  }
  ```

#### `check_performance_changes(p_settlement_month text)`
```sql
-- Returns: jsonb
-- Security: Invoker
```
- **목적**: 실적 데이터 변경사항 확인 (추가, 수정, 삭제 건수)
- **반환 데이터**:
  ```json
  {
    "added_count": 0,
    "modified_count": 0,
    "deleted_count": 0
  }
  ```

### 5.3. 데이터 조회 함수들

#### `get_absorption_analysis_details(p_settlement_month, p_company_id, p_client_id)`
```sql
-- Returns: TABLE(id, company_name, client_name, prescription_month, product_name, prescription_qty, prescription_amount, commission_rate, payment_amount, remarks, created_at, created_by)
-- Security: Invoker
```
- **목적**: 흡수율 분석 화면의 상세 데이터 조회
- **필터링**: 정산월, 업체, 거래처별 필터링 지원

#### `get_distinct_companies_from_analysis(p_settlement_month)`
```sql
-- Returns: TABLE(id uuid, company_name text)
-- Security: Invoker
```
- **목적**: 업체 필터 목록 조회
- **로직**: '완료' 상태 실적에 연결된 모든 업체 중복 제거

### 5.4. 디버깅 함수들

#### `debug_absorption_rates(p_settlement_month text)`
```sql
-- Returns: TABLE(absorption_analysis_id, pharmacy_brn_from_prescription, standard_code_from_prescription, month_from_prescription, brn_from_sales, standard_code_from_sales, month_from_sales, sales_amount)
-- Security: Invoker
```
- **목적**: 흡수율 분석 디버깅용 (상세 매칭 정보)
- **용도**: 매출 데이터 매칭 과정에서 발생하는 문제 진단

#### `debug_distribution_ratios(p_settlement_month text)`
```sql
-- Returns: TABLE(absorption_analysis_id, company_name, client_name, product_name, pharmacy_brn, prescription_qty, total_group_qty, distribution_ratio)
-- Security: Invoker
```
- **목적**: 분배 비율 디버깅용
- **용도**: 약국별 매출 분배 로직 검증

---

## 6. 최신 RLS 정책 (Row Level Security)

### 6.1. 핵심 정책 개요

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

### 6.2. 권한 관리 체계

- **`user_type`**: 'admin' 또는 'user'로 구분
- **`approval_status`**: 'pending', 'approved', 'rejected'로 업체 승인 상태 관리
- **`status`**: 'active', 'inactive'로 데이터 활성 상태 관리

---

## 7. 파일 업로드 시스템

### 7.1. 실적 증빙 파일 (`performance_evidence_files`)

- **저장 위치**: Supabase Storage
- **접근 권한**: 업체별로 자신의 파일만 관리 가능
- **파일 정보**: 파일명, 경로, 크기, 업로드자, 업로드 시각 추적

### 7.2. 공지사항 첨부 파일

- **파일 URL**: `notices.file_url` 필드에 저장
- **링크 정보**: `notices.links` 필드에 외부 링크 저장
- **관리 권한**: 관리자만 파일 업로드/관리 가능 