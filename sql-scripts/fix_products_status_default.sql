-- products 테이블의 status 컬럼 기본값을 active로 변경
-- 2025-01-07

-- 1. 현재 status 컬럼의 기본값 확인
SELECT column_name, column_default, is_nullable, data_type 
FROM information_schema.columns 
WHERE table_name = 'products' AND column_name = 'status';

-- 2. status 컬럼의 기본값을 'active'로 변경
ALTER TABLE products 
ALTER COLUMN status SET DEFAULT 'active';

-- 3. 기존에 NULL이거나 잘못된 값인 레코드들을 'active'로 업데이트
UPDATE products 
SET status = 'active' 
WHERE status IS NULL OR status NOT IN ('active', 'inactive');

-- 4. 변경사항 확인
SELECT column_name, column_default, is_nullable, data_type 
FROM information_schema.columns 
WHERE table_name = 'products' AND column_name = 'status'; 