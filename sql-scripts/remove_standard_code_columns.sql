-- products 테이블에서 표준코드 관련 컬럼 제거
-- 2025-01-07

-- 주의: 이 작업은 되돌릴 수 없으므로 신중하게 실행하세요!

-- 1. 컬럼 제거 전 백업 (선택사항)
CREATE TABLE IF NOT EXISTS products_backup_standard_code AS
SELECT * FROM products;

-- 2. 컬럼 제거
ALTER TABLE products DROP COLUMN IF EXISTS standard_code;
ALTER TABLE products DROP COLUMN IF EXISTS unit_packaging_desc;
ALTER TABLE products DROP COLUMN IF EXISTS unit_quantity;

-- 3. 컬럼 제거 확인
SELECT '컬럼 제거 완료' as status;
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'products' 
ORDER BY ordinal_position; 