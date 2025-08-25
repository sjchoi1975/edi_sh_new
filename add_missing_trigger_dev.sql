-- 개발서버 누락 트리거 함수 추가
-- 개발서버: selklngerzfmuvagcvvf
-- 목적: product_company_not_assignments 테이블의 누락된 트리거 함수 추가

-- =====================================================
-- 1. 누락된 트리거 함수 생성
-- =====================================================

CREATE OR REPLACE FUNCTION update_product_company_not_assignments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 2. 트리거 생성
-- =====================================================

DROP TRIGGER IF EXISTS trigger_update_product_company_not_assignments_updated_at ON product_company_not_assignments;
CREATE TRIGGER trigger_update_product_company_not_assignments_updated_at
    BEFORE UPDATE ON product_company_not_assignments
    FOR EACH ROW
    EXECUTE FUNCTION update_product_company_not_assignments_updated_at();

-- =====================================================
-- 3. 적용 확인
-- =====================================================

-- 3-1. 트리거 함수 존재 확인
SELECT 
    'Missing Trigger Function Added' as info,
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'update_product_company_not_assignments_updated_at';

-- 3-2. 트리거 적용 확인
SELECT 
    'Trigger Applied Successfully' as info,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'product_company_not_assignments'
AND trigger_name = 'trigger_update_product_company_not_assignments_updated_at';

-- 3-3. 전체 트리거 함수 상태 재확인
SELECT 
    'All Trigger Functions Status' as info,
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
