-- 트리거 상태 확인 및 재적용 스크립트

-- 1. 현재 트리거 상태 확인
SELECT 
    'Current Triggers on performance_records' as info,
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'performance_records';

-- 2. 기존 트리거 삭제 (안전하게)
DROP TRIGGER IF EXISTS prevent_updated_fields_on_review_status_change ON performance_records;
DROP FUNCTION IF EXISTS prevent_updated_fields_on_review_status_change();

-- 3. 트리거 함수 재생성
CREATE OR REPLACE FUNCTION prevent_updated_fields_on_review_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- review_status만 변경되고 다른 필드는 변경되지 않은 경우
    IF OLD.review_status IS DISTINCT FROM NEW.review_status 
       AND OLD.settlement_month = NEW.settlement_month
       AND OLD.company_id = NEW.company_id
       AND OLD.client_id = NEW.client_id
       AND OLD.product_id = NEW.product_id
       AND OLD.prescription_month = NEW.prescription_month
       AND OLD.prescription_qty = NEW.prescription_qty
       AND OLD.prescription_type = NEW.prescription_type
       AND OLD.commission_rate = NEW.commission_rate
       AND OLD.remarks = NEW.remarks
       AND OLD.review_action = NEW.review_action THEN
        
        -- updated_at, updated_by를 이전 값으로 유지
        NEW.updated_at = OLD.updated_at;
        NEW.updated_by = OLD.updated_by;
        
        -- 디버깅을 위한 로그 (선택사항)
        RAISE NOTICE 'Trigger: review_status only change detected. Keeping updated_at=% and updated_by=%', OLD.updated_at, OLD.updated_by;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. 트리거 재생성
CREATE TRIGGER prevent_updated_fields_on_review_status_change
    BEFORE UPDATE ON performance_records
    FOR EACH ROW
    EXECUTE FUNCTION prevent_updated_fields_on_review_status_change();

-- 5. 트리거 생성 확인
SELECT 
    'Trigger Applied Successfully' as info,
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'prevent_updated_fields_on_review_status_change';

-- 6. 테스트용 샘플 데이터 확인
SELECT 
    'Sample Data for Testing' as info,
    id,
    review_status,
    updated_at,
    updated_by,
    prescription_qty
FROM performance_records 
WHERE review_status = '대기'
ORDER BY created_at DESC
LIMIT 3;

-- 7. 실제 테스트 (주석 해제하여 실행)
/*
-- 테스트 1: review_status만 변경
UPDATE performance_records 
SET review_status = '검수중'
WHERE id = (SELECT id FROM performance_records WHERE review_status = '대기' LIMIT 1);

-- 테스트 결과 확인
SELECT 
    'Test Result' as info,
    id,
    review_status,
    updated_at,
    updated_by
FROM performance_records 
WHERE review_status = '검수중'
ORDER BY updated_at DESC
LIMIT 1;
*/ 