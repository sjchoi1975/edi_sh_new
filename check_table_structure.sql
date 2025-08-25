-- 운영서버 테이블 구조 확인
-- 운영서버: vaeolqywqckiwwtspxfp

-- =====================================================
-- 1. performance_records_absorption 테이블 구조 확인
-- =====================================================

-- 1-1. 테이블 컬럼 목록
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'performance_records_absorption'
ORDER BY ordinal_position;

-- 1-2. 테이블 제약조건 현황
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
LEFT JOIN information_schema.constraint_column_usage ccu 
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_schema = 'public' 
    AND tc.table_name = 'performance_records_absorption'
ORDER BY tc.constraint_type, tc.constraint_name;

-- 1-3. 테이블 인덱스 확인
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'performance_records_absorption';

-- =====================================================
-- 2. 실제 데이터 샘플 확인
-- =====================================================

-- 2-1. 첫 번째 레코드 구조 확인
SELECT * FROM performance_records_absorption LIMIT 1;

-- 2-2. 컬럼별 NULL이 아닌 값 개수 확인
SELECT 
    'Column Data Count' as info,
    COUNT(*) as total_records
FROM performance_records_absorption;

-- 2-3. 각 컬럼별 NULL이 아닌 값 개수
SELECT 
    'Non-Null Column Counts' as info,
    COUNT(commission_rate) as commission_rate_count,
    COUNT(prescription_qty) as prescription_qty_count,
    COUNT(absorption_rate) as absorption_rate_count,
    COUNT(review_status) as review_status_count,
    COUNT(review_action) as review_action_count
FROM performance_records_absorption;
