-- review_status 변경 시 updated_at, updated_by 갱신 방지 트리거
-- 목적: review_status만 변경될 때는 updated_at, updated_by를 갱신하지 않음

-- 1. 기존 트리거가 있다면 삭제
DROP TRIGGER IF EXISTS prevent_updated_fields_on_review_status_change ON performance_records;

-- 2. 트리거 함수 생성
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
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'prevent_updated_fields_on_review_status_change';

-- 5. 테스트 쿼리 (실제 적용 전 확인용)
-- review_status만 변경하는 경우 updated_at, updated_by가 변경되지 않는지 확인
SELECT 
    'Test Query' as info,
    'This trigger prevents updated_at/updated_by from changing when only review_status changes' as description; 