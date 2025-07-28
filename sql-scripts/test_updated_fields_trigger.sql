-- 트리거 테스트 스크립트
-- 목적: review_status 변경 시 updated_at, updated_by가 갱신되지 않는지 확인

-- 1. 테스트용 샘플 데이터 확인
SELECT 
    'Sample Data for Testing' as info,
    id,
    review_status,
    updated_at,
    updated_by,
    prescription_qty,
    remarks
FROM performance_records 
WHERE review_status IN ('대기', '검수중', '완료')
ORDER BY created_at DESC
LIMIT 5;

-- 2. review_status만 변경하는 테스트
-- 테스트 전 상태 저장
WITH test_record AS (
    SELECT id, review_status, updated_at, updated_by
    FROM performance_records 
    WHERE review_status = '대기'
    LIMIT 1
)
SELECT 
    'Before Update' as status,
    id,
    review_status,
    updated_at,
    updated_by
FROM test_record;

-- 3. review_status 변경 실행 (실제로는 주석 처리하고 수동으로 실행)
/*
UPDATE performance_records 
SET review_status = '검수중'
WHERE id = (SELECT id FROM performance_records WHERE review_status = '대기' LIMIT 1);
*/

-- 4. 변경 후 상태 확인
WITH test_record AS (
    SELECT id, review_status, updated_at, updated_by
    FROM performance_records 
    WHERE review_status = '검수중'
    ORDER BY updated_at DESC
    LIMIT 1
)
SELECT 
    'After Update (review_status only)' as status,
    id,
    review_status,
    updated_at,
    updated_by,
    CASE 
        WHEN updated_at = (SELECT updated_at FROM performance_records WHERE id = test_record.id AND review_status = '대기')
        THEN '✅ updated_at unchanged'
        ELSE '❌ updated_at changed'
    END as updated_at_check
FROM test_record;

-- 5. 실제 데이터 변경 시 updated_at, updated_by가 갱신되는지 확인
-- 테스트 전 상태 저장
WITH test_record AS (
    SELECT id, prescription_qty, updated_at, updated_by
    FROM performance_records 
    WHERE review_status = '검수중'
    LIMIT 1
)
SELECT 
    'Before Data Update' as status,
    id,
    prescription_qty,
    updated_at,
    updated_by
FROM test_record;

-- 6. 실제 데이터 변경 실행 (실제로는 주석 처리하고 수동으로 실행)
/*
UPDATE performance_records 
SET prescription_qty = prescription_qty + 1,
    updated_at = NOW(),
    updated_by = '00000000-0000-0000-0000-000000000000'
WHERE id = (SELECT id FROM performance_records WHERE review_status = '검수중' LIMIT 1);
*/

-- 7. 변경 후 상태 확인
WITH test_record AS (
    SELECT id, prescription_qty, updated_at, updated_by
    FROM performance_records 
    WHERE review_status = '검수중'
    ORDER BY updated_at DESC
    LIMIT 1
)
SELECT 
    'After Data Update' as status,
    id,
    prescription_qty,
    updated_at,
    updated_by,
    CASE 
        WHEN updated_at > (SELECT updated_at FROM performance_records WHERE id = test_record.id AND prescription_qty = test_record.prescription_qty - 1)
        THEN '✅ updated_at changed correctly'
        ELSE '❌ updated_at not changed'
    END as updated_at_check
FROM test_record;

-- 8. 트리거 상태 확인
SELECT 
    'Trigger Status' as info,
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'prevent_updated_fields_on_review_status_change'; 