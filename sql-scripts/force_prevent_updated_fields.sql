-- 강력한 트리거로 updated_at, updated_by 갱신 방지
-- 목적: review_status만 변경될 때는 절대 updated_at, updated_by를 갱신하지 않음

-- 1. 기존 트리거 완전 삭제
DROP TRIGGER IF EXISTS prevent_updated_fields_on_review_status_change ON performance_records;
DROP FUNCTION IF EXISTS prevent_updated_fields_on_review_status_change();

-- 2. 새로운 강력한 트리거 함수 생성
CREATE OR REPLACE FUNCTION prevent_updated_fields_on_review_status_change()
RETURNS TRIGGER AS $$
DECLARE
    changed_fields_count INTEGER := 0;
    total_fields_count INTEGER := 0;
BEGIN
    -- 변경된 필드 수 계산
    IF OLD.settlement_month IS DISTINCT FROM NEW.settlement_month THEN changed_fields_count := changed_fields_count + 1; END IF;
    IF OLD.company_id IS DISTINCT FROM NEW.company_id THEN changed_fields_count := changed_fields_count + 1; END IF;
    IF OLD.client_id IS DISTINCT FROM NEW.client_id THEN changed_fields_count := changed_fields_count + 1; END IF;
    IF OLD.product_id IS DISTINCT FROM NEW.product_id THEN changed_fields_count := changed_fields_count + 1; END IF;
    IF OLD.prescription_month IS DISTINCT FROM NEW.prescription_month THEN changed_fields_count := changed_fields_count + 1; END IF;
    IF OLD.prescription_qty IS DISTINCT FROM NEW.prescription_qty THEN changed_fields_count := changed_fields_count + 1; END IF;
    IF OLD.prescription_type IS DISTINCT FROM NEW.prescription_type THEN changed_fields_count := changed_fields_count + 1; END IF;
    IF OLD.commission_rate IS DISTINCT FROM NEW.commission_rate THEN changed_fields_count := changed_fields_count + 1; END IF;
    IF OLD.remarks IS DISTINCT FROM NEW.remarks THEN changed_fields_count := changed_fields_count + 1; END IF;
    IF OLD.review_action IS DISTINCT FROM NEW.review_action THEN changed_fields_count := changed_fields_count + 1; END IF;
    IF OLD.review_status IS DISTINCT FROM NEW.review_status THEN changed_fields_count := changed_fields_count + 1; END IF;
    
    -- review_status만 변경된 경우 (다른 필드는 모두 동일)
    IF OLD.review_status IS DISTINCT FROM NEW.review_status AND changed_fields_count = 1 THEN
        -- updated_at, updated_by를 강제로 이전 값으로 유지
        NEW.updated_at = OLD.updated_at;
        NEW.updated_by = OLD.updated_by;
        
        -- 디버깅 로그
        RAISE NOTICE 'TRIGGER: Only review_status changed from % to %. Keeping updated_at=% and updated_by=%', 
            OLD.review_status, NEW.review_status, OLD.updated_at, OLD.updated_by;
    ELSE
        -- 다른 필드도 변경된 경우 정상 처리
        RAISE NOTICE 'TRIGGER: Multiple fields changed (count: %). Allowing normal update.', changed_fields_count;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. 트리거 생성
CREATE TRIGGER prevent_updated_fields_on_review_status_change
    BEFORE UPDATE ON performance_records
    FOR EACH ROW
    EXECUTE FUNCTION prevent_updated_fields_on_review_status_change();

-- 4. 트리거 확인
SELECT 
    'Trigger Created' as status,
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'prevent_updated_fields_on_review_status_change';

-- 5. 테스트용 데이터 확인
SELECT 
    'Test Data' as info,
    id,
    review_status,
    updated_at,
    updated_by,
    prescription_qty
FROM performance_records 
WHERE review_status = '대기'
ORDER BY created_at DESC
LIMIT 2; 