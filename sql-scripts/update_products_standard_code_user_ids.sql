-- products_standard_code 테이블의 created_by, updated_by 컬럼에 사용자 ID 설정

-- 1. 현재 상태 확인
SELECT 
    id,
    insurance_code,
    standard_code,
    created_at,
    updated_at,
    created_by,
    updated_by
FROM products_standard_code 
ORDER BY created_at DESC 
LIMIT 10;

-- 2. created_by가 NULL인 레코드들의 created_by 설정 (관리자 ID 사용)
UPDATE products_standard_code 
SET created_by = '5f474ca1-75e5-4382-b6af-2d33abe54d31'
WHERE created_by IS NULL;

-- 3. updated_by가 NULL이면서 updated_at이 NOT NULL인 레코드들의 updated_by 설정
UPDATE products_standard_code 
SET updated_by = '5f474ca1-75e5-4382-b6af-2d33abe54d31'
WHERE updated_by IS NULL 
  AND updated_at IS NOT NULL;

-- 4. 결과 확인
SELECT 
    id,
    insurance_code,
    standard_code,
    created_at,
    updated_at,
    created_by,
    updated_by
FROM products_standard_code 
ORDER BY created_at DESC 
LIMIT 10; 