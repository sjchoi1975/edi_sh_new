-- 개발서버 인덱스 상태 확인
-- 개발서버: selklngerzfmuvagcvvf

-- =====================================================
-- 1. 핵심 테이블의 인덱스 목록
-- =====================================================

SELECT 
    'Core Tables Indexes' as info,
    n.nspname as schema_name,
    c.relname as table_name,
    i.relname as index_name,
    pg_get_indexdef(i.oid) as index_definition,
    CASE 
        WHEN x.indisunique THEN 'UNIQUE'
        ELSE 'NON-UNIQUE'
    END as index_type
FROM pg_index x
JOIN pg_class c ON c.oid = x.indrelid
JOIN pg_class i ON i.oid = x.indexrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind = 'r'
  AND c.relname IN (
    'performance_records',
    'performance_records_absorption',
    'companies',
    'products',
    'products_standard_code',
    'product_company_not_assignments',
    'clients',
    'pharmacies',
    'settlement_months',
    'notices',
    'user_preferences'
  )
  AND NOT x.indisprimary
ORDER BY c.relname, i.relname;

-- =====================================================
-- 2. 성능 관련 중요 인덱스 확인
-- =====================================================

-- 2-1. performance_records 테이블 인덱스
SELECT 
    'Performance Records Indexes' as info,
    i.relname as index_name,
    pg_get_indexdef(i.oid) as index_definition
FROM pg_index x
JOIN pg_class c ON c.oid = x.indrelid
JOIN pg_class i ON i.oid = x.indexrelid
WHERE c.relname = 'performance_records'
  AND NOT x.indisprimary
ORDER BY i.relname;

-- 2-2. performance_records_absorption 테이블 인덱스
SELECT 
    'Performance Records Absorption Indexes' as info,
    i.relname as index_name,
    pg_get_indexdef(i.oid) as index_definition
FROM pg_index x
JOIN pg_class c ON c.oid = x.indrelid
JOIN pg_class i ON i.oid = x.indexrelid
WHERE c.relname = 'performance_records_absorption'
  AND NOT x.indisprimary
ORDER BY i.relname;

-- 2-3. products_standard_code 테이블 인덱스
SELECT 
    'Products Standard Code Indexes' as info,
    i.relname as index_name,
    pg_get_indexdef(i.oid) as index_definition
FROM pg_index x
JOIN pg_class c ON c.oid = x.indrelid
JOIN pg_class i ON i.oid = x.indexrelid
WHERE c.relname = 'products_standard_code'
  AND NOT x.indisprimary
ORDER BY i.relname;

-- =====================================================
-- 3. 인덱스 통계 요약
-- =====================================================

SELECT 
    'Index Summary by Table' as info,
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
    'companies',
    'products',
    'products_standard_code',
    'product_company_not_assignments',
    'clients',
    'pharmacies',
    'settlement_months',
    'notices',
    'user_preferences'
  )
  AND NOT x.indisprimary
GROUP BY c.relname
ORDER BY c.relname;
