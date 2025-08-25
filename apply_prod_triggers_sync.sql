-- 운영서버 트리거 동기화 스크립트
-- 운영서버: vaeolqywqckiwwtspxfp
-- 목적: 개발서버와 동일한 트리거 상태로 동기화

-- =====================================================
-- 1. performance_records 테이블 트리거
-- =====================================================

-- 1-1. 트리거 함수 생성
CREATE OR REPLACE FUNCTION prevent_updated_fields_on_review_status_change()
RETURNS TRIGGER AS $$
DECLARE
    changed_fields_count INTEGER := 0;
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

-- 1-2. 트리거 생성
DROP TRIGGER IF EXISTS prevent_updated_fields_on_review_status_change ON performance_records;
CREATE TRIGGER prevent_updated_fields_on_review_status_change
    BEFORE UPDATE ON performance_records
    FOR EACH ROW
    EXECUTE FUNCTION prevent_updated_fields_on_review_status_change();

-- =====================================================
-- 2. products_standard_code 테이블 트리거
-- =====================================================

-- 2-1. 트리거 함수 생성
CREATE OR REPLACE FUNCTION update_products_standard_code_updated_fields()
RETURNS TRIGGER AS $$
BEGIN
    -- UPDATE 시에만 updated_at을 현재 시간으로 설정
    IF TG_OP = 'UPDATE' THEN
        NEW.updated_at = NOW();
        -- updated_by는 클라이언트에서 설정하도록 함 (auth.uid() 사용)
        IF NEW.updated_by IS NULL THEN
            NEW.updated_by = auth.uid();
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2-2. 트리거 생성
DROP TRIGGER IF EXISTS trigger_update_products_standard_code_updated_fields ON products_standard_code;
CREATE TRIGGER trigger_update_products_standard_code_updated_fields
    BEFORE UPDATE ON products_standard_code
    FOR EACH ROW
    EXECUTE FUNCTION update_products_standard_code_updated_fields();

-- =====================================================
-- 3. product_company_not_assignments 테이블 트리거
-- =====================================================

-- 3-1. 트리거 함수 생성
CREATE OR REPLACE FUNCTION update_product_company_not_assignments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3-2. 트리거 생성
DROP TRIGGER IF EXISTS trigger_update_product_company_not_assignments_updated_at ON product_company_not_assignments;
CREATE TRIGGER trigger_update_product_company_not_assignments_updated_at
    BEFORE UPDATE ON product_company_not_assignments
    FOR EACH ROW
    EXECUTE FUNCTION update_product_company_not_assignments_updated_at();

-- =====================================================
-- 4. 트리거 적용 확인
-- =====================================================

-- 4-1. performance_records 트리거 확인
SELECT 
    'Performance Records Trigger Applied' as info,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'performance_records'
AND trigger_name = 'prevent_updated_fields_on_review_status_change';

-- 4-2. products_standard_code 트리거 확인
SELECT 
    'Products Standard Code Trigger Applied' as info,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'products_standard_code'
AND trigger_name = 'trigger_update_products_standard_code_updated_fields';

-- 4-3. product_company_not_assignments 트리거 확인
SELECT 
    'Product Company Not Assignments Trigger Applied' as info,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'product_company_not_assignments'
AND trigger_name = 'trigger_update_product_company_not_assignments_updated_at';

-- 4-4. 전체 트리거 목록 확인
SELECT 
    'All Triggers Status' as info,
    n.nspname as schema_name,
    c.relname as table_name,
    t.tgname as trigger_name,
    p.proname as function_name
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE n.nspname NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
  AND NOT t.tgisinternal
ORDER BY n.nspname, c.relname, t.tgname;
