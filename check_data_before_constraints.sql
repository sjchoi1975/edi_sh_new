-- 제약조건 적용 전 기존 데이터 상태 확인
-- 운영서버: vaeolqywqckiwwtspxfp

-- =====================================================
-- 1. performance_records_absorption 테이블 데이터 검증
-- =====================================================

-- 1-1. commission_rate 범위 검증
SELECT 
    'Commission Rate Validation' as info,
    COUNT(*) as total_records,
    COUNT(CASE WHEN commission_rate < 0 OR commission_rate > 100 THEN 1 END) as invalid_records,
    MIN(commission_rate) as min_rate,
    MAX(commission_rate) as max_rate
FROM performance_records_absorption;

-- 1-2. prescription_qty 범위 검증
SELECT 
    'Prescription Qty Validation' as info,
    COUNT(*) as total_records,
    COUNT(CASE WHEN prescription_qty < 0 THEN 1 END) as invalid_records,
    MIN(prescription_qty) as min_qty,
    MAX(prescription_qty) as max_qty
FROM performance_records_absorption;

-- 1-3. absorption_rate 범위 검증
SELECT 
    'Absorption Rate Validation' as info,
    COUNT(*) as total_records,
    COUNT(CASE WHEN absorption_rate < 0 OR absorption_rate > 100 THEN 1 END) as invalid_records,
    MIN(absorption_rate) as min_rate,
    MAX(absorption_rate) as max_rate
FROM performance_records_absorption;

-- 1-4. analysis_amount 범위 검증
SELECT 
    'Analysis Amount Validation' as info,
    COUNT(*) as total_records,
    COUNT(CASE WHEN analysis_amount < 0 THEN 1 END) as invalid_records,
    MIN(analysis_amount) as min_amount,
    MAX(analysis_amount) as max_amount
FROM performance_records_absorption;

-- 1-5. analysis_commission_amount 범위 검증
SELECT 
    'Analysis Commission Amount Validation' as info,
    COUNT(*) as total_records,
    COUNT(CASE WHEN analysis_commission_amount < 0 THEN 1 END) as invalid_records,
    MIN(analysis_commission_amount) as min_amount,
    MAX(analysis_commission_amount) as max_amount
FROM performance_records_absorption;

-- 1-6. analysis_absorption_amount 범위 검증
SELECT 
    'Analysis Absorption Amount Validation' as info,
    COUNT(*) as total_records,
    COUNT(CASE WHEN analysis_absorption_amount < 0 THEN 1 END) as invalid_records,
    MIN(analysis_absorption_amount) as min_amount,
    MAX(analysis_absorption_amount) as max_amount
FROM performance_records_absorption;

-- 1-7. analysis_absorption_commission_amount 범위 검증
SELECT 
    'Analysis Absorption Commission Amount Validation' as info,
    COUNT(*) as total_records,
    COUNT(CASE WHEN analysis_absorption_commission_amount < 0 THEN 1 END) as invalid_records,
    MIN(analysis_absorption_commission_amount) as min_amount,
    MAX(analysis_absorption_commission_amount) as max_amount
FROM performance_records_absorption;

-- 1-8. review_status 값 검증
SELECT 
    'Review Status Validation' as info,
    review_status,
    COUNT(*) as record_count
FROM performance_records_absorption
GROUP BY review_status
ORDER BY review_status;

-- 1-9. review_action 값 검증
SELECT 
    'Review Action Validation' as info,
    review_action,
    COUNT(*) as record_count
FROM performance_records_absorption
GROUP BY review_action
ORDER BY review_action;

-- =====================================================
-- 2. 문제가 있는 데이터 샘플 확인
-- =====================================================

-- 2-1. absorption_rate가 범위를 벗어난 데이터
SELECT 
    'Invalid Absorption Rate Data' as info,
    id,
    absorption_rate,
    settlement_month
FROM performance_records_absorption
WHERE absorption_rate < 0 OR absorption_rate > 100
LIMIT 10;

-- 2-2. commission_rate가 범위를 벗어난 데이터
SELECT 
    'Invalid Commission Rate Data' as info,
    id,
    commission_rate,
    settlement_month
FROM performance_records_absorption
WHERE commission_rate < 0 OR commission_rate > 100
LIMIT 10;

-- 2-3. prescription_qty가 음수인 데이터
SELECT 
    'Invalid Prescription Qty Data' as info,
    id,
    prescription_qty,
    settlement_month
FROM performance_records_absorption
WHERE prescription_qty < 0
LIMIT 10;
