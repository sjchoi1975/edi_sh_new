-- 트리거 동기화 최종 확인 스크립트
-- 양쪽 서버에서 동일하게 실행하여 결과 비교

-- =====================================================
-- 1. 주요 테이블별 트리거 상태 확인
-- =====================================================

-- 1-1. performance_records 테이블 트리거
SELECT 
    'Performance Records Triggers' as info,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'performance_records'
ORDER BY trigger_name;

-- 1-2. products_standard_code 테이블 트리거
SELECT 
    'Products Standard Code Triggers' as info,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'products_standard_code'
ORDER BY trigger_name;

-- 1-3. product_company_not_assignments 테이블 트리거
SELECT 
    'Product Company Not Assignments Triggers' as info,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'product_company_not_assignments'
ORDER BY trigger_name;

-- 1-4. settlement_months 테이블 트리거
SELECT 
    'Settlement Months Triggers' as info,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'settlement_months'
ORDER BY trigger_name;

-- =====================================================
-- 2. 전체 트리거 목록 (핵심 테이블만)
-- =====================================================

SELECT 
    'Core Tables Triggers Summary' as info,
    c.relname as table_name,
    COUNT(t.tgname) as trigger_count,
    STRING_AGG(t.tgname, ', ' ORDER BY t.tgname) as trigger_names
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public'
  AND NOT t.tgisinternal
  AND c.relname IN (
    'performance_records',
    'products_standard_code', 
    'product_company_not_assignments',
    'settlement_months',
    'companies',
    'products',
    'clients',
    'pharmacies'
  )
GROUP BY c.relname
ORDER BY c.relname;

-- =====================================================
-- 3. 트리거 함수 존재 확인
-- =====================================================

SELECT 
    'Trigger Functions Status' as info,
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name IN (
    'prevent_updated_fields_on_review_status_change',
    'update_products_standard_code_updated_fields',
    'update_product_company_not_assignments_updated_at',
    'update_settlement_months_updated_at_column'
)
ORDER BY routine_name;
