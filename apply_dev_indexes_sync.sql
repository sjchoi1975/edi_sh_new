-- 개발서버 인덱스 동기화 스크립트
-- 개발서버: selklngerzfmuvagcvvf
-- 목적: 운영서버와 동일한 인덱스 상태로 동기화

-- =====================================================
-- 1. companies 테이블 인덱스 추가
-- =====================================================

-- 1-1. email 유니크 인덱스 추가
CREATE UNIQUE INDEX IF NOT EXISTS companies_email_key 
ON companies (email);

-- 1-2. user_id 유니크 인덱스 추가
CREATE UNIQUE INDEX IF NOT EXISTS companies_user_id_key 
ON companies (user_id);

-- =====================================================
-- 2. performance_records 테이블 인덱스 추가
-- =====================================================

-- 2-1. prescription_month 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_performance_records_prescription_month 
ON performance_records (prescription_month);

-- 2-2. registered_by 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_performance_records_registered_by 
ON performance_records (registered_by);

-- =====================================================
-- 3. 인덱스 생성 확인
-- =====================================================

-- 3-1. companies 인덱스 확인
SELECT 
    'Companies Indexes Applied' as info,
    i.relname as index_name,
    pg_get_indexdef(i.oid) as index_definition
FROM pg_index x
JOIN pg_class c ON c.oid = x.indrelid
JOIN pg_class i ON i.oid = x.indexrelid
WHERE c.relname = 'companies'
  AND NOT x.indisprimary
ORDER BY i.relname;

-- 3-2. performance_records 인덱스 확인
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

-- 3-3. 전체 인덱스 요약 재확인
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
    'companies',
    'performance_records'
  )
  AND NOT x.indisprimary
GROUP BY c.relname
ORDER BY c.relname;
