-- 개발서버 함수와 뷰 상태 확인
-- 개발서버: selklngerzfmuvagcvvf

-- 1. 데이터베이스 함수 목록 확인
SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments,
    pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
  AND p.prosrc IS NOT NULL
ORDER BY n.nspname, p.proname;

-- 2. 뷰 목록 확인
SELECT 
    schemaname as schema_name,
    viewname as view_name
FROM pg_views
WHERE schemaname NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
ORDER BY schemaname, viewname;

-- 3. 특정 함수 상세 확인 (흡수율 분석 함수)
SELECT 
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments,
    pg_get_function_result(p.oid) as return_type,
    p.prosrc as source_code
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
  AND p.proname = 'calculate_absorption_rates';

-- 4. 특정 뷰 상세 확인 (리뷰 상세 뷰)
SELECT 
    viewname as view_name,
    definition as view_definition
FROM pg_views
WHERE schemaname = 'public' 
  AND viewname = 'review_details_view';
