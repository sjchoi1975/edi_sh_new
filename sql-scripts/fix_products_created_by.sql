-- products 테이블의 created_by 값을 실제 존재하는 user_id로 업데이트

-- 1. 현재 상태 확인
SELECT 
    id,
    product_name,
    created_by,
    updated_by
FROM products 
WHERE created_by = '0e085a22-2267-4e7a-9c1e-5c7bf4f3034a'
LIMIT 10;

-- 2. created_by를 서울메디의 user_id로 업데이트
UPDATE products 
SET created_by = '5f474ca1-75e5-4382-b6af-2d33abe54d31'
WHERE created_by = '0e085a22-2267-4e7a-9c1e-5c7bf4f3034a';

-- 3. updated_by도 동일하게 업데이트 (null이 아닌 경우)
UPDATE products 
SET updated_by = '5f474ca1-75e5-4382-b6af-2d33abe54d31'
WHERE updated_by = '0e085a22-2267-4e7a-9c1e-5c7bf4f3034a';

-- 4. 결과 확인
SELECT 
    id,
    product_name,
    created_by,
    updated_by
FROM products 
WHERE created_by = '5f474ca1-75e5-4382-b6af-2d33abe54d31'
LIMIT 10; 