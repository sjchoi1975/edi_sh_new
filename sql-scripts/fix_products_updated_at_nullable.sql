-- products 테이블 updated_at 컬럼을 NULL 허용으로 변경
-- INSERT 시 NULL 값을 허용하도록 수정

-- 1. updated_at 컬럼을 NULL 허용으로 변경
ALTER TABLE products ALTER COLUMN updated_at DROP NOT NULL;

-- 2. updated_by 컬럼도 NULL 허용으로 변경 (일관성을 위해)
ALTER TABLE products ALTER COLUMN updated_by DROP NOT NULL;

-- 3. 모든 레코드의 updated_at을 NULL로 설정
UPDATE products 
SET updated_at = NULL,
    updated_by = NULL;

-- 4. 결과 확인
SELECT 
    id,
    product_name,
    created_at,
    updated_at,
    created_by,
    updated_by
FROM products 
ORDER BY created_at DESC; 