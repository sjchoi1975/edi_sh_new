-- 현재 트리거 상태 확인

-- 1. performance_records 테이블의 모든 트리거 확인
SELECT 
    'All Triggers on performance_records' as info,
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'performance_records'
ORDER BY trigger_name;

-- 2. 특정 트리거 상세 정보 확인
SELECT 
    'Specific Trigger Details' as info,
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing,
    action_statement,
    action_orientation,
    action_condition
FROM information_schema.triggers 
WHERE trigger_name = 'prevent_updated_fields_on_review_status_change';

-- 3. 트리거 함수 확인
SELECT 
    'Trigger Function' as info,
    routine_name,
    routine_type,
    data_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'prevent_updated_fields_on_review_status_change';

-- 4. 테이블 구조 확인 (updated_at 컬럼)
SELECT 
    'Table Structure' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'performance_records' 
AND column_name IN ('updated_at', 'updated_by', 'review_status')
ORDER BY column_name; 