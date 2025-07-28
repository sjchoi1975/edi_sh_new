-- updated_at 갱신 문제 디버깅

-- 1. 현재 테이블 구조 확인
SELECT 
    'Table Structure' as info,
    column_name,
    data_type,
    is_nullable,
    column_default,
    is_identity
FROM information_schema.columns 
WHERE table_name = 'performance_records' 
AND column_name IN ('updated_at', 'updated_by', 'review_status')
ORDER BY column_name;

-- 2. 현재 트리거 확인
SELECT 
    'Current Triggers' as info,
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'performance_records';

-- 3. 테스트용 데이터 확인
SELECT 
    'Test Data' as info,
    id,
    review_status,
    updated_at,
    updated_by,
    created_at
FROM performance_records 
WHERE review_status = '대기'
ORDER BY created_at DESC
LIMIT 2;

-- 4. updated_at 컬럼의 기본값 확인
SELECT 
    'Column Default' as info,
    column_name,
    column_default
FROM information_schema.columns 
WHERE table_name = 'performance_records' 
AND column_name = 'updated_at';

-- 5. 테이블의 모든 제약조건 확인
SELECT 
    'Constraints' as info,
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'performance_records'; 