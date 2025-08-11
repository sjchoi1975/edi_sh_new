-- performance_records_absorption 테이블 데이터 반올림 처리
-- wholesale_revenue, direct_revenue, total_revenue: 정수로 반올림 (마이너스 허용)
-- absorption_rate: 소수점 3자리로 반올림

-- 1. 현재 데이터 확인
SELECT 
    id,
    wholesale_revenue,
    direct_revenue,
    total_revenue,
    absorption_rate
FROM performance_records_absorption 
WHERE wholesale_revenue != 0 OR direct_revenue != 0 OR total_revenue != 0 OR absorption_rate != 0
ORDER BY id
LIMIT 10;

-- 2. 데이터 반올림 업데이트
UPDATE performance_records_absorption 
SET 
    wholesale_revenue = ROUND(COALESCE(wholesale_revenue, 0)),
    direct_revenue = ROUND(COALESCE(direct_revenue, 0)),
    total_revenue = ROUND(COALESCE(total_revenue, 0)),
    absorption_rate = ROUND(COALESCE(absorption_rate, 0), 3)
WHERE wholesale_revenue IS NOT NULL 
   OR direct_revenue IS NOT NULL 
   OR total_revenue IS NOT NULL 
   OR absorption_rate IS NOT NULL;

-- 3. 업데이트 후 데이터 확인
SELECT 
    id,
    wholesale_revenue,
    direct_revenue,
    total_revenue,
    absorption_rate
FROM performance_records_absorption 
WHERE wholesale_revenue != 0 OR direct_revenue != 0 OR total_revenue != 0 OR absorption_rate != 0
ORDER BY id
LIMIT 10;

-- 4. 반올림 결과 통계 확인
SELECT 
    COUNT(*) as total_records,
    COUNT(CASE WHEN wholesale_revenue != 0 THEN 1 END) as records_with_wholesale,
    COUNT(CASE WHEN direct_revenue != 0 THEN 1 END) as records_with_direct,
    COUNT(CASE WHEN total_revenue != 0 THEN 1 END) as records_with_total,
    COUNT(CASE WHEN absorption_rate != 0 THEN 1 END) as records_with_absorption
FROM performance_records_absorption;
