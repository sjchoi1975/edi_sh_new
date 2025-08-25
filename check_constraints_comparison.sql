-- 제약조건 동기화 확인 스크립트
-- 양쪽 서버에서 동일하게 실행하여 결과 비교

-- =====================================================
-- 1. 외래키 제약조건 확인
-- =====================================================

SELECT 
    'Foreign Key Constraints' as info,
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    pc.confdeltype AS delete_rule,
    pc.confupdtype AS update_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
JOIN pg_constraint pc ON pc.conname = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
    AND tc.table_name IN (
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
ORDER BY tc.table_name, tc.constraint_name;

-- =====================================================
-- 2. 유니크 제약조건 확인
-- =====================================================

SELECT 
    'Unique Constraints' as info,
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    tc.constraint_type
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'UNIQUE'
    AND tc.table_schema = 'public'
    AND tc.table_name IN (
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
ORDER BY tc.table_name, tc.constraint_name;

-- =====================================================
-- 3. 체크 제약조건 확인
-- =====================================================

SELECT 
    'Check Constraints' as info,
    tc.constraint_name,
    tc.table_name,
    cc.check_clause
FROM information_schema.table_constraints AS tc
JOIN information_schema.check_constraints AS cc
    ON tc.constraint_name = cc.constraint_name
WHERE tc.constraint_type = 'CHECK'
    AND tc.table_schema = 'public'
    AND tc.table_name IN (
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
ORDER BY tc.table_name, tc.constraint_name;

-- =====================================================
-- 4. NOT NULL 제약조건 확인
-- =====================================================

SELECT 
    'NOT NULL Constraints' as info,
    table_name,
    column_name,
    is_nullable,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
    AND is_nullable = 'NO'
    AND table_name IN (
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
ORDER BY table_name, column_name;

-- =====================================================
-- 5. 제약조건 통계 요약
-- =====================================================

SELECT 
    'Constraints Summary by Table' as info,
    tc.table_name,
    COUNT(CASE WHEN tc.constraint_type = 'FOREIGN KEY' THEN 1 END) as foreign_keys,
    COUNT(CASE WHEN tc.constraint_type = 'UNIQUE' THEN 1 END) as unique_constraints,
    COUNT(CASE WHEN tc.constraint_type = 'CHECK' THEN 1 END) as check_constraints,
    COUNT(CASE WHEN tc.constraint_type = 'PRIMARY KEY' THEN 1 END) as primary_keys
FROM information_schema.table_constraints tc
WHERE tc.table_schema = 'public'
    AND tc.table_name IN (
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
GROUP BY tc.table_name
ORDER BY tc.table_name;
