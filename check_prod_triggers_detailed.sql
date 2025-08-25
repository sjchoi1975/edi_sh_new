-- 운영서버 트리거 상세 상태 확인
-- 운영서버: vaeolqywqckiwwtspxfp

-- 1. 모든 테이블의 트리거 목록 확인
SELECT 
    'All Triggers' as info,
    n.nspname as schema_name,
    c.relname as table_name,
    t.tgname as trigger_name,
    p.proname as function_name,
    t.tgtype as trigger_type,
    CASE 
        WHEN t.tgtype & 66 = 2 THEN 'BEFORE'
        WHEN t.tgtype & 66 = 64 THEN 'AFTER'
        ELSE 'INSTEAD OF'
    END as timing,
    CASE 
        WHEN t.tgtype & 28 = 4 THEN 'INSERT'
        WHEN t.tgtype & 28 = 8 THEN 'DELETE'
        WHEN t.tgtype & 28 = 16 THEN 'UPDATE'
        WHEN t.tgtype & 28 = 12 THEN 'INSERT OR DELETE'
        WHEN t.tgtype & 28 = 20 THEN 'INSERT OR UPDATE'
        WHEN t.tgtype & 28 = 24 THEN 'DELETE OR UPDATE'
        WHEN t.tgtype & 28 = 28 THEN 'INSERT OR DELETE OR UPDATE'
        ELSE 'UNKNOWN'
    END as events
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE n.nspname NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
  AND NOT t.tgisinternal
ORDER BY n.nspname, c.relname, t.tgname;

-- 2. 주요 테이블별 트리거 확인
SELECT 
    'Performance Records Triggers' as info,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'performance_records'
ORDER BY trigger_name;

SELECT 
    'Products Standard Code Triggers' as info,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'products_standard_code'
ORDER BY trigger_name;

SELECT 
    'Product Company Assignments Triggers' as info,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'product_company_assignments'
ORDER BY trigger_name;

SELECT 
    'Pharmacies Triggers' as info,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'pharmacies'
ORDER BY trigger_name;

SELECT 
    'Settlement Months Triggers' as info,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'settlement_months'
ORDER BY trigger_name;

-- 3. 트리거 함수 상세 정보
SELECT 
    'Trigger Functions' as info,
    routine_name,
    routine_type,
    data_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name IN (
    'prevent_updated_fields_on_review_status_change',
    'update_products_standard_code_updated_fields',
    'update_product_company_assignments_updated_at',
    'update_pharmacies_updated_fields',
    'update_settlement_months_updated_fields'
)
ORDER BY routine_name;
