-- products_standard_code 테이블의 중복 데이터 확인 및 정리
-- 2025-01-07

-- 1. 중복 데이터 확인
SELECT 
  insurance_code,
  standard_code,
  COUNT(*) as duplicate_count
FROM products_standard_code 
GROUP BY insurance_code, standard_code
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 2. 중복 데이터 중 가장 최근 것만 남기고 나머지 삭제
DELETE FROM products_standard_code 
WHERE id NOT IN (
  SELECT MAX(id)
  FROM products_standard_code
  GROUP BY insurance_code, standard_code
);

-- 3. 중복 제거 후 결과 확인
SELECT 
  insurance_code,
  standard_code,
  COUNT(*) as count
FROM products_standard_code 
GROUP BY insurance_code, standard_code
HAVING COUNT(*) > 1; 