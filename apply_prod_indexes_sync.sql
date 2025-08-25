-- 운영서버 인덱스 동기화 스크립트
-- 운영서버: vaeolqywqckiwwtspxfp
-- 목적: 개발서버와 동일한 인덱스 상태로 동기화

-- =====================================================
-- 1. performance_records 테이블 인덱스 추가
-- =====================================================

-- 1-1. settlement_month 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_performance_records_settlement_month 
ON performance_records (settlement_month);

-- 1-2. client_id 인덱스 추가 (기존 인덱스와 동일한 컬럼)
-- 기존: idx_performance_records_client (client_id)
-- 추가: idx_performance_records_client_id (client_id) - 동일한 컬럼이므로 생략

-- 1-3. company_id 인덱스 추가 (기존 인덱스와 동일한 컬럼)
-- 기존: idx_performance_records_company_settlement (company_id, settlement_month)
-- 추가: idx_performance_records_company_id (company_id) - 동일한 컬럼이므로 생략

-- 1-4. product_id 인덱스 추가 (기존 인덱스와 동일한 컬럼)
-- 기존: idx_performance_records_product (product_id)
-- 추가: idx_performance_records_product_id (product_id) - 동일한 컬럼이므로 생략

-- =====================================================
-- 2. performance_records_absorption 테이블 인덱스 추가
-- =====================================================

-- 2-1. product_id 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_performance_records_absorption_product_id 
ON performance_records_absorption (product_id);

-- =====================================================
-- 3. product_company_not_assignments 테이블 인덱스 추가
-- =====================================================

-- 3-1. company_id 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_product_company_not_assignments_company_id 
ON product_company_not_assignments (company_id);

-- 3-2. product_id 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_product_company_not_assignments_product_id 
ON product_company_not_assignments (product_id);

-- 3-3. product_company 복합 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_product_company_not_assignments_product_company 
ON product_company_not_assignments (product_id, company_id);

-- 3-4. 기존 인덱스들 추가 (중복 방지)
CREATE INDEX IF NOT EXISTS idx_product_company_assignments_company_id 
ON product_company_not_assignments (company_id);

CREATE INDEX IF NOT EXISTS idx_product_company_assignments_product_id 
ON product_company_not_assignments (product_id);

-- 3-5. 복합 유니크 제약조건 인덱스 추가
CREATE UNIQUE INDEX IF NOT EXISTS product_company_assignments_product_id_company_id_key 
ON product_company_not_assignments (product_id, company_id);

-- =====================================================
-- 4. pharmacies 테이블 인덱스 추가
-- =====================================================

-- 4-1. business_registration_number 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_pharmacies_business_registration_number 
ON pharmacies (business_registration_number);

-- =====================================================
-- 5. 인덱스 생성 확인
-- =====================================================

-- 5-1. performance_records 인덱스 확인
SELECT 
    'Performance Records Indexes Applied' as info,
    i.relname as index_name,
    pg_get_indexdef(i.oid) as index_definition
FROM pg_index x
JOIN pg_class c ON c.oid = x.indrelid
JOIN pg_class i ON i.oid = x.indexrelid
WHERE c.relname = 'performance_records'
  AND NOT x.indisprimary
ORDER BY i.relname;

-- 5-2. performance_records_absorption 인덱스 확인
SELECT 
    'Performance Records Absorption Indexes Applied' as info,
    i.relname as index_name,
    pg_get_indexdef(i.oid) as index_definition
FROM pg_index x
JOIN pg_class c ON c.oid = x.indrelid
JOIN pg_class i ON i.oid = x.indexrelid
WHERE c.relname = 'performance_records_absorption'
  AND NOT x.indisprimary
ORDER BY i.relname;

-- 5-3. product_company_not_assignments 인덱스 확인
SELECT 
    'Product Company Not Assignments Indexes Applied' as info,
    i.relname as index_name,
    pg_get_indexdef(i.oid) as index_definition
FROM pg_index x
JOIN pg_class c ON c.oid = x.indrelid
JOIN pg_class i ON i.oid = x.indexrelid
WHERE c.relname = 'product_company_not_assignments'
  AND NOT x.indisprimary
ORDER BY i.relname;

-- 5-4. pharmacies 인덱스 확인
SELECT 
    'Pharmacies Indexes Applied' as info,
    i.relname as index_name,
    pg_get_indexdef(i.oid) as index_definition
FROM pg_index x
JOIN pg_class c ON c.oid = x.indrelid
JOIN pg_class i ON i.oid = x.indexrelid
WHERE c.relname = 'pharmacies'
  AND NOT x.indisprimary
ORDER BY i.relname;

-- 5-5. 전체 인덱스 요약 재확인
SELECT 
    'Updated Index Summary' as info,
    c.relname as table_name,
    COUNT(i.relname) as index_count,
    STRING_AGG(i.relname, ', ' ORDER BY i.relname) as index_names
FROM pg_index x
JOIN pg_class c ON c.oid = x.indrelid
JOIN pg_class i ON i.oid = x.indexrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind = 'r'
  AND c.relname IN (
    'performance_records',
    'performance_records_absorption',
    'product_company_not_assignments',
    'pharmacies'
  )
  AND NOT x.indisprimary
GROUP BY c.relname
ORDER BY c.relname;
