-- 운영서버 상태 확인 스크립트
-- 운영서버: vaeolqywqckiwwtspxfp

-- 1. 데이터베이스 함수 목록 확인
SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments,
    pg_get_function_result(p.oid) as return_type,
    p.prosrc as source_code
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
  AND p.prosrc IS NOT NULL
ORDER BY n.nspname, p.proname;

-- 2. 뷰 목록 확인
SELECT 
    schemaname as schema_name,
    viewname as view_name,
    definition as view_definition
FROM pg_views
WHERE schemaname NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
ORDER BY schemaname, viewname;

-- 3. 트리거 목록 확인
SELECT 
    n.nspname as schema_name,
    t.tgname as trigger_name,
    c.relname as table_name,
    p.proname as function_name
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE n.nspname NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
  AND NOT t.tgisinternal
ORDER BY n.nspname, c.relname, t.tgname;

-- 4. 인덱스 목록 확인
SELECT 
    n.nspname as schema_name,
    c.relname as table_name,
    i.relname as index_name,
    pg_get_indexdef(i.oid) as index_definition
FROM pg_index x
JOIN pg_class c ON c.oid = x.indrelid
JOIN pg_class i ON i.oid = x.indexrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
  AND c.relkind = 'r'
ORDER BY n.nspname, c.relname, i.relname;
