-- products_standard_code 테이블에 status 컬럼 추가
-- 2025-01-07

-- 1. status 컬럼 추가
ALTER TABLE products_standard_code 
ADD COLUMN status text DEFAULT 'active';

-- 2. 기존 데이터의 status를 'active'로 초기화
UPDATE products_standard_code 
SET status = 'active' 
WHERE status IS NULL;

-- 3. NOT NULL 제약조건 추가
ALTER TABLE products_standard_code 
ALTER COLUMN status SET NOT NULL; 