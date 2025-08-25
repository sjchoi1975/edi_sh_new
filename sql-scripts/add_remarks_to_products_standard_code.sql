-- products_standard_code 테이블에 remarks 컬럼 추가
-- 2025-01-07

-- 1. remarks 컬럼 추가
ALTER TABLE products_standard_code 
ADD COLUMN remarks text DEFAULT '';

-- 2. 기존 데이터의 remarks를 빈 문자열로 초기화
UPDATE products_standard_code 
SET remarks = '' 
WHERE remarks IS NULL; 