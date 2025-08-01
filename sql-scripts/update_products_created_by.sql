-- products 테이블의 모든 created_by 컬럼에 사용자 ID 설정

-- 1. 모든 레코드의 created_by를 지정된 사용자 ID로 설정
UPDATE products 
SET created_by = '0e085a22-2267-4e7a-9c1e-5c7bf4f3034a';

-- 2. 결과 확인
SELECT 
    id,
    product_name,
    created_at,
    updated_at,
    created_by,
    updated_by
FROM products 
ORDER BY created_at DESC; 